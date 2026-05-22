#!/usr/bin/env bash
# 下载离线会议纪要所需的模型文件
# 模型文件较大，不提交到 Git，运行此脚本后本地可用

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== 下载 VAD 模型 (Silero VAD v4.0) ==="
if [ -f silero_vad.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o silero_vad.onnx \
        'https://cdn.jsdelivr.net/gh/snakers4/silero-vad@v4.0/files/silero_vad.onnx'
    echo "  下载完成: $(du -h silero_vad.onnx | cut -f1)"
fi

echo ""
echo "=== 下载 ASR 模型 (SenseVoiceSmall 量化版) ==="
if [ -f model_quant.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o model_quant.onnx \
        'https://modelscope.cn/models/iic/SenseVoiceSmall-onnx/resolve/master/model_quant.onnx'
    echo "  下载完成: $(du -h model_quant.onnx | cut -f1)"
fi

echo ""
echo "=== 下载 说话人分离模型 (CAM++ 嵌入模型) ==="
if [ -f campplus_cn.onnx ]; then
    echo "  已存在，跳过"
else
    curl -L -o campplus_cn.onnx \
        'https://modelscope.cn/models/SixStons/speech_campplus_sv_zh-cn_16k-common-onnx/resolve/master/campplus_cn.onnx'
    echo "  下载完成: $(du -h campplus_cn.onnx | cut -f1)"
fi

echo ""
echo "=== 模型文件列表 ==="
ls -lh silero_vad.onnx model_quant.onnx campplus_cn.onnx 2>/dev/null

echo ""
echo "完成。可用 http://localhost:8080 启动服务测试。"
