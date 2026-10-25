# XLeRobot MuJoCo keyboard sim (JBit)
# Build:  docker build -t xlerobot-mujoco .

# Minimal Debian 13 with Python 3.12 (matches the local venv)
FROM python:3.12-slim-trixie

# No interactive install prompts, no pip download cache, print output immediately
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

# System libraries:
#   build-essential  -> C compiler (evdev builds from source)
#   libgl1/libglx-mesa0/libgl1-mesa-dri/libegl1 -> OpenGL + Intel/AMD graphics drivers
#   libx11-6 ... libxi6 -> X11 libraries so GLFW can open a window on the host screen
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libgl1 libglx-mesa0 libgl1-mesa-dri libegl1 \
        libx11-6 libxrandr2 libxinerama1 libxcursor1 libxi6 \
    && rm -rf /var/lib/apt/lists/*

# Everything lives in /app inside the container
WORKDIR /app

# Install Python packages first so Docker caches this slow step
COPY requirements.txt .
RUN pip install -r requirements.txt

# Robot model, scene, assets, and controller script
COPY . .

# What runs when the container starts
CMD ["python", "xlerobot_mujoco.py"]
