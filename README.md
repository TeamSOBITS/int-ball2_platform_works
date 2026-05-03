# Platform Works

競技用Docker Image作成用リポジトリです


## インストール方法
以下はすべてローカルで行います。
1. `ローカル`でシム内の`shared_data_sim`配下に本リポジトリをclone

2. `user_programs` まで `cd`して、各サブモジュールをcloneする(初回のみ)
    - YOLO, Depth Anything V2, intball2_commomなど
    ```sh
    git submodule update --init --recursive
    ```
3. サブモジュールを最新の状態に更新する場合、`user_programs` まで `cd`して以下のコマンド
    ```sh
    git submodule update --remote intball2_common
    ```
4. 以下の階層に`cd`で移動

    ```sh
    int-ball2_platform_works/platform_docker/sample_tests
    ```
5. Depth Anything V2のモデルをダウンロードし適切な場所(intball2_common/intball_programs/config)に配置

6. 以下のコマンドでイメージをビルド
    ```bash
    docker build . -t ib2_user:0.1
    ```

**コードを更新する場合、手順3から実行6まで実行してください**

## 実行・操作方法

- GPUを使用する場合は、コンテナ起動前に以下を実行してください
    1. `/etc/docker/daemon.json`を書き換えて`default-runtime`を変更する
        ```sh
        sudo nano /etc/docker/daemon.json
        ```

        エディタが開くため、内容を以下に書き換えてください
        ```
        {
            "default-runtime": "nvidia",
            "runtimes": {
                "nvidia": {
                    "args": [],
                    "path": "nvidia-container-runtime"
                }
            }
        }
        ```
        - 保存: Ctrl + O （オー）を押す。
        - 確定: 下にファイル名が出ますので、そのまま Enter を押す。
        - 終了: Ctrl + X を押してエディタを閉じる。
    2. Dockerサービスを再起動する
        ```sh
        sudo systemctl restart docker
        ```
    3. 設定が正しく読み込まれたか確認します。
        ```sh
        docker info | grep "Default Runtime"
        ```
        - 出力が Default Runtime: nvidia になっていればよい

- GSEからではなく、ローカルのターミナルから起動する場合(**デバッグ用**)
    ```sh
    docker compose down
    PWD=$(pwd) docker compose up -d
    ```
    起動後はコンテナ内で以下を実行
    ```sh
    source /opt/ros/noetic/setup.bash
    source ~/catkin_ws/devel/setup.bash
    ```
    - シムからのTopicなどが受信できない場合は以下を実行(URIはシム側に合わせる)
        ```sh
        unset ROS_HOSTNAME
        export ROS_MASTER_URI=http://172.17.0.1:11311
        export ROS_IP=$(hostname -I | awk '{print $1}')
        ```
- GSEから起動する場合
    - コンテナ実行時に`sample_tests/scripts/cmd.sh`に記述されている内容が起動されます
    - 内容をGSEでStartボタン押したときに起動したいプログラムへのコマンドへ変更してください
    - Startボタンでコンテナ作成、Stopボタンでコンテナ削除しています
         - StopせずにGSE終了させるとコンテナが残るため、次回起動時にStartでエラーでます
    - GPU使用時はｍ起動後にコンテナ内で以下を実行し、GPUが使用できるか確認してください
        ```sh
        nvidia-smi
        ```
        ```sh
        python3 -c "import torch; print(torch.cuda.is_available())"
        ```

## トラブルシューティング

- GSEのStartボタンで起動しない場合、シムのコンテナのGAZEBO側のログを見てください
    - 起動しようとしている名前のdocker imageが存在しない
    - ユーザーコンテナが既に起動している
        - docker rm コンテナIDで消去の必要あり
    - cmd.shが見つからない
    - cmd.shにあるコマンドが存在しない

## Overview
Technology Demonstration Platform S/W for Int-ball2.

For details see the [Int-ball2_simulator](https://github.com/jaxa/int-ball2_simulator) Repository.


---

## License
This project is distributed under the Apache 2.0 license. Please see the LICENSE file for details.

This Repository is provided by Japan Aerospace Exploration Agency.

---
