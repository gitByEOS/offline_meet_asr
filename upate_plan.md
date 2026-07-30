# 离线会议纪要升级方案

## 目标

保留“浏览器完全离线”作为默认且完整可用的产品形态
本机后端仅作为可选增强能力，不能成为浏览器模式的运行前提

## 现状

当前实现是单页浏览器应用，使用 Silero VAD、SenseVoiceSmall ONNX、CAM++ ONNX 与 ONNX Runtime Web
音频处理、VAD、ASR、说话人聚类和纪要导出均在 `index.html` 内完成

当前主要缺口：

- ONNX Runtime 与 WASM 从 CDN 获取，断网时不满足完全离线
- `audioBuffer`、VAD 队列和识别队列缺少明确上限
- 长时间会议的内存、时延和识别质量没有基准与自动化回归
- CAM++ 为在线质心聚类，缺少置信度、回溯修正和可评测的说话人分段契约
- 代码集中在单个 HTML 文件，测试与可维护性不足

## 方案总览

| 维度 | 方案 A：仅浏览器 | 方案 B：浏览器 + 本机后端 |
|---|---|---|
| 默认入口 | 静态页面 | 静态页面，按需发现本机服务 |
| 网络要求 | 首次下载模型后全程断网 | 浏览器与 `localhost` 通信，不访问公网 |
| ASR | SenseVoiceSmall ONNX | 浏览器 ASR + 可选 Parakeet、Whisper、Paraformer 等 |
| VAD | 浏览器 Silero ONNX | 浏览器 VAD 或后端 Silero VAD |
| 说话人 | CAM++ 嵌入 + 本地聚类 | 浏览器 CAM++ 或后端可插拔 diarization |
| 延迟 | 受浏览器 CPU/WASM 限制 | 由本机 MLX、MPS、CUDA 或 CPU 后端加速 |
| 隐私 | 音频不离开浏览器进程 | 音频仅在本机 loopback 链路传输 |
| 部署复杂度 | 最低，只需静态服务 | 需要安装并管理 Python 模型服务 |
| 兼容性 | Chrome、Edge、Safari 需逐项验证 | 前端兼容性不变，后端需按平台适配 |
| 推荐定位 | 默认产品路径 | 高精度、长会、专业设备增强路径 |

## 方案 A：仅浏览器模式

### 架构

```text
麦克风
  → AudioWorklet
  → 16 kHz 单声道 PCM
  ├─ VAD Worker（Silero ONNX）
  ├─ ASR Worker（SenseVoiceSmall ONNX）
  └─ Speaker Worker（CAM++ ONNX + 本地聚类）
  → 会议事件存储
  → 页面渲染 / Markdown、JSONL 导出
```

### 必须实施

| 优先级 | 改造 | 现状 | 目标 | 验收 |
|---|---|---|---|---|
| P0 | 本地化运行时 | `index.html` 从 jsDelivr 加载 ORT/WASM | 将 `ort.min.js` 与 WASM 随应用发布 | 断开外网仍能加载模型并录音 |
| P0 | Worker 化 | 音频处理依赖 `ScriptProcessorNode` 与主线程 | 改用 `AudioWorklet`，模型推理放 Worker | UI 帧率与录音同步稳定 |
| P0 | 有界缓存 | `audioBuffer` 与两个队列可无限增长 | 使用环形音频缓冲与有界队列 | 两小时会议内存无持续增长 |
| P0 | 分段边界 | 固定 VAD 阈值与静音帧 | 配置预滚、后滚、最长段、强制切段 | 短句不截断，长句不无限延后 |
| P1 | 说话人事件 | 只渲染 `发言人 N` | 保存标准字段与置信度 | JSONL 可重放会议记录 |
| P1 | 聚类稳定性 | 质心EMA后未重新归一化 | 每次更新后 L2 归一化，并支持合并/重命名 | 同人误拆与异人误合可测 |
| P1 | 指标 | 无可观测性 | 记录处理延迟、队列深度、丢段、模型版本 | 导出诊断报告 |
| P1 | 质量测试 | 无音频基准 | 增加固定音频、文本和说话人标注集 | CER、DER、P95 延迟回归 |
| P2 | 代码组织 | 全部逻辑位于 `index.html` | 拆为 UI、音频、模型、事件、导出模块 | 单元与集成测试独立运行 |

