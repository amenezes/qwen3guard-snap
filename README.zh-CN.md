# Qwen3Guard 推理 snap

[![qwen3guard](https://snapcraft.io/qwen3guard/badge.svg)](https://snapcraft.io/qwen3guard)

<!-- README-I18N:START -->

[English](./README.md) | [Português (Brasil)](./README.pt-BR.md) | **简体中文**

<!-- README-I18N:END -->

**[Qwen3Guard-Gen](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)** 是
[阿里云（通义千问团队）](https://qwen.ai) 推出的安全护栏模型系列，专为对 token 流进行实时内容审核与安全分类而设计。提供三种尺寸：

* **0.6B**：超轻量级，适合边缘端与设备侧部署
* **4B**：质量与资源占用均衡
* **8B**：面向高要求工作负载的最高精度版本

使用本 snap 可快速搭建一套针对 Qwen3Guard 优化的本地推理环境。

本 snap 包含以下针对硬件优化的推理引擎：

* cpu：针对 x64 与 ARM（armv8、armv9）CPU 优化
* nvidia-gpu：CUDA GPU 加速
* amd-gpu：AMD GPU 的 ROCm 加速

系统会根据可用硬件自动选择最合适的引擎。

#### 安装
```shell
sudo snap install qwen3guard
```

#### 运行
```shell
qwen3guard
```

> [!TIP]
> 部分加速器需要额外安装[驱动程序](https://documentation.ubuntu.com/inference-snaps/how-to/setup/drivers/)才能与本 snap 配合使用。
> `amd-gpu` 引擎使用内核自带的 `amdgpu` 驱动（KFD）；ROCm 用户态库已打包在本
> snap 中，主机无需安装 ROCm。

## 模型变体

提供三种模型尺寸。默认使用 0.6B 变体（Q4_K_M）；可通过
`sudo qwen3guard use-model <variant>` 切换，并重启服务：

| 变体 | 参数量 | 磁盘占用（安装后） | 说明 |
| --- | --- | --- | --- |
| `qwen3guard-0.6b`（默认） | 0.6B | 约 0.7 GB | 超轻量级，推荐用于边缘端/设备侧部署 |
| `qwen3guard-4b` | 4B | 约 2.9 GB | 质量与资源占用均衡 |
| `qwen3guard-8b` | 8B | 约 5.3 GB | 面向高要求工作负载的最高精度版本 |

```shell
sudo qwen3guard use-model qwen3guard-4b
sudo snap restart qwen3guard
```

## 资源需求

以下数据为 `llama-server` 进程的 RSS 峰值，基于本 snap 内置的 Q4_K_M 权重
与所固定的 llama.cpp 运行时，在 cpu 引擎下实测：

| 变体 | 上下文长度 | 内存峰值（估算） |
| --- | --- | --- |
| 0.6B | 4 096 | 约 1 GB |
| 4B | 4 096 | 约 3.5 GB |
| 8B | 4 096 | 约 6 GB |

0.6B 变体安装后占用磁盘约 0.7 GB（snap、llama.cpp 组件与模型权重）；若选用 nvidia-gpu 引擎，
需再增加约 1.1 GB；若选用 amd-gpu 引擎，需再增加约 3.8 GB。更大的变体分别额外占用约
2.2 GB（4B）或约 4.6 GB（8B）。

上下文长度并非固定值：llama.cpp 的 `--fit` 会依据可用内存自动设定，并以 `--fit-ctx`
（默认 4096）为下限。

## 配置

引擎从 snap 配置中读取设置：

| 配置项 | 默认值 | 作用 |
| --- | --- | --- |
| `min-context-size` | `4096` | `--fit-ctx` 的下限；`--fit` 会将上下文扩展到模型的上限 |
| `sleep-idle-seconds` | `600` | `llama-server` 卸载模型前的空闲时间 |
| `http.port` / `http.host` | `8364` / `127.0.0.1` | 兼容 OpenAI 的 API |
| `webui.http.port` / `webui.http.host` | `8365` / `127.0.0.1` | snap 内置的 Web UI |

使用 `qwen3guard get` 查看；修改需要 root（`sudo qwen3guard set`），并且必须重启服务才会生效：

```shell
qwen3guard get
sudo qwen3guard set sleep-idle-seconds=300
sudo snap restart qwen3guard
```

## 作为安全护栏使用

Qwen3Guard 专为内容安全分类而设计。将文本发送至 chat completions 端点，
模型将返回安全评估结果：

```shell
curl -s http://127.0.0.1:8364/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3guard-0.6b",
  "messages": [{"role": "user", "content": "在此输入待评估的文本"}],
  "max_tokens": 256}'
```

## 相关资源

📚 **[文档](https://documentation.ubuntu.com/inference-snaps/)**，了解如何使用推理 snap

🤗 **[模型卡（0.6B）](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)**，上游文档

🤗 **[模型卡（4B）](https://huggingface.co/Qwen/Qwen3Guard-Gen-4B)**，上游文档

🤗 **[模型卡（8B）](https://huggingface.co/Qwen/Qwen3Guard-Gen-8B)**，上游文档

📄 **[技术报告](https://arxiv.org/abs/2510.14276)**，Qwen3Guard 论文

💻 **[Qwen3Guard 源码](https://github.com/QwenLM/Qwen3Guard)**，上游仓库

🐛 **[Issues](https://github.com/amenezes/qwen3guard-snap/issues)**，反馈问题或提出功能需求

## 关于本 snap 的说明

* **运行时版本固定：** llama.cpp 固定在构建版本 `b10344`。该构建版本同时被 `phi4`、
  `smollm2`、`gemma4` 和 `minicpm5-2b` 等 snap 采用。Qwen3 架构自更早的构建版本起即已支持。
  版本更新以 Renovate 提交的待审 PR 形式进入，并且必须通过冒烟测试。
* **对话模板：** 引擎传入 `--jinja`，以确保 llama.cpp 正确应用 GGUF 中嵌入的 Qwen3 对话
  模板。
* **无推理/思考模式：** Qwen3Guard 不是推理模型，无需 `--reasoning-preserve` 标志。
* **采样：** 引擎使用 llama.cpp 的默认采样参数。与 MiniCPM5 不同，Qwen3Guard 不需要
  `--min-p 0.0`。
* **模型许可证：** Apache-2.0（阿里云 / 通义千问团队）。打包代码为 GPL-3.0。
* **引擎选择：** 只要 PCI 总线上存在对应厂商的 GPU，就会选用 `nvidia-gpu` 或
  `amd-gpu` 引擎，即使驱动不可用。此时后端初始化失败，llama.cpp 会回退到 CPU 后端；
  可运行 `sudo qwen3guard use-engine cpu` 切回并释放该引擎组件（NVIDIA 约 1.1 GB，
  AMD 约 3.8 GB）。AMD 引擎仅匹配内置 ROCm 构建支持的微架构
  （gfx1010–gfx1201，含 RX 9070 XT）；较旧的 AMD GPU 会选择 cpu 引擎。引擎在安装时选择，需要
  `hardware-observe` 接口；若该接口尚未获得自动连接授权，请手动连接并重新执行选择：
  ```shell
  sudo snap connect qwen3guard:hardware-observe
  sudo qwen3guard use-engine --auto
  ```
* **Provider：** 本 snap 导出一个 `inference-provider` content 插槽，其他 snap 可直接使用该
  端点，而无需自行运行模型。
* **本地 API：** 该端点没有身份验证，并允许跨域请求（内置 Web UI 需要）。它仅监听
  `127.0.0.1` —— 请勿将 `http.host` 改为公网接口。

## 从源码构建并安装

克隆仓库：
```shell
git clone <this-repo>
```

初始化开发环境：
```shell
make init
```

默认情况下 `snapcraft` 在容器内构建，因此需要先准备构建提供程序。使用 LXD 时，先初始化一次
（`--storage-backend=dir` 可避免创建 ZFS loop 池）：

```shell
lxd init --auto --storage-backend=dir
```

若没有提供程序，可直接在主机上构建：
`sudo snapcraft pack --destructive-mode --platform amd64`。

构建并安装 snap：
```shell
make build
make install
```

`make init` 会下载默认的 0.6B Q4_K_M GGUF 并校验其 sha256。如需下载全部模型变体
（0.6B、4B、8B），请使用 `make init-all`。如需改用本地副本，请将其放到
`components/model-q4-k-m-0-6b-gguf/Qwen3Guard-Gen-0.6B.Q4_K_M.gguf`
（其他变体同理），然后运行 `make verify-model`（或 `make verify-extra-models`）。

## 发布到 Snap Store

有两项商店侧申请是前置条件，且都需要时间，请尽早提交：

* **组件上传权限** —— 权重与 llama.cpp 运行时以
  [组件](https://snapcraft.io/docs/explanation/how-snaps-work/snap-components/)形式发布，而组件
  上传仅限商店白名单内的账号。请在
  [Snapcraft 论坛](https://forum.snapcraft.io/c/store-requests/)提交申请。
* **`hardware-observe` 的自动连接** —— 该接口默认不会自动连接，因此在申请获批前，从商店安装的
  snap 无法在 `use-engine --auto` 时检测硬件（参见
  [流程](https://snapcraft.io/docs/reference/administration/process-for-aliases-auto-connections-and-tracks/)）。

首次上传还需要注册名称，以及一个真实存在的仓库：商店页面会链接到 `snap/snapcraft.yaml` 中的
`website`、`source-code`、`issues` 和 `contact`。

```shell
snapcraft login
snapcraft register qwen3guard
make build
./dev/upload.sh latest/edge   # snapcraft upload <snap> --component ... --release=latest/edge
```

配置好 `SNAPCRAFT_STORE_CREDENTIALS` secret（`snapcraft export-login` 的输出）后，
`.github/workflows/cicd.yaml` 会在每次推送到 `main` 时发布到 `latest/edge`。
