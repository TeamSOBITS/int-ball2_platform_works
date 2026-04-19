# Platform Works

## インストール方法

1. `shared_data_sim`配下に本リポジトリをcloneし、以下の階層に`cd`で移動

```sh
int-ball2_platform_works/platform_docker/sample_tests
```

2. 各サブモジュールをcloneする(入ってなければ)
    - YOLO, Depth Anything V2, intball2_commom

3. Depth Anything V2のモデルをダウンロードし適切な場所に配置


その後、以下のコマンドでイメージをビルド
```bash
docker build . -t ib2_user:0.1
```

- GSEからではなく、ローカルのターミナルから起動する場合
    ```sh
    docker compose down
    PWD=$(pwd) docker compose up -d
    ```
- GSEから起動する場合
    - コンテナ実行時に`sample_tests/scripts/cmd.sh`に記述されている内容が起動されます
    - 内容をGSEでStartボタン押したときに起動したいプログラムへのコマンドへ変更してください

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
## Overview
Technology Demonstration Platform S/W for Int-ball2.

For details see the [Int-ball2_simulator](https://github.com/jaxa/int-ball2_simulator) Repository.


---

## License
This project is distributed under the Apache 2.0 license. Please see the LICENSE file for details.

This Repository is provided by Japan Aerospace Exploration Agency.

---