### 浏览器事件契约

浏览器模式内部和导出都使用同一事件格式

```json
{
  "type": "transcript.final",
  "segment_id": "session-01:42",
  "start": 123.45,
  "end": 127.82,
  "text": "下周完成浏览器模式改造",
  "language": "zh",
  "speaker_id": "speaker-2",
  "speaker_confidence": 0.82,
  "asr_confidence": null,
  "source": "browser",
  "model_versions": {
    "vad": "silero-vad@pinned",
    "asr": "sensevoice-small@pinned",
    "speaker": "campplus@pinned"
  }
}
```

说明：当前模型输出未必包含可靠 ASR 置信度，因此 v1 可为 `null`，不能伪造评分

### 浏览器模式目标指标

以下为建议验收门槛，需先在目标设备建立基线后固化

| 指标 | 首期目标 | 说明 |
|---|---:|---|
| 离线启动 | 100% | 已缓存模型与运行时后断网可用 |
| 首次可录音 | ≤ 30 秒 | 不含首次模型下载时间 |
| P95 分段到终稿延迟 | ≤ 5 秒 | 以中等性能目标设备为准 |
| 连续会议时长 | ≥ 2 小时 | 无 OOM、无无界内存增长 |
| 丢弃语音段 | 0 | 正常负载下不得丢段 |
| CER / WER | 建立基线后不回退 | 中文优先 CER，英语优先 WER |
| DER | 先记录基线 | 需人工标注多说话人集 |

## 方案 B：浏览器 + 本机后端增强模式

### 适用条件

- 用户愿意安装本机 Python 服务与模型
- 需要更高精度、更多 ASR 后端或更快的 Apple Silicon、CUDA 推理
- 需要将长会、专业麦克风或企业设备管理纳入标准化部署
- 能接受音频通过 `localhost` 在本机进程间传输

### 架构

```text
浏览器麦克风
  → AudioWorklet
  → 16 kHz / mono / signed Int16 little-endian PCM
  ├─ 浏览器本地链：VAD / ASR / CAM++
  └─ localhost Realtime 链：VAD → STT → diarization 旁路
                                     ├─ partial transcript
                                     ├─ final transcript
                                     └─ speaker diarization event
  → 统一会议事件归并器
  → 页面渲染 / Markdown、JSONL 导出
```

### 后端协作边界

speech 项目可复用 VAD 分段、流式 partial transcript、Realtime WebSocket/WebRTC 和多 STT 后端
其默认 ASR 为 Parakeet TDT 0.6B-v3，并可选择 Whisper、Faster Whisper、MLX Whisper、Paraformer

speech 当前没有说话人分离、分轨或 diarization，需要独立实现可插拔旁路模块

| 组件 | 当前 speech 能力 | 升级后职责 |
|---|---|---|
| PCM 输入 | 支持 16 kHz 单声道 Int16 | 固化为浏览器与后端唯一实时输入格式 |
| VAD | Silero，支持分段与 partial | 服务端增强模式的标准分段器 |
| STT | Parakeet / Whisper / Paraformer 等 | 输出 partial 与 final 转写 |
| Diarization | 暂无 | 旁路异步处理 VAD final 音频 |
| Realtime | 已有 WebSocket/WebRTC | 下发标准化会议事件 |
| 负载控制 | 主链队列当前无界 | 先为 diarization 旁路实施有界队列与指标 |

### 后端 diarization 最小契约

不要把异步说话人结果塞进 `Transcription`
转写和说话人结果必须作为独立、可幂等的事件交付

```json
{
  "type": "speaker.diarization",
  "segment_id": "turn-17:0:2",
  "start": 123.45,
  "end": 127.82,
  "speaker_id": "speaker-2",
  "confidence": 0.82
}
```

规则：

- `start`、`end` 是绝对音频秒，不使用墙钟时间
- `segment_id` 使用 `turn_id:turn_revision:segment_index`
- v1 只追加已最终确认的说话人段，不静默改写历史标签
- 未来修订使用新事件和 `supersedes_segment_id`，不改写旧事件
- diarization 默认关闭，模型加载失败时不能影响 VAD、STT 与最终转写

### 服务端旁路流控

```text
VAD final 音频
  ├─ STT 主链：保持既有实时处理
  └─ diarization_queue(maxsize=N)
       └─ 慢 worker 异步生成 speaker.diarization
```

