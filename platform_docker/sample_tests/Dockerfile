FROM ros:noetic

# 1. 基本設定（キャッシュ維持）
RUN apt update 
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt install -y curl
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt-get install python3-pip -y 

# 2. 既存パッケージ（キャッシュ維持）
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsb-release \
    zenity \
    tree \
    gedit \
    bash-completion \
    liboctomap-dev \
    libdynamicedt3d-dev \
    ros-noetic-stereo-image-proc \
    ros-noetic-octomap-server \
    ros-noetic-vision-msgs \
    ros-noetic-pcl-ros \
    ros-noetic-nodelet \
    ros-noetic-gazebo-msgs \
    ros-noetic-smach \
    ros-noetic-smach-ros \
    && rm -rf /var/lib/apt/lists/*

# 3. 既存Pythonライブラリ（キャッシュ維持）
RUN pip3 install rospkg numpy octomap-python

# 🚀 【ここから追加：キャッシュを活かしつつ問題を解決】
# 1. octomap-pythonのインポートエラー解消
RUN ln -s /usr/lib/x86_64-linux-gnu/libdynamicedt3d.so.1.9 /usr/lib/x86_64-linux-gnu/libdynamicedt3d.so.1.8 || true && \
    ln -s /usr/lib/x86_64-linux-gnu/liboctomap.so.1.9 /usr/lib/x86_64-linux-gnu/liboctomap.so.1.8 || true && \
    ldconfig

# 2. YOLO ROS用のライブラリ追加
RUN pip3 install ultralytics

# 3. Depth-Anything-V2 / Gradio 関連のライブラリ追加
RUN pip3 install \
    torch \
    torchvision \
    opencv-python \
    matplotlib \
    gradio \
    gradio_imageslider

# 4. 環境変数の設定
ENV LD_LIBRARY_PATH=/opt/ros/noetic/lib:/root/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
############################# User packages build ##############################
RUN mkdir -p /root/catkin_ws/src
COPY user_programs /root/catkin_ws/src/user_programs
RUN cd /root/catkin_ws/ && \
    /bin/bash -c "source /opt/ros/noetic/setup.bash; catkin_make"

############################# Import shell scripts ##############################
COPY scripts /root/scripts
RUN chmod -R 744 /root/scripts
CMD ["/root/scripts/cmd.sh"]