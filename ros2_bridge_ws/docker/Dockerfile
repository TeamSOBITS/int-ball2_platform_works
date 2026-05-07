# syntax=docker/dockerfile:1
# Multi-stage build for ros1_bridge with layered image strategy:
# - ros1_base: OS + ROS1 Noetic + ROS2 Humble (base foundation, reusable)
# - msg_bridge_base: ros1_base + custom messages + ros1_bridge (heavy build, shared via ghcr.io)
# - final: msg_bridge_base + application scripts (local builds only, fast iteration)
#
# Build mode selection:
#   --full:       ROS1_BASE_IMAGE=ros1_base_local  → builds ros1_base from scratch
#   --msg-build:  ROS1_BASE_IMAGE=ghcr.io/.../ros1_base:noetic-humble  → pulls ros1_base
#   --pull:       uses Dockerfile.final directly (this file is not used)

# Global ARG: must be declared before the first FROM to be usable in FROM instructions.
# --full:      leave as default → uses locally built ros1_base_local stage
# --msg-build: override with ghcr.io/teamsobits/ros1_base:noetic-humble
ARG ROS1_BASE_IMAGE=ros1_base_local

# ============================================================================
# LAYER 1a: ros1_base_local - Full local build of base foundation (--full mode)
# ============================================================================
# Only built when ROS1_BASE_IMAGE is not overridden (i.e., --full mode).
FROM osrf/ros:humble-desktop-full AS ros1_base_local

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

WORKDIR /root

# ROS1 installation from source
RUN mkdir -p /root/Downloads
RUN cd /root/Downloads && \
    wget http://archive.ubuntu.com/ubuntu/pool/universe/h/hddtemp/hddtemp_0.3-beta15-53_amd64.deb && \
    apt-get update -q && \
    apt-get install -yq ./hddtemp_0.3-beta15-53_amd64.deb

RUN cd /root/Downloads && \
    wget https://raw.githubusercontent.com/ros/rosdistro/master/rosdep/base.yaml && \
    sed -i '/focal: \[hddtemp\]/a \    jammy: \[hddtemp\]' base.yaml && \
    sed -i "s|^yaml .*base.yaml$|yaml file:///root/Downloads/base.yaml|" /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep update

RUN apt-get update -q && \
    apt-get install -yq --no-install-recommends liburdfdom-headers-dev liburdfdom-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/catkin_ws && \
    cd /root/catkin_ws && \
    rosinstall_generator ros_comm rosconsole_bridge actionlib actionlib_msgs geometry_msgs common_msgs tf2_msgs tf2_geometry_msgs visualization_msgs --rosdistro noetic --deps --tar > noetic-ros_comm.rosinstall && \
    mkdir -p src && \
    vcs import --input noetic-ros_comm.rosinstall ./src && \
    apt-get update -q && \
    rosdep install --from-paths ./src --ignore-packages-from-source --rosdistro noetic -y --skip-keys=python3-rospkg

RUN cd /root/catkin_ws/src && \
    mkdir -p /root/Downloads/backup && \
    if [ -d rosconsole ]; then mv rosconsole /root/Downloads/backup/; fi && \
    if [ -d urdf ]; then mv urdf /root/Downloads/backup/; fi && \
    git clone https://github.com/dreuter/rosconsole.git && \
    cd rosconsole && \
    git checkout noetic-jammy && \
    cd /root/catkin_ws/src && \
    git clone https://github.com/dreuter/urdf.git && \
    cd urdf && \
    git checkout set-cxx-version && \
    cd /root/catkin_ws/src

# gazebo_msgs for ROS1
RUN cd /root/catkin_ws/src && \
    git clone -b noetic-devel https://github.com/ros-simulation/gazebo_ros_pkgs.git && \
    cd gazebo_ros_pkgs && \
    find . -mindepth 1 -maxdepth 1 -type d ! -name gazebo_msgs -exec rm -rf {} +

# Unset ROS env vars inherited from osrf/ros:humble-desktop-full so that the
# ROS1 Noetic source build does not detect a conflicting humble environment.
# (The original sobits-user variant relied on `sudo` to wipe these vars.)
RUN cd /root/catkin_ws && \
    unset ROS_DISTRO ROS_VERSION ROS_PYTHON_VERSION AMENT_PREFIX_PATH COLCON_PREFIX_PATH && \
    ./src/catkin/bin/catkin_make_isolated --install --install-space /opt/ros/noetic \
        -DCMAKE_BUILD_TYPE=Release \
        --make-args -j$(nproc)

WORKDIR /root

# ============================================================================
# LAYER 1b: ros1_base - Unified stage (local build or pulled from registry)
# ============================================================================
# --full mode:      ROS1_BASE_IMAGE=ros1_base_local (default, built above)
# --msg-build mode: ROS1_BASE_IMAGE=ghcr.io/teamsobits/ros1_base:noetic-humble
FROM ${ROS1_BASE_IMAGE} AS ros1_base

# ============================================================================
# LAYER 2: msg_bridge_base - Custom messages + ros1_bridge (heavy build)
# ============================================================================
# This layer compiles custom ROS1 and ROS2 messages, then builds ros1_bridge.
# It's the most time-consuming layer and is published to ghcr.io for sharing.
FROM ros1_base AS msg_bridge_base

