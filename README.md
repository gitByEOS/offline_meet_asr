# 离线会议纪要

纯前端离线语音识别，无需上传数据到服务器。

## 技术栈

- **Silero VAD** — 语音活动检测，识别有人说话的片段
- **SenseVoiceSmall** — 多语言语音转文字（中文、英文、日语、韩语、粤语）
- **ONNX Runtime Web** — 浏览器端模型推理

## 快速开始

```bash
# 1. 下载模型（首次运行，约 230MB）
./download_models.sh

# 2. 启动服务
./serve.sh

# 3. 浏览器打开 http://localhost:11900
```

## 使用方式

1. 点击「加载模型」下载并初始化 VAD + ASR 模型
2. 点击「开始录音」，说话后自动转写
3. 点击「导出纪要」保存为 Markdown，或「复制文本」

## 文件说明

| 文件 | 说明 |
|------|------|
| `index.html` | 主页面，纯前端实现 |
| `download_models.sh` | 模型下载脚本 |
| `serve.sh` | 启动 HTTP 服务 |
| `silero_vad.onnx` | VAD 模型（1.7MB，不提交） |
| `model_quant.onnx` | ASR 模型（230MB，不提交） |

## 模型来源

- Silero VAD: https://github.com/snakers4/silero-vad
- SenseVoiceSmall: https://github.com/FunAudioLLM/SenseVoice
