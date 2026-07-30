#!/usr/bin/env bash
# 下载离线会议纪要所需的模型文件
# 模型文件较大，不提交到 Git，运行此脚本后本地可用

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p models

SILERO_VAD_VERSION="v6.2.1"
SILERO_VAD_SHA256="1a153a22f4509e292a94e67d6f9b85e8deb25b4988682b7e174c65279d8788e3"
SILERO_VAD_URL="https://github.com/snakers4/silero-vad/raw/${SILERO_VAD_VERSION}/src/silero_vad/data/silero_vad.onnx"

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    [ "$actual" = "$expected" ]
}

download_atomic() {
    local url="$1"
    local target="$2"
    local expected_sha="$3"
    local temp="${target}.tmp.$$"

    trap 'rm -f "$temp"' RETURN
    curl --fail --location --retry 3 --retry-all-errors --output "$temp" "$url"
    if ! verify_sha256 "$temp" "$expected_sha"; then
        rm -f "$temp"
        echo "  SHA-256 校验失败: $target" >&2
        return 1
    fi
    mv "$temp" "$target"
    trap - RETURN
}

echo "=== 下载 VAD 模型 ==="
if [ -f models/silero_vad.onnx ] && verify_sha256 models/silero_vad.onnx "$SILERO_VAD_SHA256"; then
    echo "  Silero ${SILERO_VAD_VERSION} 已存在且校验通过"
else
    rm -f models/silero_vad.onnx
    download_atomic "$SILERO_VAD_URL" models/silero_vad.onnx "$SILERO_VAD_SHA256"
    echo "  Silero ${SILERO_VAD_VERSION} 下载并校验完成: $(du -h models/silero_vad.onnx | cut -f1)"
fi

echo ""
echo "=== 下载 ASR 模型 ==="
if [ -f models/model_quant.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o models/model_quant.onnx \
        'https://modelscope.cn/models/iic/SenseVoiceSmall-onnx/resolve/master/model_quant.onnx'
    echo "  下载完成: $(du -h models/model_quant.onnx | cut -f1)"
fi

echo ""
echo "=== 下载 CMVN 参数 ==="
if [ -f models/am.mvn ]; then
    echo "  已存在，跳过"
else
    curl -L -o models/am.mvn \
        'https://modelscope.cn/models/iic/SenseVoiceSmall-onnx/resolve/master/am.mvn'
    echo "  下载完成: $(du -h models/am.mvn | cut -f1)"
fi

echo ""
echo "=== 下载词汇映射表 ==="
if [ -f models/tokens.json ]; then
    echo "  已存在，跳过"
else
    curl -L -o models/tokens.json \
        'https://modelscope.cn/models/iic/SenseVoiceSmall-onnx/resolve/master/tokens.json'
    echo "  下载完成: $(du -h models/tokens.json | cut -f1)"
fi

echo ""
echo "=== 下载说话人识别模型 ==="
if [ -f models/campplus_cn.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o models/campplus_cn.onnx \
        'https://modelscope.cn/models/SixStons/speech_campplus_sv_zh-cn_16k-common-onnx/resolve/master/campplus_cn.onnx'
    echo "  下载完成: $(du -h models/campplus_cn.onnx | cut -f1)"
fi

echo ""
echo "=== 模型文件列表 ==="
ls -lh models/

echo ""
echo "完成。运行 ./serve.sh 启动服务。"