#!/usr/bin/env python3
"""ROS 1 ActionClient helper - subprocess side of the action bridge.
Communicates with the ROS 2 side via stdin (goal/cancel JSON) and stdout (feedback/result JSON).
Run only in a pure ROS 1 environment (no ROS 2 paths in PYTHONPATH).
"""
import sys
import json
import threading

import rospy
import actionlib
from ib2_msgs.msg import CtlCommandAction, CtlCommandGoal


_stdout_lock = threading.Lock()


def send(msg: dict) -> None:
    line = json.dumps(msg) + '\n'
    with _stdout_lock:
        sys.stdout.write(line)
        sys.stdout.flush()


def main() -> None:
    rospy.init_node('ctl_command_bridge_ros1', anonymous=True, disable_signals=True)

    client = actionlib.SimpleActionClient('/ctl/command', CtlCommandAction)
    rospy.loginfo("[ros1_helper] Waiting for ROS 1 Action Server /ctl/command ...")
    client.wait_for_server()
    rospy.loginfo("[ros1_helper] Connected.")
    send({"type": "ready"})

    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError as e:
            rospy.logwarn(f"[ros1_helper] JSON parse error: {e}")
            continue

        goal_id = msg.get("id", "unknown")
        msg_type = msg.get("type")

        if msg_type == "cancel":
            client.cancel_goal()
            continue

        if msg_type != "goal":
            continue

        # Build ROS 1 goal
        goal = CtlCommandGoal()
        goal.target.header.stamp = rospy.Time.now()
        goal.target.header.frame_id = msg.get("frame_id", "")
        goal.target.pose.position.x = msg["target_x"]
        goal.target.pose.position.y = msg["target_y"]
        goal.target.pose.position.z = msg["target_z"]
        goal.target.pose.orientation.x = msg["qx"]
        goal.target.pose.orientation.y = msg["qy"]
        goal.target.pose.orientation.z = msg["qz"]
        goal.target.pose.orientation.w = msg["qw"]
        goal.type.type = msg["cmd_type"]  # CtlStatusType.type field

        # Capture goal_id in default arg to avoid closure capture issues
        def _feedback_cb(fb, gid=goal_id):
            send({
                "type": "feedback",
                "id": gid,
                "time_to_go_sec": fb.time_to_go.secs,
                "time_to_go_nsec": fb.time_to_go.nsecs,
                "pose_x": fb.pose_to_go.position.x,
                "pose_y": fb.pose_to_go.position.y,
                "pose_z": fb.pose_to_go.position.z,
                "pose_qx": fb.pose_to_go.orientation.x,
                "pose_qy": fb.pose_to_go.orientation.y,
                "pose_qz": fb.pose_to_go.orientation.z,
                "pose_qw": fb.pose_to_go.orientation.w,
            })

        client.send_goal(goal, feedback_cb=_feedback_cb)
        client.wait_for_result()
        result = client.get_result()

        if result is None:
            send({"type": "error", "id": goal_id, "msg": "ROS 1 action returned None"})
        else:
            send({
                "type": "result",
                "id": goal_id,
                "stamp_sec": result.stamp.secs,
                "stamp_nsec": result.stamp.nsecs,
                "result_type": result.type,
            })


if __name__ == '__main__':
    main()
