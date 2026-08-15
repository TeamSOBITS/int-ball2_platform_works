# dock: 実行中の Docker コンテナへ手早くアタッチするためのシェル関数．
# 本リポジトリの管理対象外（個人環境の設定）．~/.bashrc に追記して使用してください．
#
# - 引数なしで実行すると，実行中のコンテナ一覧から選択（1つだけなら自動選択）．
# - アタッチ先コンテナの既定ユーザーが非root ならそのまま非rootでシェルに入り，
#   root （または判定不能）な場合のみ root でシェルに入る．
function dock() {
    local target_container=$1

    # 引数がない場合は実行中のコンテナから選択
    if [ -z "$target_container" ]; then
        mapfile -t running_containers < <(docker ps --format "{{.Names}}")

        if [ ${#running_containers[@]} -eq 0 ]; then
            echo "No docker container is running."
            return
        elif [ ${#running_containers[@]} -eq 1 ]; then
            target_container=${running_containers[0]}
        else
            echo "Select a container to attach:"
            select choice in "${running_containers[@]}" "Cancel(Stay on Host)"; do
                if [ "$choice" == "Cancel(Stay on Host)" ]; then return; fi
                if [[ -n $choice ]]; then
                    target_container=$choice
                    break
                fi
            done
        fi
    fi

    if [ -n "$target_container" ]; then
        echo "Attaching to $target_container..."

        # 💡 コンテナ名の決め打ちではなく、そのコンテナの既定ユーザー (compose の
        #    user: や Dockerfile の USER) が非rootとして解決されるかどうかで判定する。
        #    こうしておけば、今後どのプロジェクトが非root化されても個別の追記が不要。
        local default_user
        default_user=$(docker exec "$target_container" whoami 2>/dev/null)
        if [ -n "$default_user" ] && [ "$default_user" != "root" ]; then
            # 既定ユーザーが非rootのコンテナはそのまま (デフォルトユーザー) で入る
            docker exec -it "$target_container" /bin/bash
        else
            # 既定が root のコンテナ (または判定できない場合) は root で強制ログイン
            docker exec -it -u root "$target_container" /bin/bash
        fi
    fi
}

# ターミナル起動時、実行中のコンテナがあれば自動で dock を呼び出す（任意）．
# 不要な場合はこのブロックごと削除してください．
if [ ! -f /.dockerenv ]; then
    if [ $(docker ps -q | wc -l) -gt 0 ]; then
        dock
    fi
fi
