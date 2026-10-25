#!/usr/bin/env bash
# Run the XLeRobot MuJoCo sim container with its window on the host screen.
# Usage: ./run.sh   (build first with: docker build -t xlerobot-mujoco .)
set -e

# --user / --group-add : run as you (not root), with access to the graphics chip
# --hostname           : match the laptop's name so the display key is accepted
# DISPLAY + X11 socket : lets the container open a window on your screen
# XAUTHORITY + mount   : read-only copy of the display key ("cookie")
# HOME=/tmp            : gives libraries a writable spot for config/cache files
# --device /dev/dri    : hardware-accelerated 3D drawing
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --group-add "$(getent group video | cut -d: -f3)" \
  --group-add "$(getent group render | cut -d: -f3)" \
  --hostname "$(hostname)" \
  -e DISPLAY="$DISPLAY" \
  -e XAUTHORITY=/tmp/.Xauthority \
  -v "${XAUTHORITY:-$HOME/.Xauthority}":/tmp/.Xauthority:ro \
  -e HOME=/tmp \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --device /dev/dri \
  xlerobot-mujoco
