#!/bin/bash

export ROS_IP=`hostname -I | cut -d ' ' -f1`

source /root/catkin_ws/devel/setup.bash

# select the launch file
# /opt/ros/noetic/bin/rosrun intball_programs run_competition.py


echo "Starting run_competition.py..."
/opt/ros/noetic/bin/rosrun intball_programs run_competition.py &

# 4秒待機
sleep 4

# 2. 1つ目のlaunchをバックグラウンドで起動
echo "Starting first launch..."
/opt/ros/noetic/bin/roslaunch intball_programs gnc.launch &

# 10秒待機
sleep 10

# 3. 別のlaunchを起動 (最後なので & はあってもなくてもOK)
echo "Starting second launch..."
/opt/ros/noetic/bin/roslaunch intball_programs yolo.launch