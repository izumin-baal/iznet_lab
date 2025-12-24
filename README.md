# iznet_lab

## 使い方

1) `.env.example` を `.env` にコピーして、レジストリを自分の環境に合わせて置き換えます。`.env` は `git` から除外されています。  
2) `.env` は自動読み込み前提にせず、明示的に読み込んでから実行します。

```bash
source scripts/clab-env-source
```

3) 目的のラボのディレクトリに移動して起動します。`clab-*` がそのディレクトリ配下に作られるため、各ディレクトリで実行する運用にします。`sudo` を使うのが基本なので、`sudo -E` で環境変数を引き継ぎます。

```bash
cd cisco/ios-xr/routing/ospf-basic
sudo -E containerlab deploy
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

`clab-bridge-create` と `clab-bridge-delete` はブリッジ名を引数で受け取る汎用スクリプトです。  
任意のラボで同じように使えます。`*.clab.yml` があるディレクトリでは自動検出にも対応します。

```bash
# 作成
clab-bridge-create bridge01

# 削除
clab-bridge-delete bridge01
```

`*.clab.yml` があるディレクトリでは引数なしで `kind: bridge` を自動抽出します。

```bash
# clab.yml から bridge を抽出して作成
clab-bridge-create

# clab.yml から bridge を抽出して削除
clab-bridge-delete
```

終了する場合は以下を実行してください。

```bash
cd cisco/ios-xr/routing/ospf-basic
sudo -E containerlab destroy
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

`clab-fetch-configs` は `*.clab.yml` に記載された機器へ SSH してコンフィグを取得し、
同じ階層の `save/save-YYYYMMDDHHMMSS/<ホスト名>-conf.txt` に保存します。

### 使い方

`*.clab.yml` があるディレクトリで実行します。

```bash
clab-fetch-configs
```

`*.clab.yml` が複数ある場合は `--topo` を指定します。

```bash
clab-fetch-configs --topo example.clab.yml
```

## Startup-config の生成

`clab-generate-startup-configs` は `save/save-YYYYMMDDHHMMSS/` にある保存済みコンフィグから、
`startup-config` で参照するファイルを生成します。`startup-config` が未設定でも
`startup-configs/<node>.conf` を生成して反映します。
`kind: linux` と `kind: bridge` は自動的にスキップします。
既存の `startup-config` と保存済みコンフィグが一致しない場合は差分を表示します。

### 使い方

`*.clab.yml` があるディレクトリで実行します。

```bash
clab-generate-startup-configs
```

保存日時を指定する場合は `--snapshot` を使います。`save-` の有無どちらでも受け付けます。

```bash
clab-generate-startup-configs --snapshot 20251224231625
clab-generate-startup-configs --snapshot save-20251224231625
```

`startup-config` を `clab.yml` に追記したい場合は `--write-topo` を使います。

```bash
clab-generate-startup-configs --write-topo
```

確認なしで追記したい場合は `--write-topo-yes` を使います。

```bash
clab-generate-startup-configs --write-topo-yes
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
