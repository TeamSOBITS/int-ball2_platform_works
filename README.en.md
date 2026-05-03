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
    ```bash
    $ cd {container_PATH}/docker
    $ bash build.sh
    ```

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
- The directory structure within the container is as follows:
- Basically, please write development code in `colcon_ws`.

    ```sh
    /home
    └── sobits
        ├── bridge          # Bridge for ROS Actions, cmd.sh, etc.
        ├── catkin_ws       # ROS1 environment
        ├── colcon_msgs_ws  # Custom ROS1 messages
        ├── colcon_ws       # Development code  
        ├── Downloads       # 
        ├── ros1_bridge_ws  # ROS1 Bridge
        └── ros_entrypoint.sh
    ```

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