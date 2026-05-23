# 离线会议纪要

纯前端离线语音识别，支持多说话人区分，无需上传数据到服务器。

## 技术栈

- **Silero VAD** — 语音活动检测，精准识别说话片段
- **SenseVoiceSmall** — 多语言语音转文字（中/英/日/韩/粤）
- **CAM++** — 说话人嵌入模型，自动区分不同发言人
- **ONNX Runtime Web** — 浏览器端模型推理

## 快速开始

```bash
# 1. 下载模型（首次运行，约 250MB）
./download_models.sh

# 2. 启动服务
./serve.sh

# 3. 浏览器打开 http://localhost:11900
```

页面打开后自动加载模型，点击麦克风即可开始录音。

## 功能

- ✅ 语音活动检测（VAD）— 只在说话时识别
- ✅ 多语言识别 — 中文、英文、日语、韩语、粤语
- ✅ 说话人区分 — 自动标注「发言人 1」「发言人 2」...
- ✅ 导出纪要 — Markdown 格式，含时间戳
- ✅ 完全离线 — 数据不上传，隐私安全

## 文件说明

| 文件 | 说明 |
|------|------|
| `index.html` | 主页面，纯前端实现 |
| `download_models.sh` | 模型下载脚本 |
| `serve.sh` | 启动 HTTP 服务（端口 11900） |
| `*.onnx` | 模型文件 |

## 模型来源

- Silero VAD: https://github.com/snakers4/silero-vad
- SenseVoiceSmall: https://github.com/FunAudioLLM/SenseVoice
- CAM++: https://github.com/modelscope/3D-Speaker

## 许可

MIT
