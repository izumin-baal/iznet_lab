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

## kind 一覧

`*.clab.yml` で利用する kind は以下の通りです。

```
cisco_xrd
cisco_xrv9k
cisco_csr1000v
cisco_n9kv
cisco_iol
juniper_crpd
juniper_vmx
juniper_vsrx
juniper_vjunosrouter
juniper_vjunosswitch
juniper_cjunosevolved
arista_ceos
sonic-vs
paloalto_panos
bridge
linux
```

## コンフィグ取得スクリプト

`scripts/get-clab-configs.py` は `*.clab.yml` に記載された機器へ SSH してコンフィグを取得し、
同じ階層の `save/save-YYYYMMDDHHMMSS/<ホスト名>/host-conf.txt` に保存します。

### 使い方

`*.clab.yml` があるディレクトリで実行します。

```bash
scripts/get-clab-configs.py
```

`*.clab.yml` が複数ある場合は `--topo` を指定します。

```bash
scripts/get-clab-configs.py --topo example.clab.yml
```

ホスト名と接続先が一致しない場合は `--host-map` で上書きできます。

```bash
cat > host-map.yml <<'YAML'
RT-01: 10.0.0.2
CONET: rt-conet.lab.local
YAML

scripts/get-clab-configs.py --host-map host-map.yml
```

### PATH について

頻繁に使う場合は、リポジトリの `scripts` を PATH に追加すると便利です。

```bash
export PATH=\"$PATH:$(pwd)/scripts\"
```

その場合は以下のように実行できます。

```bash
get-clab-configs.py
```

## インターフェース Description 命名規則

ネットワーク構成管理のため、全ルーターのインターフェース Description を統一します。  
運用管理の効率化とトラブルシューティング時の視認性向上を目的とします。

### 1. 基本フォーマット

以下の 3 要素を `###` で囲んで記載します。各項目の間は半角スペース 1 つです。

```
### [Category]: [Remote_Hostname] [Remote_Port] ###
```

### 2. カテゴリー定義（Category）

| Category | 意味・用途 |
| --- | --- |
| internet_transit | ISP/トランジット上位回線 |
| internet_ixp | IXP 参加回線 |
| internet_pni | 事業者間の相対接続 (PNI) |
| uplink | 上位階層への収容回線（コア/上位 RT） |
| downlink | 下位階層への収容回線（配下 RT/スイッチ） |
| interlink | ペア機器の内部リンク |
| p2p | 拠点間または拠点内の P2P 専用線 |

### 3. 記載例

```
description ### internet_transit: AS64512_RT01 Gi0/0/0/1 ###
description ### internet_ixp: JPIX Gi0/0/0/2 ###
description ### uplink: CORE-RT01 Gi0/0/0/0 ###
description ### interlink: Osaka-Branch-RT01 Gi0/0/1/0 ###
```

### 4. 運用上の注意点

- 視認性の維持: `show interface description` 実行時に情報が欠落しないよう、ホスト名は可能な限り公式の短縮名称を使用してください。
- 記号の統一: カテゴリー後の区切りは必ず `:`（コロン）を使用してください。
- 変更時の更新: 物理ポートの差し替えや対向機器のホスト名変更が発生した場合は、速やかに Description も更新してください。
