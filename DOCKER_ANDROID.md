# Docker を使用した Android 向け WebRTC ビルド

このドキュメントでは、Docker を使用して Android 向けの WebRTC をビルドする方法を説明します。

## 前提条件

- Docker と Docker Compose がインストールされていること
- 最低 16GB のメモリ（推奨: 32GB 以上）
- 100GB 以上の空きディスク容量

## クイックスタート

### 1. 通常のビルド

最も簡単な方法は、提供されているヘルパースクリプトを使用することです：

```bash
./scripts/docker_build_android.sh
```

これにより、以下の処理が自動的に実行されます：
1. Docker イメージのビルド
2. WebRTC ソースコードの取得
3. Android 向けビルド（armeabi-v7a と arm64-v8a）
4. パッケージの作成

ビルドが完了すると、`_package/android/webrtc.android.tar.gz` に成果物が生成されます。

### 2. Docker Compose を直接使用

```bash
# イメージのビルドと実行
docker-compose up --build android-builder

# または、バックグラウンドで実行
docker-compose up -d --build android-builder
```

## 詳細な使用方法

### ヘルパースクリプトのオプション

```bash
# ヘルプを表示
./scripts/docker_build_android.sh --help

# デバッグビルド
./scripts/docker_build_android.sh --debug

# ビルドのみ実行（パッケージ作成をスキップ）
./scripts/docker_build_android.sh --build-only

# パッケージ作成のみ実行
./scripts/docker_build_android.sh --package-only

# インタラクティブモードでコンテナに入る
./scripts/docker_build_android.sh --interactive

# クリーンビルド（キャッシュをクリア）
./scripts/docker_build_android.sh --clean

# Docker イメージを再ビルド
./scripts/docker_build_android.sh --no-cache
```

### インタラクティブモードでの作業

コンテナ内で直接作業したい場合：

```bash
# インタラクティブモードでコンテナを起動
./scripts/docker_build_android.sh --interactive

# コンテナ内でのコマンド例
python3 run.py build android --debug
python3 run.py package android
```

### カスタムビルド

`docker-compose.yml` の command セクションを編集することで、ビルドオプションをカスタマイズできます：

```yaml
command: >
  bash -c "
    python3 run.py build android --extra-gn-args='is_component_build=true' &&
    python3 run.py package android
  "
```

## ディレクトリ構造

Docker 環境では以下のディレクトリ構造を使用します：

```
/workspace/                 # コンテナ内の作業ディレクトリ
├── run.py                  # ビルドスクリプト（読み取り専用）
├── patches/                # パッチファイル（読み取り専用）
├── scripts/                # スクリプト（読み取り専用）
├── _source/                # WebRTC ソース（コンテナ内のみ）
├── _build/                 # ビルド中間ファイル（コンテナ内のみ）
└── _package/               # 成果物（ホストと共有）
```

## トラブルシューティング

### メモリ不足エラー

ビルド中にメモリ不足エラーが発生する場合は、Docker Desktop の設定でメモリ制限を増やしてください：

1. Docker Desktop の設定を開く
2. Resources → Advanced でメモリを 16GB 以上に設定
3. Docker を再起動

### ディスク容量不足

WebRTC のビルドには大量のディスク容量が必要です。不要な Docker イメージやコンテナを削除してください：

```bash
# 未使用のイメージ、コンテナ、ボリュームを削除
docker system prune -a

# ビルドキャッシュも削除
docker builder prune
```

### ビルドの再開

ビルドが中断された場合、以下のコマンドで再開できます：

```bash
# 既存の状態から続行
./scripts/docker_build_android.sh

# クリーンビルド（最初から）
./scripts/docker_build_android.sh --clean
```

## 注意事項

- 初回ビルドは WebRTC ソースコードのダウンロードを含むため、数時間かかる場合があります
- `_source` と `_build` ディレクトリはコンテナ内にのみ存在し、ホストには同期されません
- 最終的な成果物のみが `_package` ディレクトリを通じてホストと共有されます

## 関連ドキュメント

- [WebRTC-Build README](README.md)
- [WebRTC 公式ドキュメント](https://webrtc.org/)