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
        <li><a href="#高度なビルドモード">高度なビルドモード</a></li>
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
2. Dockerfileからイメージをビルドします．事前ビルド済みのイメージを ghcr.io から取得するだけなので，**1分ほど**で終わります．
    ```bash
    $ gh auth login                                    # 未認証の場合のみ
    $ gh auth refresh -h github.com -s read:packages
    $ gh auth token | docker login ghcr.io -u <GitHubユーザー名> --password-stdin
    $ cd {コンテナPATH}/docker
    $ bash build.sh
    ```
    > [!NOTE]
    > `denied` エラーが出る場合，`teamsobits` 組織のパッケージへのアクセス権がありません．リポジトリ管理者に招待を依頼してください．

    メッセージ定義の更新や完全ローカルビルドなど，メンテナー向けの高度なビルドモードは[こちら](#高度なビルドモード)を参照してください．

3. イメージからコンテナを起動します．
    ```bash
    $ bash up.sh 
    ```

4. 起動中のコンテナに別端末からアクセスします．
    ```bash
    $ bash exec.sh
    # >> {コンテナ名} username@:~$　← この表示に切り替わる
    ```
    既定ではホストと同じユーザー (UID/GID) でシェルに入ります．`apt` 操作などシステム全体に関わる管理作業が必要な場合は，`root` シェルに切り替えられます．
    ```bash
    $ bash exec.sh --root
    ```
    ホスト側で実行中のコンテナへ手早くアタッチしたい場合は，[docs/dock.sh](docs/dock.sh) の内容を各自の**ホストの** `~/.bashrc`（コンテナ内ではありません）に追記してください（本リポジトリの管理対象外の個人設定です）．
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
    # または、エイリアスで
    bridge
    ```

コンテナ内の`.bashrc`には，以下の関数・エイリアスが定義済みです：
- **`rid [ID]`**: `ROS_DOMAIN_ID`の確認・設定．引数なしで現在値を表示，引数を渡すとその値に設定します．
- **`bridge`**: `bash /root/bridge/cmd.sh`のエイリアス（手順3のショートカット）．
- **`cb`**: `colcon_ws`で`colcon build --symlink-install`を実行し，`.bashrc`を再読み込みします．開発コードを変更した際に使用します．

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

### コンテナ内のディレクトリ構造
コンテナ内の開発ユーザーのホームディレクトリは `/home/<ホストのユーザー名>` です．開発コードの配置場所は下記を参照してください．

```sh
/home/<username>
├── .bashrc             # ROS2環境の読み込み、rid関数、cb/bridgeエイリアスなど
├── colcon_ws -> /root/colcon_ws              # シンボリックリンク
├── catkin_ws -> /root/catkin_ws              # シンボリックリンク
├── colcon_msgs_ws -> /root/colcon_msgs_ws    # シンボリックリンク
├── ros1_bridge_ws -> /root/ros1_bridge_ws    # シンボリックリンク
└── bridge -> /root/bridge                    # シンボリックリンク

/root                    # ワークスペースの実体はここに置かれています (chown 済み、上記のリンク先)
├── bridge              # ROS Actionのブリッジ、cmd.shなど
├── catkin_ws           # ROS1環境
├── colcon_msgs_ws      # ROS2カスタムメッセージ
├── colcon_ws           # 開発コード (ホストの ../src がここにbind mountされる)
├── ros1_bridge_ws      # ROS1/ROS2ブリッジ
├── ros2_env.sh         # ROS2環境スクリプト（対話型シェル用）
├── bridge_env.sh       # ROS1+ROS2混合環境スクリプト（ブリッジプロセス用）
└── Downloads
```

開発コードはホスト側の `ros2_bridge_ws/src/`（`docker/`と同階層）に配置してください．

#### 環境スクリプトについて

- **`ros2_env.sh`**: 対話的なシェル（`bash exec.sh`）で自動的にソースされます．純粋なROS2環境を提供し，ROS1のパスが混在していないため，Pythonパッケージの解決が正確です．
- **`bridge_env.sh`**: ROS1/ROS2ブリッジプロセス（`cmd.sh`）でのみ使用されます．ROS1とROS2の両方の環境をセットアップして，カスタムメッセージの相互翻訳を可能にします．

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

### 高度なビルドモード
Docker イメージは3層構造になっています：
- **Layer 1 (ros1_base)**: OS + ROS1 Noetic + ROS2 Humble 基盤（ghcr.io で共有）
- **Layer 2 (msg_bridge_base)**: カスタムメッセージ + ros1_bridge ビルド済み（ghcr.io で共有）
- **Layer 3 (final)**: アプリケーションスクリプト（ローカルビルド）

| モード | コマンド | 用途 | 時間 | 認証 |
|---|---|---|---|---|
| `--pull`（デフォルト） | `bash build.sh` | 通常の開発 | ~1分 | pull認証（前述） |
| `--msg-build` | `bash build.sh --msg-build` | メッセージ定義を更新した際のビルド | 20-30分 | pull認証（前述） |
| `--msg-build --push` | `GITHUB_USER=$(gh api user --jq .login) GITHUB_TOKEN=$(gh auth token) bash build.sh --msg-build --push` | 更新した`msg_bridge_base`をghcr.ioに共有（メンテナー用） | 20-30分 | `write:packages`が追加で必要 |
| `--full` | `bash build.sh --full` | 環境の完全検証・カスタマイズ | 40-60分 | 不要（全てローカルビルド） |
| `--full --push` | `GITHUB_USER=$(gh api user --jq .login) GITHUB_TOKEN=$(gh auth token) bash build.sh --full --push` | `ros1_base`の基盤更新をghcr.ioに共有（メンテナー用） | 40-60分+ | `write:packages`が追加で必要 |

> [!NOTE]
> - `--push`は単独では使えず，必ず`--msg-build`または`--full`と一緒に使用します．
> - `write:packages`が必要な場合は事前に`gh auth refresh -h github.com -s write:packages`を実行してください．

<p align="right">(<a href="#readme-top">上に戻る</a>)</p>

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