| 规则 | 设计 |
|---|---|
| 队列满 | `put_nowait` 后丢弃本次旁路任务 |
| 主链影响 | 不反压 VAD、STT 或浏览器采集 |
| 指标 | `submitted`、`completed`、`dropped_full`、`errors`、`queue_depth`、`capacity`、`process_latency_s` |
| 会话隔离 | 每个 Realtime session 单独 worker、队列与指标 |
| 会话结束 | 重置 diarization worker 状态 |

注意：不得直接将所有既有主链队列改为有界队列
主链有界化需要先定义丢弃、阻塞和重试语义，再以压测结果独立推进

### 后端模式目标指标

| 指标 | 首期目标 | 说明 |
|---|---:|---|
| 连接失败降级 | 100% | 自动或手动切回浏览器模式 |
| 实时输入格式 | 100% | 16 kHz、mono、S16LE |
| P95 partial 延迟 | ≤ 1.5 秒 | 目标硬件需独立建基线 |
| P95 final 延迟 | ≤ 4 秒 | 从 VAD final 到最终文字 |
| diarization 丢弃 | 可观测 | 满队列允许丢弃，必须记录 |
| diarization 主链影响 | 0 | 慢 worker 不增加转写延迟 |
| 音频外发 | 0 | 仅允许 `localhost`，默认拒绝远端地址 |

## 推荐路线

优先完成方案 A，再在不改变默认体验的前提下接入方案 B

| 阶段 | 范围 | 产出 | 退出条件 |
|---|---|---|---|
| 0：基线 | 采集样本、固定设备、记录现状 | 基线报告与测试音频 | 可重复测得 CER、DER、延迟、内存 |
| 1：浏览器可靠性 | 本地ORT、AudioWorklet、有界缓存、模型校验 | 断网可运行的浏览器版本 | 2小时稳定录音与质量不回退 |
| 2：浏览器质量 | 说话人事件、稳定聚类、JSONL、诊断导出 | 可重放会议数据 | 核心浏览器矩阵通过 |
| 3：后端契约 | PCM、partial/final、speaker事件、能力发现 | 版本化协议文档 | 浏览器可忽略未知事件 |
| 4：本机增强 | Realtime适配、多STT后端、旁路指标 | 可选本机增强服务 | 服务不可用时无感回退 |
| 5：后端说话人 | 可插拔 provider、旁路队列、评测 | diarization 实现 | 慢模型不阻塞转写 |

## 前后兼容与回滚

| 风险 | 控制方式 | 回滚 |
|---|---|---|
| 后端不可用 | 后端模式显式可选，浏览器链始终存在 | 关闭增强开关 |
| 模型版本漂移 | 保存模型版本、SHA-256、来源与许可 | 回退已验证模型清单 |
| 协议变更 | 事件含 `type` 与版本，未知事件忽略 | 保留旧事件解析器 |
| diarization 变慢 | 旁路有界队列与丢弃指标 | 关闭 provider，保留文字转写 |
| 浏览器性能回退 | 设备矩阵和性能门禁 | 回退 Worker/模型构建产物 |

## 测试与发布门禁

| 类别 | 浏览器模式 | 后端增强模式 |
|---|---|---|
| 单元测试 | 重采样、环形缓冲、VAD状态机、聚类、导出 | 事件序列化、队列满、provider异常、session reset |
| 集成测试 | 本地静态服务、断网、预录音频回放 | WebSocket 16k PCM、partial/final/diarization 乱序 |
| 兼容测试 | Chrome、Edge、Safari 当前支持版本 | macOS MLX/MPS、Linux CUDA/CPU、Windows CPU |
| 长稳测试 | 2小时模拟会议、内存与队列曲线 | 多会话、慢 diarization、服务重启 |
| 质量测试 | CER/WER、DER、分段召回与精度 | 与浏览器模式同集对比 |
| 发布门禁 | 断网可用、无严重控制台错误、指标不回退 | 后端关闭时浏览器模式零回归 |

## 决策

当前选择：以方案 A 为默认交付，方案 B 延后为可选增强

因此当前项目不依赖 speech 项目即可完成离线会议纪要
后续仅在需要更高精度、更多模型或本机硬件加速时接入 speech
