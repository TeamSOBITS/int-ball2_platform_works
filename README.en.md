<a name="readme-top"></a>

[JA](README.md) | [EN](README.en.md)

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

# Platform Works

<!-- Table of Contents -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#overview">Overview</a>
    </li>
    <li>
      <a href="#setup">Setup</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li>
      <a href="#usage">Usage</a>
      <ul>
        <li><a href="#building-the-container">Building the Container</a></li>
        <li><a href="#how-to-run-and-operate-the-container">How to Run and Operate the Container</a></li>
        <li><a href="#directory-structure-in-the-container">Directory structure in the container</a></li>
        <li><a href="#advanced-build-modes">Advanced Build Modes</a></li>
      </ul>
    </li>
    <li><a href="#milestone">Milestone</a></li>
    <li><a href="#references">References</a></li>
  </ol>
</details>

## Overview
This repository is for creating a docker image of the ROS2 bridge with int-ball2_simulator.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Setup

This section describes how to set up this repository.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Prerequisites
First, prepare the following environment before proceeding to the next installation method.
| System  | Version |
| --- | --- |
| Ubuntu | 22.04 (Jammy Jellyfish) or 24.04 (Noble Numbat)|

> [!WARNING]
> When using the `GPU version` of Docker, be sure to install the [Nvidia Driver](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/ubuntu.html).
> It is not necessary to install CUDA or cuDNN.

> [!WARNING]
> About 10GB of storage is required to create a container. Please ensure sufficient capacity.

### Installation
1. Clone this repository locally.
    ```sh
    git clone -b humble-bridge https://github.com/TeamSOBITS/int-ball2_platform_works.git
    ```
2. Navigate to the installation folder in the repository.
    ```sh
    cd ball2_platform_works/ros2_bridge_ws/setup_sh/
    ```
3. Install the necessary resources. **This step is not required if you already have other docker containers or images.**
    ```sh
    bash install_docker.sh
    ```
    To use GPU within the Docker container, also run the following command.
    ```sh
    bash install_nvidia_docker.sh
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Building the Container
1. Copy the `ros2_bridge_ws` directory and paste it into your Home directory or elsewhere.
    - At this time, change the name of the duplicated folder.
    - Example: `ros2_bridge_ws` → `my_new_ws`
    - Ensure that container names do not overlap.
2. Build the image from the Dockerfile. Since it only pulls a pre-built image from ghcr.io, this takes **about 1 minute**.
    ```bash
    $ gh auth login                                    # only if not already authenticated
    $ gh auth refresh -h github.com -s read:packages
    $ gh auth token | docker login ghcr.io -u <your GitHub username> --password-stdin
    $ cd {container_PATH}/docker
    $ bash build.sh
    ```
    > [!NOTE]
    > If you get a `denied` error, you don't have access to the `teamsobits` organization's packages. Please ask a repository administrator for an invite.

    For advanced build modes intended for maintainers (updating message definitions, full local builds, etc.), see [Advanced Build Modes](#advanced-build-modes).

3. Start the container from the image.
    ```bash
    $ bash up.sh 
    ```

4. Access the running container from another terminal.
    ```bash
    $ bash exec.sh
    # >> {container_name} username@:~$　← changes to this display
    ```
    By default this enters the shell as the same user (UID/GID) as the host. If you need a root shell for system-wide administrative tasks (e.g. `apt` operations), you can switch to one:
    ```bash
    $ bash exec.sh --root
    ```
    If you want quick access to attach to the running container from the host side, append the contents of [docs/dock.sh](docs/dock.sh) to your **host's** `~/.bashrc` (not the container's) — this is a personal setting outside this repository's management scope.
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### How to Run and Operate the Container
1. Start the simulator-side container.
2. Start the bridge container created with the following command.
    ```bash
    bash exec.sh
    ```
3. Start the bridge with the following command.
    ```sh
    bash ~/bridge/cmd.sh
    # or, using the alias
    bridge
    ```

The following functions/aliases are already defined in the container's `.bashrc`:
- **`rid [ID]`**: Check/set `ROS_DOMAIN_ID`. Shows the current value when called with no argument; sets it to the given value otherwise.
- **`bridge`**: Alias for `bash /root/bridge/cmd.sh` (shortcut for step 3).
- **`cb`**: Runs `colcon build --symlink-install` in `colcon_ws` and reloads `.bashrc`. Use this after changing development code.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Directory structure in the container
The development user's home directory in the container is `/home/<host username>`. See below for where development code is placed.

```sh
/home/<username>
├── .bashrc             # ROS2 environment, rid function, cb/bridge aliases, etc.
├── colcon_ws -> /root/colcon_ws              # symlink
├── catkin_ws -> /root/catkin_ws              # symlink
├── colcon_msgs_ws -> /root/colcon_msgs_ws    # symlink
├── ros1_bridge_ws -> /root/ros1_bridge_ws    # symlink
└── bridge -> /root/bridge                    # symlink

