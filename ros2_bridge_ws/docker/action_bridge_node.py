#!/usr/bin/env python3
"""ROS 2 side of the ROS 1-2 Action Bridge.
Spawns bridge_ros1_helper.py as a subprocess in a pure ROS 1 environment
and communicates via stdin/stdout JSON to avoid Python module cache conflicts
between ROS 1 and ROS 2 geometry_msgs/ib2_msgs types.
"""
import os
import sys
import json
import queue
import signal
import subprocess
import threading
import uuid
from pathlib import Path

import rclpy
from rclpy.node import Node
from rclpy.action import ActionServer, CancelResponse, GoalResponse
from rclpy.callback_groups import ReentrantCallbackGroup
from rclpy.executors import MultiThreadedExecutor

from ib2_msgs.action import CtlCommand

HELPER_SCRIPT = str(Path(__file__).parent / "bridge_ros1_helper.py")

# Configurable via environment variables; defaults suit a standard Noetic + catkin_ws setup.
_ROS1_DISTRO = os.environ.get("ROS1_DISTRO", "noetic")
_CATKIN_WS   = os.path.expanduser(os.environ.get("ROS1_CATKIN_WS", "~/catkin_ws"))

_ROS1_BASE   = f"/opt/ros/{_ROS1_DISTRO}"
_CATKIN_DEV  = f"{_CATKIN_WS}/devel"

# Minimal environment for the ROS 1 subprocess (no ROS 2 paths).
# Override ROS1_DISTRO or ROS1_CATKIN_WS before launching to adapt to other machines.
_ROS1_ENV = {
    **{k: os.environ[k] for k in ("PATH", "HOME", "USER", "LOGNAME") if k in os.environ},
    "PYTHONPATH": (
        f"{_ROS1_BASE}/lib/python3/dist-packages:"
        f"{_CATKIN_DEV}/lib/python3/dist-packages"
    ),
    "LD_LIBRARY_PATH": (
        f"{_ROS1_BASE}/lib:"
        f"{_CATKIN_DEV}/lib"
    ),
    "CMAKE_PREFIX_PATH": f"{_CATKIN_DEV}:{_ROS1_BASE}",
    "ROS_PACKAGE_PATH":  f"{_CATKIN_WS}/src:{_ROS1_BASE}/share",
    "ROS_ROOT":          f"{_ROS1_BASE}/share/ros",
    "ROS_DISTRO":        _ROS1_DISTRO,
    "ROS_VERSION":       "1",
    "ROS_ETC_DIR":       f"{_ROS1_BASE}/etc/ros",
    "ROS_MASTER_URI":    os.environ.get("ROS_MASTER_URI", "http://localhost:11311"),
}


