# MuJoCo POC Sim Notes (XLeRobot)

**Status (Oct 24, 2026):** Running on an Ubuntu 26.04 laptop, both in a local venv and in a Docker container. Janky, but works as a proof of concept.

## What this is

Upstream XLeRobot's MuJoCo keyboard demo. It loads the robot model (`xlerobot.xml`) into a scene (`scene.xml`) and lets you drive the omni-wheel base and both arms from the keyboard.

It's a "does the model load and move" check, not a training environment.

## Quick start

From `~/personalprojects/XLeRobot/simulation/mujoco`:

**Docker (preferred, same on any Linux machine):**

```bash
docker build -t xlerobot-mujoco .   # only needed once, or after changing files
./run.sh
```

**Local venv (quick path, laptop only):**

```bash
source .venv/bin/activate
python xlerobot_mujoco.py
```

## Controls

Click the sim window first so it receives key presses.

| Part | Keys |
|---|---|
| Base forward / back | Home / End |
| Base left / right | Delete / Page Down |
| Base rotate | Insert / Page Up |
| Left arm (joints 1–3) | Q/A, W/S, E/D |
| Right arm (joints 1–3) | U/J, I/K, O/L |

- On the laptop keyboard, Home/End/Page Up/Page Down may need Fn held.
- Mouse drag rotates the camera.
- Exit: close the window, or Ctrl+C in the terminal.

## Machine and paths

- **Machine:** Ubuntu 26.04 LTS laptop, CPU only
- **Repo:** `~/personalprojects/XLeRobot` (clone of `Vector-Wangel/XLeRobot`)
- **Sim folder:** `~/personalprojects/XLeRobot/simulation/mujoco`
- **JBit-added files in the sim folder:**
  - `Dockerfile`: recipe for the image
  - `.dockerignore`: keeps `.venv` and caches out of the image
  - `run.sh`: runs the container with its window on the host screen
  - `mujoco_poc_sim_notes.md`: this file

---

## Part 1: Local venv setup (what was run)

### 1. Clone

```bash
cd ~/personalprojects && git clone https://github.com/Vector-Wangel/XLeRobot.git
```

### 2. Env

```bash
cd ~/personalprojects/XLeRobot/simulation/mujoco && uv venv --python 3.12 && source .venv/bin/activate
```

- Python 3.12 (3.12.14), because Ubuntu 26.04 ships 3.14.
- Kept separate from the lerobot env so the pinned MuJoCo version can't conflict.

### 3. Install (dry run first)

```bash
uv pip install -r requirements.txt --dry-run
uv pip install -r requirements.txt
python -c "import mujoco; print(mujoco.__version__)"   # expect 3.3.0
```

- 57 packages, all version-pinned. Key ones:
  - `mujoco==3.3.0`: physics engine
  - `mujoco-python-viewer==0.1.4`: 3D window
  - `glfw==2.8.0`: window and keyboard input
- `evdev` builds from source, so it needs `build-essential`.

### 4. Run

```bash
python xlerobot_mujoco.py
```

---

## Part 2: Docker setup (what was run)

### 1. Install Docker (Ubuntu)

```bash
sudo apt update && apt install --dry-run docker.io docker-buildx
sudo apt install docker.io docker-buildx
```

- Installed Docker 29.1.3. `docker-buildx` is the modern build engine; without it, builds warn about a deprecated builder.
- **Don't use the snap version.** Snaps get a private `/tmp`, which breaks the screen sharing.

### 2. Run Docker without sudo

```bash
sudo usermod -aG docker $USER
```

- **Restart the laptop afterward.** Group changes only apply to new sessions.
- Test with `docker run --rm hello-world`, which should print "Hello from Docker!"
- Being in the `docker` group is effectively equivalent to sudo. That's the normal tradeoff on a dev machine.

### 3. Add the container files

Add `Dockerfile`, `.dockerignore`, and `run.sh` to the sim folder.

`.dockerignore` contents:

```
.venv/
__pycache__/
*.pyc
```

### 4. Build

```bash
docker build -t xlerobot-mujoco .
```

- About 2 minutes the first time.
- Image size: 1.87 GB on disk, 430 MB compressed.

### 5. Run

```bash
./run.sh
```

What `run.sh` does:
- **Runs as your user, not root,** with the `video`/`render` groups so it can use the graphics chip.
- **Shares the screen** through the X11 socket and `DISPLAY`.
- **Passes a read-only copy of the display cookie** (`$XAUTHORITY`, falling back to `~/.Xauthority`) and matches the laptop's hostname so the display accepts the connection.
- This approach was chosen over the common `xhost +local:` trick, which lets any local program draw on the screen.

### Troubleshooting log

| Symptom | Cause / fix |
|---|---|
| `permission denied ... docker.sock` | Group change not applied yet. Restart after `usermod`. |
| `Authorization required, but no authorization protocol specified` / `X11: Failed to open display` | Container lacked the display cookie. Fixed in `run.sh` with the `XAUTHORITY` mount + `--hostname`. |
| `mv: cannot stat ~/Downloads/run.sh` | Browser didn't save the download. Created `run.sh` directly in the terminal instead. |

---

## Running on Arch Linux

1. Install and start Docker:
   ```bash
   sudo pacman -S docker docker-buildx
   sudo systemctl enable --now docker.service
   ```
2. Add yourself to the `docker` group (`sudo usermod -aG docker $USER`), then log out and back in (or restart).
3. Get the sim folder, including the JBit-added files above.
4. From the sim folder:
   ```bash
   docker build -t xlerobot-mujoco .
   ./run.sh
   ```

- **Intel/AMD graphics:** should work as-is.
- **NVIDIA graphics:** needs the NVIDIA Container Toolkit plus a small change to `run.sh`. Not set up yet.

## Known limits / later

- Keyboard only moves joints 1–3 on each arm (no wrist or gripper).
- GUI-only. The image isn't set up for headless (no-screen) runs, which cloud training will need.
- The image could be slimmed (drop the compiler after install, trim unused packages).
- The JBit files currently sit untracked in a clone of upstream. They should move to a JBit fork.
