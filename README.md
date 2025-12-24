# iznet_lab

## 使い方

1) `.env.example` を `.env` にコピーして、レジストリを自分の環境に合わせて置き換えます。`.env` は `git` から除外されています。  
2) `.env` は自動読み込み前提にせず、明示的に読み込んでから実行します。

```bash
source scripts/run-with-env.sh
```

3) 目的のラボのディレクトリに移動して起動します。`clab-*` がそのディレクトリ配下に作られるため、各ディレクトリで実行する運用にします。`sudo` を使うのが基本なので、`sudo -E` で環境変数を引き継ぎます。

```bash
cd cisco/ios-xr/routing/basic
sudo -E containerlab deploy -t iosxr-basic.clab.yml
```

## 起動時の注意

- XRd は inotify 上限不足で起動失敗することがあります。必要に応じて上限を引き上げてください。
  - 推奨値: `fs.inotify.max_user_instances=1048576`
  - 推奨値: `fs.inotify.max_user_watches=1048576`
- 永続化する場合は `/etc/sysctl.d/99-inotify.conf` に設定し、`sysctl -p` で反映します。
- 再起動後に `clab-*` の残骸やリンクが残ると、`file exists` や `Link not found` で失敗することがあります。
- `clab-*` ディレクトリが残っていると `first-boot.cfg` が再生成されません。
- メモリが厳しい場合は swap を増やすか `vm.swappiness` を上げると改善する場合があります。

## AWS ECR への sudo ログイン（オプション）

環境ごとに値が異なるため、`<...>` は自身の値に置き換えてください。

```bash
aws ecr get-login-password --region <region> | sudo docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

## Bridge スクリプト（ホスト側）

`scripts/create-bridge.sh` と `scripts/delete-bridge.sh` はブリッジ名を引数で受け取る汎用スクリプトです。  
任意のラボで同じように使えます。

```bash
# 作成
./scripts/create-bridge.sh bridge01

# 削除
./scripts/delete-bridge.sh bridge01
```

`-f` で `clab.yml` を指定すると、定義内の `kind: bridge` を自動抽出してまとめて処理します。

```bash
# clab.yml から bridge を抽出して作成
./scripts/create-bridge.sh -f cisco/ios-xr/routing/basic/iosxr-basic.clab.yml

# clab.yml から bridge を抽出して削除
./scripts/delete-bridge.sh -f cisco/ios-xr/routing/basic/iosxr-basic.clab.yml
```

終了する場合は以下を実行してください。

```bash
cd cisco/ios-xr/routing/basic
sudo -E containerlab destroy -t iosxr-basic.clab.yml
```
