# syntax=docker/dockerfile:1
FROM ghcr.io/teamsobits/ros1_base:noetic-humble

ARG USERNAME=ros
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG ROS_DOMAIN_ID=0

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

SHELL ["/bin/bash", "-c"]

############################# ROS2 gazebo_msgs (apt) ##############################
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -q && \
    sudo apt-get install -yq --no-install-recommends \
        ros-humble-gazebo-msgs

############################# ROS1 custom msgs ##############################
RUN mkdir -p /home/${USERNAME}/catkin_ws/src
COPY --chown=${USERNAME}:${USERNAME} baked_pkgs/ib2_msgs/ /home/${USERNAME}/catkin_ws/src/ib2_msgs/
COPY --chown=${USERNAME}:${USERNAME} baked_pkgs/platform_msgs/ /home/${USERNAME}/catkin_ws/src/platform_msgs/
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && cd /home/${USERNAME}/catkin_ws && catkin_make -j$(nproc)"

############################# ROS2 custom msgs ##############################
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

############################# ros1_bridge installation ##############################
RUN mkdir -p /home/${USERNAME}/ros1_bridge_ws/src
RUN cd /home/${USERNAME}/ros1_bridge_ws/src && \
    git clone https://github.com/ros2/ros1_bridge.git
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && source /home/${USERNAME}/colcon_msgs_ws/install/setup.bash && \
    cd /home/${USERNAME}/ros1_bridge_ws && colcon build --symlink-install --packages-skip ros1_bridge --parallel-workers $(nproc)"
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && source /home/${USERNAME}/catkin_ws/devel/setup.bash && \
    source /opt/ros/humble/setup.bash && source /home/${USERNAME}/colcon_msgs_ws/install/setup.bash && \
    cd /home/${USERNAME}/ros1_bridge_ws && colcon build --symlink-install --packages-select ros1_bridge --cmake-force-configure --parallel-workers $(nproc)"

RUN mkdir -p /home/${USERNAME}/colcon_ws/src

############################# Shell environment scripts ##############################
# Interactive shell env: pure ROS2 (no ros1_bridge_ws / catkin_ws to avoid
# shadowing humble Python pkgs — ros1_bridge_ws transitively re-sources catkin_ws).
# Use if/fi blocks (NOT [ -f ] && source) so the script always returns 0
# even when sourced under `set -e` (colcon-generated setup.bash may return non-zero).
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

# Bridge env: full ROS1+2 mixed (only for cmd.sh / ros1_bridge process)
RUN cat > /home/${USERNAME}/bridge_env.sh <<'EOF' && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/bridge_env.sh
source /opt/ros/noetic/setup.bash
if [ -f ~/catkin_ws/devel/setup.bash ]; then source ~/catkin_ws/devel/setup.bash; fi
source /opt/ros/humble/setup.bash
if [ -f ~/colcon_msgs_ws/install/setup.bash ]; then source ~/colcon_msgs_ws/install/setup.bash; fi
if [ -f ~/ros1_bridge_ws/install/setup.bash ]; then source ~/ros1_bridge_ws/install/setup.bash; fi
if [ -f ~/colcon_ws/install/setup.bash ]; then source ~/colcon_ws/install/setup.bash; fi
:
EOF

# Bake into .bashrc
RUN echo "source /home/${USERNAME}/ros2_env.sh" >> /home/${USERNAME}/.bashrc && \
    echo "export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}" >> /home/${USERNAME}/.bashrc

############################# Bridge scripts (prod entrypoint) ##############################
RUN mkdir -p /home/${USERNAME}/bridge
COPY --chown=${USERNAME}:${USERNAME} cmd.sh action_bridge_node.py bridge_ros1_helper.py /home/${USERNAME}/bridge/
RUN chmod +x /home/${USERNAME}/bridge/cmd.sh /home/${USERNAME}/bridge/action_bridge_node.py

WORKDIR /home/${USERNAME}

CMD ["/home/sobits/bridge/cmd.sh"]