ARG ROS_DOMAIN_ID=0

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

SHELL ["/bin/bash", "-c"]

# ROS2 gazebo_msgs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -q && \
    apt-get install -yq --no-install-recommends \
        ros-humble-gazebo-msgs

# ROS1 custom messages
RUN mkdir -p /root/catkin_ws/src
COPY baked_pkgs/ib2_msgs/ /root/catkin_ws/src/ib2_msgs/
COPY baked_pkgs/platform_msgs/ /root/catkin_ws/src/platform_msgs/
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && cd /root/catkin_ws && catkin_make -j$(nproc)"

# ROS2 custom messages
RUN mkdir -p /root/colcon_msgs_ws/src/ib2_msgs/msg \
    /root/colcon_msgs_ws/src/ib2_msgs/srv \
    /root/colcon_msgs_ws/src/ib2_msgs/action \
    /root/colcon_msgs_ws/src/platform_msgs/msg \
    /root/colcon_msgs_ws/src/platform_msgs/srv
COPY msgs_ros2/ib2_msgs/msg/ /root/colcon_msgs_ws/src/ib2_msgs/msg/
COPY msgs_ros2/ib2_msgs/srv/ /root/colcon_msgs_ws/src/ib2_msgs/srv/
COPY msgs_ros2/ib2_msgs/action/ /root/colcon_msgs_ws/src/ib2_msgs/action/
COPY msgs_ros2/platform_msgs/msg/ /root/colcon_msgs_ws/src/platform_msgs/msg/
COPY msgs_ros2/platform_msgs/srv/ /root/colcon_msgs_ws/src/platform_msgs/srv/
COPY msgs_ros2/ib2_msgs/package.xml /root/colcon_msgs_ws/src/ib2_msgs/package.xml
COPY msgs_ros2/ib2_msgs/CMakeLists.txt /root/colcon_msgs_ws/src/ib2_msgs/CMakeLists.txt
COPY msgs_ros2/platform_msgs/package.xml /root/colcon_msgs_ws/src/platform_msgs/package.xml
COPY msgs_ros2/platform_msgs/CMakeLists.txt /root/colcon_msgs_ws/src/platform_msgs/CMakeLists.txt
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && cd /root/colcon_msgs_ws && colcon build --parallel-workers $(nproc)"

# ros1_bridge installation
RUN mkdir -p /root/ros1_bridge_ws/src
RUN cd /root/ros1_bridge_ws/src && \
    git clone https://github.com/ros2/ros1_bridge.git
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && source /root/colcon_msgs_ws/install/setup.bash && \
    cd /root/ros1_bridge_ws && colcon build --symlink-install --packages-skip ros1_bridge --parallel-workers $(nproc)"
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && source /root/catkin_ws/devel/setup.bash && \
    source /opt/ros/humble/setup.bash && source /root/colcon_msgs_ws/install/setup.bash && \
    cd /root/ros1_bridge_ws && colcon build --symlink-install --packages-select ros1_bridge --cmake-force-configure --parallel-workers $(nproc)"

RUN mkdir -p /root/colcon_ws/src

# ============================================================================
# LAYER 3: final - Application layer (scripts, configuration)
# ============================================================================
# This is the final runtime image with cmd.sh and environment setup.
# Built locally from msg_bridge_base, either pulled or locally built.
# Fast to rebuild when application code changes.
FROM msg_bridge_base AS final

ARG ROS_DOMAIN_ID=0

ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

SHELL ["/bin/bash", "-c"]

# Shell environment scripts
RUN cat > /root/ros2_env.sh <<'EOF'
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
RUN cat > /root/bridge_env.sh <<'EOF'
source /opt/ros/noetic/setup.bash
if [ -f ~/catkin_ws/devel/setup.bash ]; then source ~/catkin_ws/devel/setup.bash; fi
source /opt/ros/humble/setup.bash
if [ -f ~/colcon_msgs_ws/install/setup.bash ]; then source ~/colcon_msgs_ws/install/setup.bash; fi
if [ -f ~/ros1_bridge_ws/install/setup.bash ]; then source ~/ros1_bridge_ws/install/setup.bash; fi
if [ -f ~/colcon_ws/install/setup.bash ]; then source ~/colcon_ws/install/setup.bash; fi
:
EOF

# Add to .bashrc (orange-colored username for visual distinction from host shell)
RUN echo "source /root/ros2_env.sh" >> /root/.bashrc && \
    echo "export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}" >> /root/.bashrc && \
    echo "export PS1='\[\e[38;5;208m\]\u\[\e[0m\]@\h:\w\\$ '" >> /root/.bashrc

# Bridge scripts (application entry point)
RUN mkdir -p /root/bridge
COPY cmd.sh action_bridge_node.py bridge_ros1_helper.py /root/bridge/
RUN chmod +x /root/bridge/cmd.sh /root/bridge/action_bridge_node.py

WORKDIR /root

CMD ["/root/bridge/cmd.sh"]
