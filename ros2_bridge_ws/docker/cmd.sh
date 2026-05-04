#!/bin/bash
set -e

export ROS_IP=$(hostname -I | cut -d ' ' -f1)

# ros1_bridge needs the full ROS1+ROS2 mixed env (custom msg bridging).
# Run in a subshell so its PYTHONPATH does not affect action_bridge_node.py.
(
  source /home/sobits/bridge_env.sh
  sleep 4
  exec ros2 run ros1_bridge dynamic_bridge --bridge-all-topics
) &

# action_bridge_node.py is pure ROS2.
source /home/sobits/ros2_env.sh

exec python3 /home/sobits/bridge/action_bridge_node.py
