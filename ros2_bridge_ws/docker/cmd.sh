#!/bin/bash
set -e

export ROS_IP=$(hostname -I | cut -d ' ' -f1)

# ros1_bridge requires full ROS 1+2 mixed env (for custom msg bridging)
# Run in a subshell so its PYTHONPATH changes don't affect action_bridge_node.py
(
  source /home/sobits/ros_entrypoint.sh
  sleep 4
  exec ros2 run ros1_bridge dynamic_bridge --bridge-all-topics
) &

# action_bridge_node.py is pure ROS 2 — source only ROS 2 paths to avoid
# ROS 1 catkin ib2_msgs shadowing ib2_msgs.action
source /opt/ros/humble/setup.bash
source /home/sobits/colcon_msgs_ws/install/setup.bash
[ -f /home/sobits/colcon_ws/install/setup.bash ] && source /home/sobits/colcon_ws/install/setup.bash

exec python3 /home/sobits/bridge/action_bridge_node.py
