<a name="readme-top"></a>

[JA](README.md) | [EN](README.en.md)

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

# Platform Works
<!-- 目次 -->
<details>
  <summary>目次</summary>
  <ol>
    <li>
      <a href="#概要">概要</a>
    </li>
    <li>
      <a href="#セットアップ">セットアップ</a>
      <ul>
        <li><a href="#環境条件">環境条件</a></li>
        <li><a href="#インストール方法">インストール方法</a></li>
      </ul>
    </li>
    <li>
    　<a href="#実行操作方法">実行・操作方法</a>
      <ul>
        <li><a href="#コンテナのビルド方法">コンテナのビルド方法</a></li>
        <li><a href="#コンテナの実行・操作方法">コンテナの実行・操作方法</a></li>
        <li><a href="#コンテナ内のディレクトリ構造">コンテナ内のディレクトリ構造</a></li>
      </ul>
    </li>
    <li><a href="#マイルストーン">マイルストーン</a></li>
    <li><a href="#参考文献">参考文献</a></li>
  </ol>
</details>

## 概要
int-ball2_simulatorとのROS2 bridgeのdocker imageを作成するためのリポジトリです

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

## セットアップ

ここで，本レポジトリのセットアップ方法について説明します．

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

### 環境条件
まず，以下の環境を整えてから，次のインストール方法に進んでください．
| System  | Version |
| --- | --- |
| Ubuntu | 22.04 (Jammy Jellyfish) or 24.04 (Noble Numbat)|

> [!WARNING]
> `GPU版`のDockerを使用する場合は，必ず[Nvidia Driver](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/ubuntu.html)のインストールを済ませてください．
> CUDAやcuDNNをインストールすることは必要ではありません．

> [!WARNING]
> コンテナの作成には10GBほどのストレージが必要です．十分な容量を確保してください．

### インストール方法
1. 本レポジトリをローカルにcloneします．
    ```sh
    git clone -b humble-bridge https://github.com/TeamSOBITS/int-ball2_platform_works.git
    ```
2. レポジトリの中のインストールのフォルダへ移動します．
    ```sh
    cd ball2_platform_works/ros2_bridge_ws/setup_sh/
    ```
3. 必要なリソースをインストールします．**すでに別のdockerコンテナやイメージがある場合は不要です。**
    ```sh
    bash install_docker.sh
    ```
    Dockerコンテナ内でGPUを使う場合．以下のコマンドも実行します．
    ```sh
    bash install_nvidia_docker.sh
    ```

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

## 実行・操作方法

### コンテナのビルド方法
1. `ros2_bridge_ws`のディレクトリをディレクトリごとコピーし，Homeディレクトリなどに貼り付けてください．
    - この際，複製されたフォルダの名前を変更してください．
    - 例: `ros2_bridge_ws` → `my_new_ws`
    - コンテナの名前が被らないようにしてください．
2. Dockerfileからイメージをビルドします.
    ```bash
    $ cd {コンテナPATH}/docker
    $ bash build.sh
    ```

3. イメージからコンテナを起動します．
    ```bash
    $ bash up.sh 
    ```

4. 起動中のコンテナに別端末からアクセスします．
    ```bash
    $ bash exec.sh
    # >> {コンテナ名} username@:~$　← この表示に切り替わる
    ```
<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

### コンテナの実行・操作方法
1. シム側のコンテナを起動する
2. 以下のコマンドで作成したbridgeのコンテナを起動する．
    ```bash
    bash exec.sh
    ```
3. 以下のコマンドでブリッジを起動する．
    ```sh
    bash ~/bridge/cmd.sh
    ```
<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

### コンテナ内のディレクトリ構造
- コンテナ内のディレクトリ構造は以下の様になっています
- 基本的に開発コードは`colcon_ws`内に記述してください

    ```sh
    /home
    └── sobits
        ├── bridge          # ROS Actionのブリッジ、cmd.shなど
        ├── catkin_ws       # ROS1環境
        ├── colcon_msgs_ws  # ROS1独自msg
        ├── colcon_ws       # 開発コード  
        ├── Downloads       # 
        ├── ros1_bridge_ws  # ROS1 Bridge
        └── ros_entrypoint.sh
    ```
## マイルストーン
現時点のバッグや新規機能の依頼を確認するために[Issueページ][issues-url] をご覧ください．

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>


### 参考文献
- 公式サイト: [Docker Docs](https://docs.docker.com/)
- [Docker Workspaces](https://github.com/TeamSOBITS/docker_ws)

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

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