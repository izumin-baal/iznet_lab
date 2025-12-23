# iznet_lab

## 使い方

1) `.env.example` を `.env` にコピーして、レジストリを自分の環境に合わせて置き換えます。`.env` は `git` から除外されています。  
2) `.env` は自動読み込み前提にせず、明示的に読み込んでから実行します。

```bash
set -a
. .env
set +a
```

3) 目的のラボを起動します。`sudo` を使うのが基本なので、`sudo -E` で環境変数を引き継ぎます。

```bash
sudo -E containerlab deploy -t cisco/ios-xr/routing/basic/iosxr-basic.clab.yml
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
sudo -E containerlab destroy -t cisco/ios-xr/routing/basic/iosxr-basic.clab.yml
```