/root                    # Workspaces physically live here (ownership chowned to you, linked above)
├── bridge              # ROS Actions bridge, cmd.sh, etc.
├── catkin_ws           # ROS1 environment
├── colcon_msgs_ws      # ROS2 custom messages
├── colcon_ws           # Development code (host's ../src is bind-mounted here)
├── ros1_bridge_ws      # ROS1/ROS2 bridge
├── ros2_env.sh         # ROS2 environment script (for interactive shell)
├── bridge_env.sh       # ROS1+ROS2 mixed environment script (for bridge process)
└── Downloads
```

Please place development code under the host's `ros2_bridge_ws/src/` (at the same level as `docker/`).

#### About Environment Scripts

- **`ros2_env.sh`**: Automatically sourced in the interactive shell (`bash exec.sh`). Provides a pure ROS2 environment without ROS1 paths mixed in, ensuring accurate Python package resolution.
- **`bridge_env.sh`**: Used only in the ROS1/ROS2 bridge process (`cmd.sh`). Sets up both ROS1 and ROS2 environments to enable mutual translation of custom messages.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Advanced Build Modes
The Docker image has a 3-layer structure:
- **Layer 1 (ros1_base)**: OS + ROS1 Noetic + ROS2 Humble foundation (shared on ghcr.io)
- **Layer 2 (msg_bridge_base)**: Custom messages + pre-built ros1_bridge (shared on ghcr.io)
- **Layer 3 (final)**: Application scripts (local build)

| Mode | Command | Purpose | Time | Auth |
|---|---|---|---|---|
| `--pull` (default) | `bash build.sh` | Regular development | ~1 minute | pull auth (above) |
| `--msg-build` | `bash build.sh --msg-build` | Build when message definitions are updated | 20-30 min | pull auth (above) |
| `--msg-build --push` | `GITHUB_USER=$(gh api user --jq .login) GITHUB_TOKEN=$(gh auth token) bash build.sh --msg-build --push` | Share the updated `msg_bridge_base` on ghcr.io (maintainers) | 20-30 min | `write:packages` additionally required |
| `--full` | `bash build.sh --full` | Full environment validation/customization | 40-60 min | none (fully local build) |
| `--full --push` | `GITHUB_USER=$(gh api user --jq .login) GITHUB_TOKEN=$(gh auth token) bash build.sh --full --push` | Share `ros1_base` foundation updates on ghcr.io (maintainers) | 40-60 min+ | `write:packages` additionally required |

> [!NOTE]
> - `--push` cannot be used on its own; always use it together with `--msg-build` or `--full`.
> - If you need `write:packages`, run `gh auth refresh -h github.com -s write:packages` beforehand.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Milestone
Please visit the [Issue page][issues-url] to check for current bugs or requests for new features.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


### References
- Official website: [Docker Docs](https://docs.docker.com/)
- [Docker Workspaces](https://github.com/TeamSOBITS/docker_ws)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/TeamSOBITS/int-ball2_platform_works.svg?style=for-the-badge
[contributors-url]: https://github.com/TeamSOBITS/int-ball2_platform_works/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/TeamSOBITS/int-ball2_platform_works.svg?style=for-the-badge
[forks-url]: https://github.com/TeamSOBITS/int-ball2_platform_works/network/members
[stars-shield]: https://img.shields.io/github/stars/TeamSOBITS/int-ball2_platform_works.svg?style=for-the-badge
[stars-url]: https://github.com/TeamSOBITS/int-ball2_platform_works/stargazers
[issues-shield]: https://img.shields.io/github/issues/TeamSOBITS/int-ball2_platform_works.svg?style=for-the-badge
[issues-url]: https://github.com/TeamSOBITS/int-ball2_platform_works/issues
[license-shield]: https://img.shields.io/github/license/TeamSOBITS/int-ball2_platform_works.svg?style=for-the-badge
[license-url]: LICENSE
