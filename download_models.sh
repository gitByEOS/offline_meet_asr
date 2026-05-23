#!/usr/bin/env bash
# 下载离线会议纪要所需的模型文件
# 模型文件较大，不提交到 Git，运行此脚本后本地可用

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p models

echo "=== 下载 VAD 模型 ==="
if [ -f models/silero_vad.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o models/silero_vad.onnx \
        'https://cdn.jsdelivr.net/gh/snakers4/silero-vad@v4.0/files/silero_vad.onnx'
    echo "  下载完成: $(du -h models/silero_vad.onnx | cut -f1)"
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