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

## Scripts

| Script | 概要 | 実行場所 |
| --- | --- | --- |
| `scripts/clab-env-source` | `.env` を読み込む | どこでも |
| `scripts/clab-bridge-create` | Bridge 作成 | `*.clab.yml` があるディレクトリ |
| `scripts/clab-bridge-delete` | Bridge 削除 | `*.clab.yml` があるディレクトリ |
| `scripts/clab-fetch-configs` | SSH でコンフィグ取得 | `*.clab.yml` があるディレクトリ |
| `scripts/clab-generate-startup-configs` | 保存済みコンフィグから startup-config 生成 | `*.clab.yml` があるディレクトリ |
| `scripts/clab-test-run` | `test.yml` を再帰的に実行 | `*.clab.yml` があるディレクトリ |

### clab-env-source

`.env` を明示的に読み込みます。

```bash
source scripts/clab-env-source
```

### clab-bridge-create / clab-bridge-delete

`*.clab.yml` があるディレクトリで引数なし実行すると `kind: bridge` を自動抽出します。

```bash
clab-bridge-create bridge01
clab-bridge-delete bridge01
```

### clab-fetch-configs

`*.clab.yml` に記載された機器へ SSH してコンフィグを取得し、
`save/save-YYYYMMDDHHMMSS/<ホスト名>-conf.txt` に保存します。

```bash
clab-fetch-configs
clab-fetch-configs --topo example.clab.yml
```

### clab-generate-startup-configs

`save/save-YYYYMMDDHHMMSS/` の保存済みコンフィグから `startup-config` を生成します。
`kind: linux` と `kind: bridge` は自動的にスキップします。

```bash
clab-generate-startup-configs
clab-generate-startup-configs --snapshot 20251224231625
clab-generate-startup-configs --write-topo
```

### clab-test-run

任意の階層に `test.yml` / `test.yaml` / `*.test.yml` を配置し、再帰的に実行できます。

#### test.yml サンプル

```yaml
tests:
  - title: "OSPF Neighbor"
    detail: "router01 の OSPF 隣接が FULL であること"
    hosts: ["router01"]
    command: "show ospf neighbor"
    expect:
      - type: contains
        value: "FULL"
      - type: regex
        value: "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+"

  - title: "Ping host01 -> host02"
    detail: "host01 から host02 へ ping が通ること"
    hosts: ["host01"]
    command: "ping -c 3 192.168.2.1"
    expect:
      - type: contains
        value: "0% packet loss"
    when: previous_success
    timeout: 5
    retries: 2
```

#### 実行

```bash
scripts/clab-test-run
scripts/clab-test-run --root cisco/ios-xr
scripts/clab-test-run --file cisco/ios-xr/routing/ospf-basic/test.yml
```

#### 期待値 (expect)

| type | 意味 |
| --- | --- |
| `contains` | 標準出力に文字列が含まれる |
| `not_contains` | 標準出力に文字列が含まれない |
| `regex` | 標準出力が正規表現に一致する |
| `not_regex` | 標準出力が正規表現に一致しない |
| `stderr_contains` | 標準エラーに文字列が含まれる |
| `exit_code` | 終了コードが一致する |

`expect` が未指定の場合は `exit_code=0` を期待します。
`expect` は複数指定した場合、すべて満たす必要があります。

否定条件の例:

```yaml
expect:
  - type: not_contains
    value: "DOWN"
```

#### 前提条件 (when)

| 指定 | 意味 |
| --- | --- |
| `previous_success` | 直前のテストが PASS の場合のみ実行 |
| `previous_fail` | 直前のテストが FAIL の場合のみ実行 |
| `always` | 常に実行 |
| `never` | 常にスキップ |
| `<test title>` | 指定したタイトルのテストが PASS の場合のみ実行 |

`hosts` を複数指定した場合は、各ホストで実行され、すべて PASS の場合のみそのテストが PASS になります。

例:

```yaml
when: previous_success
```

```yaml
when: "OSPF Neighbor"
```

#### ログ出力

最も近い `*.clab.yml` があるディレクトリに `test-logs/` を作成し、
`test-<ファイル名>-YYYYMMDDHHMMSS.log` を出力します。

#### オプション

`--root` / `--file` / `--timeout` / `--retries` / `--detail`  

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
