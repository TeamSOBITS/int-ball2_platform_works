#!/bin/bash
set -e

export ROS_IP=$(hostname -I | cut -d ' ' -f1)

# ros1_bridge needs the full ROS1+ROS2 mixed env (custom msg bridging).
# Run in a subshell so its PYTHONPATH does not affect action_bridge_node.py.
(
  source /root/bridge_env.sh
  sleep 4
  exec ros2 run ros1_bridge dynamic_bridge --bridge-all-topics
) &

# action_bridge_node.py is pure ROS2.
source /root/ros2_env.sh

exec python3 /root/bridge/action_bridge_node.py
