#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 色付き出力用の関数
print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# ヘルプメッセージ
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Android向けWebRTCビルドをDockerコンテナ内で実行します。

OPTIONS:
    -h, --help          このヘルプメッセージを表示
    -b, --build-only    ビルドのみ実行（パッケージ作成をスキップ）
    -p, --package-only  パッケージ作成のみ実行（ビルド済みの成果物が必要）
    -d, --debug         デバッグビルドを実行
    -i, --interactive   インタラクティブモードでコンテナを起動
    -c, --clean         ビルド前にキャッシュをクリア
    --no-cache          Dockerイメージを再ビルド（キャッシュを使用しない）

EXAMPLES:
    # 通常のビルドとパッケージ作成
    $0

    # デバッグビルド
    $0 --debug

    # インタラクティブモードでコンテナに入る
    $0 --interactive

    # クリーンビルド
    $0 --clean

EOF
}

# デフォルト値
BUILD_ONLY=false
PACKAGE_ONLY=false
DEBUG_BUILD=false
INTERACTIVE=false
CLEAN_BUILD=false
NO_CACHE=""

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -p|--package-only)
            PACKAGE_ONLY=true
            shift
            ;;
        -d|--debug)
            DEBUG_BUILD=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        *)
            print_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# プロジェクトルートに移動
cd "$PROJECT_ROOT"

# _packageディレクトリの作成
if [ ! -d "_package" ]; then
    print_info "_packageディレクトリを作成しています..."
    mkdir -p _package
fi

# クリーンビルドの場合、既存の成果物を削除
if [ "$CLEAN_BUILD" = true ]; then
    print_info "既存のビルド成果物をクリーンアップしています..."
    rm -rf _package/android
fi

# Dockerイメージのビルド
print_info "Dockerイメージをビルドしています..."
docker-compose build $NO_CACHE android-builder

# コマンドの構築
if [ "$INTERACTIVE" = true ]; then
    # インタラクティブモード
    print_info "インタラクティブモードでコンテナを起動しています..."
    docker-compose run --rm android-builder /bin/bash
elif [ "$BUILD_ONLY" = true ]; then
    # ビルドのみ
    CMD="python3 run.py build android"
    if [ "$DEBUG_BUILD" = true ]; then
        CMD="$CMD --debug"
    fi
    print_info "ビルドを実行しています: $CMD"
    docker-compose run --rm android-builder bash -c "$CMD"
elif [ "$PACKAGE_ONLY" = true ]; then
    # パッケージ作成のみ
    CMD="python3 run.py package android"
    print_info "パッケージ作成を実行しています: $CMD"
    docker-compose run --rm android-builder bash -c "$CMD"
else
    # 通常のビルドとパッケージ作成
    CMD="python3 run.py build android && python3 run.py package android"
    if [ "$DEBUG_BUILD" = true ]; then
        CMD="python3 run.py build android --debug && python3 run.py package android"
    fi
    print_info "ビルドとパッケージ作成を実行しています..."
    docker-compose run --rm android-builder bash -c "$CMD"
fi

# 結果の確認
if [ -f "_package/android/webrtc.android.tar.gz" ]; then
    print_success "ビルドが完了しました！"
    print_info "成果物: _package/android/webrtc.android.tar.gz"
    ls -lh _package/android/webrtc.android.tar.gz
else
    if [ "$INTERACTIVE" != true ] && [ "$BUILD_ONLY" != true ]; then
        print_error "ビルド成果物が見つかりません"
        exit 1
    fi
fi