class CtlCommandActionBridge(Node):
    def __init__(self) -> None:
        super().__init__("ctl_command_action_bridge")

        self._proc: subprocess.Popen | None = None
        self._goal_queues: dict[str, queue.Queue] = {}
        self._goal_lock = threading.Lock()  # one goal at a time through the bridge

        self._start_ros1_helper()

        self._action_server = ActionServer(
            self,
            CtlCommand,
            "/ctl/command_ros2",
            execute_callback=self.execute_callback,
            goal_callback=self.goal_callback,
            cancel_callback=self.cancel_callback,
            callback_group=ReentrantCallbackGroup(),
        )
        self.get_logger().info("ROS 2 Action Server ready: /ctl/command_ros2")

    # ------------------------------------------------------------------
    # Subprocess management
    # ------------------------------------------------------------------

    def _start_ros1_helper(self) -> None:
        self.get_logger().info(f"Starting ROS 1 helper: {HELPER_SCRIPT}")
        self._proc = subprocess.Popen(
            [sys.executable, HELPER_SCRIPT],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=_ROS1_ENV,
            bufsize=1,          # line-buffered
            text=True,
        )

        # Thread to forward stderr from helper for debugging
        threading.Thread(target=self._stderr_reader, daemon=True).start()

        # Wait for the "ready" signal before allowing goals
        self.get_logger().info("Waiting for ROS 1 helper to connect to /ctl/command ...")
        for raw in self._proc.stdout:
            try:
                msg = json.loads(raw.strip())
            except json.JSONDecodeError:
                continue
            if msg.get("type") == "ready":
                self.get_logger().info("ROS 1 helper is ready.")
                break

        # Background thread that routes all subsequent subprocess output
        threading.Thread(target=self._stdout_reader, daemon=True).start()

    def _stdout_reader(self) -> None:
        for raw in self._proc.stdout:
            raw = raw.strip()
            if not raw:
                continue
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                self.get_logger().warn(f"[helper stdout] bad JSON: {raw!r}")
                continue
            goal_id = msg.get("id")
            if goal_id and goal_id in self._goal_queues:
                self._goal_queues[goal_id].put(msg)
            else:
                self.get_logger().debug(f"[helper] unrouted msg: {msg}")

    def _stderr_reader(self) -> None:
        for line in self._proc.stderr:
            self.get_logger().info(f"[ros1_helper] {line.rstrip()}")

    def _send_to_helper(self, msg: dict) -> None:
        if self._proc and self._proc.stdin:
            self._proc.stdin.write(json.dumps(msg) + "\n")
            self._proc.stdin.flush()

    # ------------------------------------------------------------------
    # Action Server callbacks
    # ------------------------------------------------------------------

    def goal_callback(self, goal_request):
        return GoalResponse.ACCEPT

    def cancel_callback(self, goal_handle):
        goal_id = str(goal_handle.goal_id.uuid.tobytes().hex())
        self._send_to_helper({"type": "cancel", "id": goal_id})
        return CancelResponse.ACCEPT

    def execute_callback(self, goal_handle):
        goal_id = str(goal_handle.goal_id.uuid.tobytes().hex())
        req = goal_handle.request

        q: queue.Queue = queue.Queue()
        self._goal_queues[goal_id] = q

        goal_msg = {
            "type": "goal",
            "id": goal_id,
            "frame_id": req.target.header.frame_id,
            "target_x": req.target.pose.position.x,
            "target_y": req.target.pose.position.y,
            "target_z": req.target.pose.position.z,
            "qx": req.target.pose.orientation.x,
            "qy": req.target.pose.orientation.y,
            "qz": req.target.pose.orientation.z,
            "qw": req.target.pose.orientation.w,
            "cmd_type": int(req.type.type),  # CtlStatusType.type is int32
        }

        with self._goal_lock:
            self.get_logger().info(f"Forwarding goal {goal_id[:8]}... to ROS 1")
            self._send_to_helper(goal_msg)

            result_data = None
            while rclpy.ok():
                try:
                    msg = q.get(timeout=1.0)
                except queue.Empty:
                    if goal_handle.is_cancel_requested:
                        self._send_to_helper({"type": "cancel", "id": goal_id})
                    continue

                if msg["type"] == "feedback":
                    fb = CtlCommand.Feedback()
                    fb.time_to_go.sec = msg["time_to_go_sec"]
                    fb.time_to_go.nanosec = msg["time_to_go_nsec"]
                    fb.pose_to_go.position.x = msg["pose_x"]
                    fb.pose_to_go.position.y = msg["pose_y"]
                    fb.pose_to_go.position.z = msg["pose_z"]
                    fb.pose_to_go.orientation.x = msg["pose_qx"]
                    fb.pose_to_go.orientation.y = msg["pose_qy"]
                    fb.pose_to_go.orientation.z = msg["pose_qz"]
                    fb.pose_to_go.orientation.w = msg["pose_qw"]
                    goal_handle.publish_feedback(fb)

                elif msg["type"] == "result":
                    result_data = msg
                    break

                elif msg["type"] == "error":
                    self.get_logger().error(f"ROS 1 error: {msg.get('msg')}")
                    goal_handle.abort()
                    self._goal_queues.pop(goal_id, None)
                    return CtlCommand.Result()

        self._goal_queues.pop(goal_id, None)

        if result_data is None:
            goal_handle.abort()
            return CtlCommand.Result()

        goal_handle.succeed()
        result = CtlCommand.Result()
        result.stamp.sec = result_data["stamp_sec"]
        result.stamp.nanosec = result_data["stamp_nsec"]
        result.type = result_data["result_type"]
        self.get_logger().info(f"Goal {goal_id[:8]}... succeeded.")
        return result

    def destroy_node(self) -> None:
        if self._proc:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=3.0)
            except subprocess.TimeoutExpired:
                self._proc.kill()
        super().destroy_node()


def main(args=None) -> None:
    rclpy.init(args=args)
    bridge = CtlCommandActionBridge()

    executor = MultiThreadedExecutor()
    try:
        rclpy.spin(bridge, executor=executor)
    except KeyboardInterrupt:
        pass
    finally:
        bridge.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
