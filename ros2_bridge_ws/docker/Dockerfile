# syntax=docker/dockerfile:1
# Multi-stage build for ros1_bridge with layered image strategy:
# - ros1_base: OS + ROS1 Noetic + ROS2 Humble (base foundation, reusable)
# - msg_bridge_base: ros1_base + custom messages + ros1_bridge (heavy build, shared via ghcr.io)
# - final: msg_bridge_base + application scripts (local builds only, fast iteration)

# ============================================================================
# LAYER 1: ros1_base - Base foundation (OS + ROS1 + ROS2)
# ============================================================================
# This layer provides the OS environment and both ROS distributions.
# Built locally with --full, or pulled from ghcr.io in normal --pull mode.
FROM osrf/ros:humble-desktop-full AS ros1_base

ARG USERNAME=ros
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

SHELL ["/bin/bash", "-c"]

# Base system packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -q && apt-get upgrade -yq && apt-get install -yq --no-install-recommends \
        wget \
        curl \
        git \
        gnupg \
        build-essential \
        vim \
        sudo \
        lsb-release \
        locales \
        bash-completion \
        glmark2 \
        tzdata \
        software-properties-common \
        cmake \
        python3-empy \
        python3-defusedxml \
        python3-rosdep \
        python3-rosinstall-generator \
        python3-vcstools \
        python3-vcstool \
        libboost-all-dev && \
    locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# ROS1 package sources
RUN add-apt-repository universe && \
    echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros-latest.list && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# User setup
RUN if ! getent group ${LOCAL_GID} >/dev/null; then groupadd --gid ${LOCAL_GID} ${USERNAME}; fi && \
    if ! id -u ${USERNAME} >/dev/null 2>&1; then useradd --uid ${LOCAL_UID} --gid ${LOCAL_GID} -m -s /bin/bash ${USERNAME}; fi && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ROS1 installation from source
RUN mkdir -p /home/${USERNAME}/Downloads
RUN cd /home/${USERNAME}/Downloads && \
    wget http://archive.ubuntu.com/ubuntu/pool/universe/h/hddtemp/hddtemp_0.3-beta15-53_amd64.deb && \
    sudo apt-get update -q && \
    sudo apt-get install -yq ./hddtemp_0.3-beta15-53_amd64.deb

RUN cd /home/${USERNAME}/Downloads && \
    wget https://raw.githubusercontent.com/ros/rosdistro/master/rosdep/base.yaml && \
    sed -i '/focal: \[hddtemp\]/a \    jammy: \[hddtemp\]' base.yaml && \
    sudo sed -i "s|^yaml .*base.yaml$|yaml file:///home/${USERNAME}/Downloads/base.yaml|" /etc/ros/rosdep/sources.list.d/20-default.list && \
    sudo rosdep update

RUN sudo apt-get update -q && \
    sudo apt-get install -yq --no-install-recommends liburdfdom-headers-dev liburdfdom-dev && \
    sudo rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/${USERNAME}/catkin_ws && \
    cd /home/${USERNAME}/catkin_ws && \
    rosinstall_generator ros_comm rosconsole_bridge actionlib actionlib_msgs geometry_msgs common_msgs tf2_msgs tf2_geometry_msgs visualization_msgs --rosdistro noetic --deps --tar > noetic-ros_comm.rosinstall && \
    mkdir -p src && \
    vcs import --input noetic-ros_comm.rosinstall ./src && \
    sudo apt-get update -q && \
    sudo rosdep install --from-paths ./src --ignore-packages-from-source --rosdistro noetic -y --skip-keys=python3-rospkg

RUN cd /home/${USERNAME}/catkin_ws/src && \
    mkdir -p /home/${USERNAME}/Downloads/backup && \
    if [ -d rosconsole ]; then mv rosconsole /home/${USERNAME}/Downloads/backup/; fi && \
    if [ -d urdf ]; then mv urdf /home/${USERNAME}/Downloads/backup/; fi && \
    git clone https://github.com/dreuter/rosconsole.git && \
    cd rosconsole && \
    git checkout noetic-jammy && \
    cd /home/${USERNAME}/catkin_ws/src && \
    git clone https://github.com/dreuter/urdf.git && \
    cd urdf && \
    git checkout set-cxx-version && \
    cd /home/${USERNAME}/catkin_ws/src

# gazebo_msgs for ROS1
RUN cd /home/${USERNAME}/catkin_ws/src && \
    git clone -b noetic-devel https://github.com/ros-simulation/gazebo_ros_pkgs.git && \
    cd gazebo_ros_pkgs && \
    find . -mindepth 1 -maxdepth 1 -type d ! -name gazebo_msgs -exec rm -rf {} +

RUN cd /home/${USERNAME}/catkin_ws && \
    sudo ./src/catkin/bin/catkin_make_isolated --install --install-space /opt/ros/noetic \
        -DCMAKE_BUILD_TYPE=Release \
        --make-args -j$(nproc)

WORKDIR /home/${USERNAME}

# ============================================================================
# LAYER 2: msg_bridge_base - Custom messages + ros1_bridge (heavy build)
# ============================================================================
# This layer compiles custom ROS1 and ROS2 messages, then builds ros1_bridge.
# It's the most time-consuming layer and is published to ghcr.io for sharing.
FROM ros1_base AS msg_bridge_base

ARG USERNAME=ros
ARG ROS_DOMAIN_ID=0

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

SHELL ["/bin/bash", "-c"]

