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
      </ul>
    </li>
    <li><a href="#milestone">Milestone</a></li>
    <li><a href="#references">References</a></li>
  </ol>
</details>

## Introduction
This repository is for creating a docker image of the ROS2 bridge with int-ball2_simulator.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

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

## Launch and Usage

### Building the Container
1. Copy the `ros2_bridge_ws` directory and paste it into your Home directory or elsewhere.
    - At this time, change the name of the duplicated folder.
    - Example: `ros2_bridge_ws` → `my_new_ws`
    - Ensure that container names do not overlap.
2. Build the image from the Dockerfile.

#### Build Modes

The Docker image has a 3-layer structure:
- **Layer 1 (ros1_base)**: OS + ROS1 Noetic + ROS2 Humble foundation (shared on ghcr.io)
- **Layer 2 (msg_bridge_base)**: Custom messages + pre-built ros1_bridge (shared on ghcr.io)
- **Layer 3 (final)**: Application scripts (local build)

`build.sh` supports 4 build modes:

##### 1. `--pull` (default - recommended)
Pulls the pre-built `msg_bridge_base` and builds only the application layer locally. **Fastest** (about 1 minute or less) and ideal for daily development.
```bash
$ cd {container_PATH}/docker
$ bash build.sh
# or
$ bash build.sh --pull
```

##### 2. `--msg-build`
Used when message definitions are updated. Builds message definitions and ros1_bridge from `ros1_base`, generating a new `msg_bridge_base` (20-30 minutes).
```bash
$ cd {container_PATH}/docker
$ bash build.sh --msg-build
```

##### 3. `--msg-build --push`
Same as `--msg-build`, but pushes the new `msg_bridge_base` to ghcr.io after building. **When one team member runs this command after updating messages**, other members can build quickly using `--pull`. GitHub authentication required (described below).
```bash
$ cd {container_PATH}/docker
$ GITHUB_USER=<username> GITHUB_TOKEN=<token> bash build.sh --msg-build --push
```

##### 4. `--full`
Completely builds ros1_base locally, then builds messages and ros1_bridge. Use for full environment validation or when customization is needed (40-60 minutes or more).
```bash
$ cd {container_PATH}/docker
$ bash build.sh --full
```

##### 5. `--full --push`
Same as `--full`, but pushes `ros1_base` to ghcr.io after building. Use when making major foundational changes, such as ROS version updates. GitHub authentication required.
```bash
$ cd {container_PATH}/docker
$ GITHUB_USER=<username> GITHUB_TOKEN=<token> bash build.sh --full --push
```

#### Recommended Build Workflow

| Situation | Command | Time |
|-----------|---------|------|
| Regular development | `bash build.sh --pull` | ~1 minute |
| Update message definitions (maintainer) | `bash build.sh --msg-build --push` | ~30 minutes |
| Update message definitions (other members) | `bash build.sh --pull` | ~1 minute |
| Full environment validation | `bash build.sh --full` | ~60 minutes |

#### GitHub Personal Access Token Setup (required only for `--push`)

To push images to ghcr.io, a GitHub Personal Access Token (PAT) is required:

1. Visit [GitHub Settings - Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token" → "Generate new token (classic)"
3. Enter a token name (e.g., `ghcr-push-token`)
4. Set an expiration date
5. Select `write:packages` in scopes
6. Click "Generate token" and copy it

Set as environment variables and run:
```bash
$ export GITHUB_USER=<GitHub username>
$ export GITHUB_TOKEN=<copied token>
$ cd {container_PATH}/docker
$ bash build.sh --msg-build --push
```

> [!NOTE]
> - When using `--push`, always use it together with `--msg-build` or `--full`
> - You can persist GitHub PAT by setting it as environment variables or adding to `.bashrc`
> - Periodically check the expiration date of your PAT and update if necessary

3. Start the container from the image.
    ```bash
    $ bash up.sh 
    ```

4. Access the running container from another terminal.
    ```bash
    $ bash exec.sh
    # >> {container_name} username@:~$　← changes to this display
    ```
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
    ```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Directory structure in the container
The directory structure within the container is as follows. Basically, please write development code in `colcon_ws`.

```sh
/root
├── bridge              # ROS Actions bridge, cmd.sh, etc.
├── catkin_ws           # ROS1 environment
├── colcon_msgs_ws      # ROS2 custom messages
├── colcon_ws           # Development code
├── ros1_bridge_ws      # ROS1/ROS2 bridge
├── ros2_env.sh         # ROS2 environment script (for interactive shell)
├── bridge_env.sh       # ROS1+ROS2 mixed environment script (for bridge process)
└── Downloads
```

> [!NOTE]
> The container runs as the `root` user, so the home directory is `/root` (not `/home/root`).
> When you enter the interactive shell via `bash exec.sh`, the username (`root`) at the left side of the prompt is displayed in orange to visually distinguish it from your host shell.
> The bind-mounted `../src` is owned by `root` inside the container, so be mindful of permissions when editing it from the host.

#### About Environment Scripts

- **`ros2_env.sh`**: Automatically sourced in interactive shell (`bash exec.sh`). Provides a pure ROS2 environment without ROS1 paths mixed in, ensuring accurate Python package resolution.
- **`bridge_env.sh`**: Used only in the ROS1/ROS2 bridge process (`cmd.sh`). Sets up both ROS1 and ROS2 environments to enable mutual translation of custom messages.

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