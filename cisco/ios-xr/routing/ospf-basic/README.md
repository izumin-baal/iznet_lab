## 概要

`iosxr-ospf-basic.clab.yml` は XRd Control Plane（`xrd-control-plane`）7台 +
Linux ホスト2台の構成です。

## 推奨スペック（目安）

- CPU: 6コア以上
- RAM: 20GB 以上（XRd Control Plane 7台分を見込む）
- Swap: 4GB 以上

## 起動時の注意（bridge）

`bridge01` はホスト側で事前に作成が必要です。

```bash
./scripts/create-bridge.sh bridge01
```
