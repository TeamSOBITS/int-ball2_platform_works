#!/bin/bash
set -e

export ROS_IP=$(hostname -I | cut -d ' ' -f1)

# Kill any previous bridge instances to prevent duplicate action servers.
pkill -f "action_bridge_node.py" 2>/dev/null || true
pkill -f "parameter_bridge"      2>/dev/null || true
pkill -f "dynamic_bridge"        2>/dev/null || true
sleep 1

# Load bridge topic/service list into ROS1 param server before starting parameter_bridge.
# bridge_topics.yaml defines the explicit set of topics/services to bridge (avoids --bridge-all-topics
# which degrades high-bandwidth topics like camera images from 30Hz to <1Hz).
(source /opt/ros/noetic/setup.bash && rosparam delete /services_1_to_2 2>/dev/null || true; rosparam load /root/bridge/bridge_topics.yaml /)

# ros1_bridge needs the full ROS1+ROS2 mixed env (custom msg bridging).
# Run in a subshell so its PYTHONPATH does not affect action_bridge_node.py.
(
  source /root/bridge_env.sh
  sleep 4
  exec ros2 run ros1_bridge parameter_bridge
) &

# action_bridge_node.py is pure ROS2.
source /root/ros2_env.sh

exec python3 /root/bridge/action_bridge_node.py
