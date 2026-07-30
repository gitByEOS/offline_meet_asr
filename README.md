# 离线会议纪要

纯浏览器本地会议转写：音频不会上传服务器。

## 技术栈

- **Silero VAD v6.2.1**：16 kHz 流式语音活动检测
- **SenseVoiceSmall**：中、英、日、韩、粤语转写
- **CAM++**：说话人嵌入与本地聚类
- **ONNX Runtime Web 1.18.0**：随应用本地发布的浏览器推理运行时

## 快速开始

```bash
# 首次联网准备模型；总量约 260 MB
./download_models.sh

# 仅绑定本机回环地址，并提供 COOP/COEP 响应头
./serve.sh
```

在浏览器打开 <http://localhost:11900>，等待三项模型均加载完成后点击麦克风。

## 离线边界

模型、ORT JavaScript 和 WASM 都从本地静态路径加载。首次执行下载脚本需要网络；之后可断网运行本地服务。`download_models.sh` 会固定并校验 Silero v6.2.1 的 SHA-256。

## 已实现的可靠性措施

- Silero v6.2.1：64 样本上下文、`[2,1,128]` LSTM 状态、固定 512 样本帧
- VAD 输入按会话串行处理，延迟推理结果不会污染下一会话
- 停止录音时会关闭采集、补齐尾帧、排空 VAD，再结束最后一个段
- 采用起段/续段双阈值、前滚、后滚与较长 hangover，减少短句漏检和句中断段
- 流式重采样跨回调保留相位，避免 44.1 kHz 输入长期累计漂移

当前转写链已通过真实预录 WAV → VAD → ASR → CAM++ → Markdown 下载 E2E，但 SenseVoice 的手写 FBank/解码准确率仍需单独提高；不能将“链路可运行”误报为“文字准确率已验收”。

## 浏览器 E2E

```bash
./serve.sh
python3 /Users/bole/.claude/skills/hand-of-browser/scripts/browser_hand.py \
  --html 'http://localhost:11900/?e2e=1' \
  --file e2e/actions-export.json
```

详见 [e2e/README.md](e2e/README.md)。

## 模型来源与许可

- Silero VAD：<https://github.com/snakers4/silero-vad>
- SenseVoice：<https://github.com/FunAudioLLM/SenseVoice>
- CAM++：<https://github.com/modelscope/3D-Speaker>
- ONNX Runtime：<https://onnxruntime.ai/>

项目代码采用 [MIT](LICENSE) 许可；模型须分别遵守其上游许可。
