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
sudo -E containerlab deploy -t cisco/ios-xr/routing/basic/clab.yml
```

終了する場合は以下を実行してください。

```bash
sudo -E containerlab destroy -t cisco/ios-xr/routing/basic/clab.yml
```

## 画像設定（重要）

- 通常は `*_IMAGE` の非バージョン変数を使います。
- 特定バージョンを固定したい場合は、`.env` にバージョン付き変数を追加し、対象の `clab.yml` 側で参照名を切り替えてください。