# ROS2 gazebo_msgs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -q && \
    sudo apt-get install -yq --no-install-recommends \
        ros-humble-gazebo-msgs

# ROS1 custom messages
RUN mkdir -p /home/${USERNAME}/catkin_ws/src
COPY --chown=${USERNAME}:${USERNAME} baked_pkgs/ib2_msgs/ /home/${USERNAME}/catkin_ws/src/ib2_msgs/
COPY --chown=${USERNAME}:${USERNAME} baked_pkgs/platform_msgs/ /home/${USERNAME}/catkin_ws/src/platform_msgs/
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && cd /home/${USERNAME}/catkin_ws && catkin_make -j$(nproc)"

# ROS2 custom messages
RUN mkdir -p /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/msg \
    /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/srv \
    /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/action \
    /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/msg \
    /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/srv
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/ib2_msgs/msg/ /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/msg/
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/ib2_msgs/srv/ /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/srv/
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/ib2_msgs/action/ /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/action/
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/platform_msgs/msg/ /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/msg/
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/platform_msgs/srv/ /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/srv/
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/ib2_msgs/package.xml /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/package.xml
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/ib2_msgs/CMakeLists.txt /home/${USERNAME}/colcon_msgs_ws/src/ib2_msgs/CMakeLists.txt
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/platform_msgs/package.xml /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/package.xml
COPY --chown=${USERNAME}:${USERNAME} msgs_ros2/platform_msgs/CMakeLists.txt /home/${USERNAME}/colcon_msgs_ws/src/platform_msgs/CMakeLists.txt
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && cd /home/${USERNAME}/colcon_msgs_ws && colcon build --parallel-workers $(nproc)"

# ros1_bridge installation
RUN mkdir -p /home/${USERNAME}/ros1_bridge_ws/src
RUN cd /home/${USERNAME}/ros1_bridge_ws/src && \
    git clone https://github.com/ros2/ros1_bridge.git
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && source /home/${USERNAME}/colcon_msgs_ws/install/setup.bash && \
    cd /home/${USERNAME}/ros1_bridge_ws && colcon build --symlink-install --packages-skip ros1_bridge --parallel-workers $(nproc)"
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && source /home/${USERNAME}/catkin_ws/devel/setup.bash && \
    source /opt/ros/humble/setup.bash && source /home/${USERNAME}/colcon_msgs_ws/install/setup.bash && \
    cd /home/${USERNAME}/ros1_bridge_ws && colcon build --symlink-install --packages-select ros1_bridge --cmake-force-configure --parallel-workers $(nproc)"

RUN mkdir -p /home/${USERNAME}/colcon_ws/src

# ============================================================================
# LAYER 3: final - Application layer (scripts, configuration)
# ============================================================================
# This is the final runtime image with cmd.sh and environment setup.
# Built locally from msg_bridge_base, either pulled or locally built.
# Fast to rebuild when application code changes.
FROM msg_bridge_base AS final

ARG USERNAME=ros
ARG ROS_DOMAIN_ID=0

ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

SHELL ["/bin/bash", "-c"]

# Shell environment scripts
RUN cat > /home/${USERNAME}/ros2_env.sh <<'EOF' && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/ros2_env.sh
source /opt/ros/humble/setup.bash
if [ -f ~/colcon_msgs_ws/install/setup.bash ]; then source ~/colcon_msgs_ws/install/setup.bash; fi
if [ -f ~/colcon_ws/install/setup.bash ]; then source ~/colcon_ws/install/setup.bash; fi
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
export ROS_MASTER_URI=${ROS_MASTER_URI:-http://localhost:11311}
alias cb='CURRENT_DIR=`pwd` && cd ~/colcon_ws/ && colcon build --symlink-install && source ~/.bashrc && cd ${CURRENT_DIR}'
alias bridge='bash ~/bridge/cmd.sh'
# To use ros1_bridge or ROS1 msgs interactively, source bridge_env.sh:
#   source ~/bridge_env.sh
:
EOF

# Bridge environment for ros1_bridge process
RUN cat > /home/${USERNAME}/bridge_env.sh <<'EOF' && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/bridge_env.sh
source /opt/ros/noetic/setup.bash
if [ -f ~/catkin_ws/devel/setup.bash ]; then source ~/catkin_ws/devel/setup.bash; fi
source /opt/ros/humble/setup.bash
if [ -f ~/colcon_msgs_ws/install/setup.bash ]; then source ~/colcon_msgs_ws/install/setup.bash; fi
if [ -f ~/ros1_bridge_ws/install/setup.bash ]; then source ~/ros1_bridge_ws/install/setup.bash; fi
if [ -f ~/colcon_ws/install/setup.bash ]; then source ~/colcon_ws/install/setup.bash; fi
:
EOF

# Add to .bashrc
RUN echo "source /home/${USERNAME}/ros2_env.sh" >> /home/${USERNAME}/.bashrc && \
    echo "export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}" >> /home/${USERNAME}/.bashrc

# Bridge scripts (application entry point)
RUN mkdir -p /home/${USERNAME}/bridge
COPY --chown=${USERNAME}:${USERNAME} cmd.sh action_bridge_node.py bridge_ros1_helper.py /home/${USERNAME}/bridge/
RUN chmod +x /home/${USERNAME}/bridge/cmd.sh /home/${USERNAME}/bridge/action_bridge_node.py

WORKDIR /home/${USERNAME}

CMD ["/home/sobits/bridge/cmd.sh"]
