#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BAKED_DIR="${ROOT_DIR}/baked_pkgs"
TARGET_DIR="${ROOT_DIR}/msgs_ros2"

rm -rf "${TARGET_DIR}/ib2_msgs/msg" \
       "${TARGET_DIR}/ib2_msgs/srv" \
       "${TARGET_DIR}/ib2_msgs/action" \
       "${TARGET_DIR}/platform_msgs/msg" \
       "${TARGET_DIR}/platform_msgs/srv"

mkdir -p "${TARGET_DIR}/ib2_msgs/msg" \
         "${TARGET_DIR}/ib2_msgs/srv" \
         "${TARGET_DIR}/ib2_msgs/action" \
         "${TARGET_DIR}/platform_msgs/msg" \
         "${TARGET_DIR}/platform_msgs/srv"

cp -a "${BAKED_DIR}/ib2_msgs/msg/." "${TARGET_DIR}/ib2_msgs/msg/"
cp -a "${BAKED_DIR}/ib2_msgs/srv/." "${TARGET_DIR}/ib2_msgs/srv/"
cp -a "${BAKED_DIR}/ib2_msgs/action/." "${TARGET_DIR}/ib2_msgs/action/"
cp -a "${BAKED_DIR}/platform_msgs/msg/." "${TARGET_DIR}/platform_msgs/msg/"
cp -a "${BAKED_DIR}/platform_msgs/srv/." "${TARGET_DIR}/platform_msgs/srv/"

find "${TARGET_DIR}/ib2_msgs" -type f \( -name '*.msg' -o -name '*.srv' -o -name '*.action' \) -print0 | \
  xargs -0 sed -i \
    -e 's/^[[:space:]]*time\b/builtin_interfaces\/Time/' \
    -e 's/^[[:space:]]*duration\b/builtin_interfaces\/Duration/' \
    -e 's/^Header /std_msgs\/Header /' \
    -e 's/\bFullHD\b/FULL_HD/g' \
    -e 's/\bFour_K\b/FOUR_K/g' \
    -e 's/\bEV\b/ev/g'

find "${TARGET_DIR}/platform_msgs" -type f \( -name '*.msg' -o -name '*.srv' \) -print0 | \
  xargs -0 sed -i \
    -e 's/^[[:space:]]*time\b/builtin_interfaces\/Time/' \
    -e 's/^[[:space:]]*duration\b/builtin_interfaces\/Duration/' \
    -e 's/^Header /std_msgs\/Header /'

echo "ROS2 interface files updated under ${TARGET_DIR}."
