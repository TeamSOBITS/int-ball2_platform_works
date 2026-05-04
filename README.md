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

#### ビルドモード

Docker イメージは3層構造になっています：
- **Layer 1 (ros1_base)**: OS + ROS1 Noetic + ROS2 Humble 基盤（ghcr.io で共有）
- **Layer 2 (msg_bridge_base)**: カスタムメッセージ + ros1_bridge ビルド済み（ghcr.io で共有）
- **Layer 3 (final)**: アプリケーションスクリプト（ローカルビルド）

`build.sh`は4つのビルドモードをサポートしています：

##### 1. `--pull`（デフォルト - 推奨）
事前ビルドされた `msg_bridge_base` をプルして，アプリケーション層のみをローカルビルドします．**最も高速**（約1分以内）で，日常開発に最適です．
```bash
$ cd {コンテナPATH}/docker
$ bash build.sh
# または
$ bash build.sh --pull
```

##### 2. `--msg-build`
メッセージ定義を更新した際に使用します． `ros1_base` からメッセージ定義と ros1_bridge をビルドし，新しい `msg_bridge_base` を生成します（20-30分）．
```bash
$ cd {コンテナPATH}/docker
$ bash build.sh --msg-build
```

##### 3. `--msg-build --push`
`--msg-build` と同じですが，ビルド完了後に新しい `msg_bridge_base` を ghcr.io にプッシュします．**チームメンバーがメッセージを更新した場合，メンテナー1名がこのコマンドを実行**することで，他のメンバーは `--pull` で高速にビルドできるようになります．GitHub 認証が必要です（後述）．
```bash
$ cd {コンテナPATH}/docker
$ GITHUB_USER=<ユーザー名> GITHUB_TOKEN=<トークン> bash build.sh --msg-build --push
```

##### 4. `--full`
ros1_base をローカルで完全ビルドしてから，メッセージと ros1_bridge をビルドします．環境の完全検証やカスタマイズが必要な場合に使用します（40-60分以上）．
```bash
$ cd {コンテナPATH}/docker
$ bash build.sh --full
```

##### 5. `--full --push`
`--full` と同じですが，完了後に `ros1_base` を ghcr.io にプッシュします．ROS のバージョン更新など，基盤を大きく変更した場合に使用します．GitHub 認証が必要です．
```bash
$ cd {コンテナPATH}/docker
$ GITHUB_USER=<ユーザー名> GITHUB_TOKEN=<トークン> bash build.sh --full --push
```

#### 推奨されるビルドフロー

| 状況 | コマンド | 時間 |
|------|---------|------|
| 通常の開発 | `bash build.sh --pull` | ~1分 |
| メッセージ定義を更新（メンテナー） | `bash build.sh --msg-build --push` | ~30分 |
| メッセージ定義を更新（他のメンバー） | `bash build.sh --pull` | ~1分 |
| 環境の完全検証 | `bash build.sh --full` | ~60分 |

#### GitHub Personal Access Token の設定（`--push` を使用する場合）

ghcr.io にイメージをプッシュするには，GitHub Personal Access Token（PAT）が必要です：

1. [GitHub Settings - Personal access tokens](https://github.com/settings/tokens)にアクセスします
2. "Generate new token" → "Generate new token (classic)"をクリックします
3. トークンの名前を入力します（例：`ghcr-push-token`）
4. 有効期限を設定します
5. スコープで`write:packages`を選択します
6. "Generate token"をクリックしてトークンをコピーします

環境変数として設定して実行します：
```bash
$ export GITHUB_USER=<GitHubユーザー名>
$ export GITHUB_TOKEN=<コピーしたトークン>
$ cd {コンテナPATH}/docker
$ bash build.sh --msg-build --push
```

> [!NOTE]
> - `--push` を使用する場合は必ず `--msg-build` または `--full` と一緒に使用してください
> - GitHub PAT は環境変数として設定するか，`.bashrc` に追加することで永続化できます
> - PAT の有効期限を定期的に確認し，必要に応じて更新してください

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
コンテナ内のディレクトリ構造は以下の様になっています．基本的に開発コードは`colcon_ws`内に記述してください．

```sh
/home
└── sobits
    ├── bridge              # ROS Actionのブリッジ、cmd.shなど
    ├── catkin_ws           # ROS1環境
    ├── colcon_msgs_ws      # ROS2カスタムメッセージ
    ├── colcon_ws           # 開発コード  
    ├── ros1_bridge_ws      # ROS1/ROS2ブリッジ
    ├── ros2_env.sh         # ROS2環境スクリプト（対話型シェル用）
    ├── bridge_env.sh       # ROS1+ROS2混合環境スクリプト（ブリッジプロセス用）
    └── Downloads
```

#### 環境スクリプトについて

- **`ros2_env.sh`**: 対話的なシェル（`bash exec.sh`）で自動的にソースされます．純粋なROS2環境を提供し，ROS1のパスが混在していないため，Pythonパッケージの解決が正確です．
- **`bridge_env.sh`**: ROS1/ROS2ブリッジプロセス（`cmd.sh`）でのみ使用されます．ROS1とROS2の両方の環境をセットアップして，カスタムメッセージの相互翻訳を可能にします．

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