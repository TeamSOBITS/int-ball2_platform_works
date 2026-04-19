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
    - おそらくroot権限で実行しています
    - Startボタンでコンテナ作成、Stopボタンでコンテナ削除しています
         - StopせずにGSE終了させるとコンテナが残るため、次回起動時にStartでエラーでます

## トラブルシューティング

- GSEのStartボタンで起動しない場合、シムのコンテナのGAZEBO側のログを見てください
    - cmd.shが見つからない
    - cmd.shにあるコマンドが存在しないコマンド
    - cmd.shで実行されたプログラムでエラーが発生した
    - ユーザーコンテナが既に起動している
        - docker rm コンテナIDで消去の必要あり
    - 起動時にホスト側の絶対パスが渡っていない or 存在しないパス
        - shared_data_sim内にplatform_worksを配置する必要あり
	    - バインドのコマンド
            ```sh
            sudo mount --bind /home/rg-msi-03/int-ball2_simulator/int-ball2_simulator_docker/shared_data_sim /home/space-ros/int-ball2_simulator/int-ball2_simulator_docker/shared_data_sim
            ```

## 現段階でGSEからの起動確認できているプログラム
- iss_static_map_server.launch
- location_broadcaster.py

## 要確認
- depth_anything_v2.launch
    - cudaがfalseになりエラー落ちの可能性高
    - compose.yml経由では起動確認済み
- yolo.launch
    - cudaがfalseになりエラー落ちの可能性高
- gnc.launch
    - マップ配信、Tf配信、深度推定
- gnc_manager.py
    - Target TFをmain内に書き込み、地点配信や地図配信も
- run_competition.py
    - メインステート, 各launchは他ターミナルで起動の必要あり
- main.launch
    - すべて

## Overview
Technology Demonstration Platform S/W for Int-ball2.

For details see the [Int-ball2_simulator](https://github.com/jaxa/int-ball2_simulator) Repository.


---

## License
This project is distributed under the Apache 2.0 license. Please see the LICENSE file for details.

This Repository is provided by Japan Aerospace Exploration Agency.

---
