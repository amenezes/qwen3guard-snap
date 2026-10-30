# Qwen3Guard inference snap

[![qwen3guard](https://snapcraft.io/qwen3guard/badge.svg)](https://snapcraft.io/qwen3guard)

<!-- README-I18N:START -->

**English** | [Português (Brasil)](./README.pt-BR.md) | [简体中文](./README.zh-CN.md)

<!-- README-I18N:END -->

**[Qwen3Guard-Gen](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)** is
[Alibaba Cloud (Qwen Team)](https://qwen.ai)'s family of safety guardrail models, designed for
real-time content moderation and safety classification on token streams. Three sizes are available:

* **0.6B**: ultra-lightweight, ideal for edge and on-device deployment
* **4B**: balanced quality and resource usage
* **8B**: highest accuracy for demanding workloads

Use this snap to quickly install an optimized environment for local inference with Qwen3Guard.

The snap includes the following hardware-optimized inference engines:

* cpu: Optimized for x64 and ARM (armv8, armv9) CPUs
* nvidia-gpu: CUDA-enabled GPU acceleration
* amd-gpu: ROCm-enabled GPU acceleration for AMD GPUs

The most suitable engine is automatically selected based on the available hardware.

#### Install
```shell
sudo snap install qwen3guard
```

#### Run
```shell
qwen3guard
```

> [!TIP]
> Some accelerators require extra [drivers](https://documentation.ubuntu.com/inference-snaps/how-to/setup/drivers/) to be usable with this snap.
> The `amd-gpu` engine uses the in-kernel `amdgpu` driver (KFD); the ROCm
> user-space libraries are bundled in the snap, so no host ROCm install is needed.

## Model variants

Three model sizes are available. The 0.6B variant (Q4_K_M) is the default; switch with
`sudo qwen3guard use-model <variant>` and restart the service:

| Variant | Parameters | Disk (installed) | Notes |
| --- | --- | --- | --- |
| `qwen3guard-0.6b` (default) | 0.6B | ~0.7 GB | Ultra-lightweight, recommended for edge/on-device |
| `qwen3guard-4b` | 4B | ~2.9 GB | Balanced quality and resource usage |
| `qwen3guard-8b` | 8B | ~5.3 GB | Highest accuracy for demanding workloads |

```shell
sudo qwen3guard use-model qwen3guard-4b
sudo snap restart qwen3guard
```

## Requirements

Measured as the peak RSS of the `llama-server` process, with the bundled Q4_K_M weights
and the pinned llama.cpp runtime on the cpu engine:

| Variant | Context size | Peak memory (est.) |
| --- | --- | --- |
| 0.6B | 4 096 | ~1 GB |
| 4B | 4 096 | ~3.5 GB |
| 8B | 4 096 | ~6 GB |

Disk usage is ~0.7 GB once installed (snap, llama.cpp component and model weights) for the 0.6B
variant, plus ~1.1 GB if the nvidia-gpu engine is selected, or ~3.8 GB if the amd-gpu engine is
selected. Larger variants add ~2.2 GB (4B) or ~4.6 GB (8B).

The context size is not fixed: llama.cpp's `--fit` feature sizes it to the memory
available, using `--fit-ctx` (default 4096) as the floor.

## Configuration

The engine reads its settings from the snap configuration:

| Setting | Default | Purpose |
| --- | --- | --- |
| `min-context-size` | `4096` | Floor for `--fit-ctx`; `--fit` grows the context up to the model's limit |
| `sleep-idle-seconds` | `600` | Idle time before `llama-server` unloads the model |
| `http.port` / `http.host` | `8364` / `127.0.0.1` | OpenAI-compatible API |
| `webui.http.port` / `webui.http.host` | `8365` / `127.0.0.1` | Bundled web UI |

Read them with `qwen3guard get`; changing them needs root (`sudo qwen3guard set`), and the
service has to be restarted to apply:

```shell
qwen3guard get
sudo qwen3guard set sleep-idle-seconds=300
sudo snap restart qwen3guard
```

## Usage as a guardrail

Qwen3Guard is designed to classify content safety. Send text to the chat completions endpoint
and the model will respond with a safety assessment:

```shell
curl -s http://127.0.0.1:8364/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3guard-0.6b",
  "messages": [{"role": "user", "content": "Your text to evaluate here"}],
  "max_tokens": 256}'
```

## Resources

📚 **[Documentation](https://documentation.ubuntu.com/inference-snaps/)**, learn how to use inference snaps

🤗 **[Model card (0.6B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)**, upstream documentation

🤗 **[Model card (4B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-4B)**, upstream documentation

🤗 **[Model card (8B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-8B)**, upstream documentation

📄 **[Technical Report](https://arxiv.org/abs/2510.14276)**, Qwen3Guard paper

💻 **[Qwen3Guard source](https://github.com/QwenLM/Qwen3Guard)**, upstream repository

🐛 **[Issues](https://github.com/amenezes/qwen3guard-snap/issues)**, report bugs and request features

## Notes on this snap

* **Runtime pin:** llama.cpp is pinned to `b10344`. This is the build also used by the `phi4`,
  `smollm2`, `gemma4` and `minicpm5-2b` snaps. Qwen3 architecture is supported since earlier
  builds. Bumps arrive as reviewed Renovate PRs and must pass smoke tests.
* **Chat template:** the engine passes `--jinja` to ensure llama.cpp applies the Qwen3 chat
  template embedded in the GGUF correctly.
* **No reasoning/thinking:** Qwen3Guard is not a thinking model; no `--reasoning-preserve` flag
  is needed.
* **Sampling:** the engine uses llama.cpp defaults for sampling parameters. Unlike MiniCPM5,
  Qwen3Guard does not require `--min-p 0.0`.
* **Model license:** Apache-2.0 (Alibaba Cloud / Qwen Team). The packaging code is GPL-3.0.
* **Engine selection:** the `nvidia-gpu` and `amd-gpu` engines are picked whenever a GPU
  from the matching vendor is present on the PCI bus, even if the driver is not usable.
  The backend then fails to initialise and llama.cpp falls back to the CPU backend; run
  `sudo qwen3guard use-engine cpu` to switch back and free the engine component
  (~1.1 GB NVIDIA, ~3.8 GB AMD). The AMD engine only matches the microarchitectures
  supported by the bundled ROCm build (gfx1010-gfx1201, including the RX 9070 XT);
  older AMD GPUs select the cpu engine. Selection runs
  at install time and needs the `hardware-observe` interface; if its auto-connection has not been
  granted, connect it and re-run the selection manually:
  ```shell
  sudo snap connect qwen3guard:hardware-observe
  sudo qwen3guard use-engine --auto
  ```
* **AMD engine needs `process-control`:** the ROCm runtime pins its worker threads with
  `sched_setaffinity`, and snapd's default seccomp policy only allows that call for pid 0.
  Without the plug, HSA fails to initialise, llama.cpp reports `no ROCm-capable device is
  detected` and runs on the CPU while the engine still shows `amd-gpu`. The interface is not
  auto-connected, so connect it once after install -- and request its auto-connection before
  publishing to the store:
  ```shell
  sudo snap connect qwen3guard:process-control
  sudo snap restart qwen3guard.server
  ```
* **Provider:** the snap exports an `inference-provider` content slot, so another snap can consume
  this endpoint instead of running its own model.
* **Local API:** the endpoint has no authentication and allows cross-origin requests, which the
  bundled web UI needs. It listens on `127.0.0.1` only -- do not rebind `http.host` to a public
  interface.

## Build and install from source

Clone the repo:
```shell
git clone https://github.com/amenezes/qwen3guard-snap
```

Initialize the development environment:
```shell
make init
```

`snapcraft` builds inside a container by default, so a build provider must be available first.
With LXD, initialize it once (`--storage-backend=dir` avoids a ZFS loop pool):

```shell
lxd init --auto --storage-backend=dir
```

Without a provider, build on the host with `sudo snapcraft pack --destructive-mode
--platform amd64` instead.

Build and install snap:
```shell
make build
make install
```

`make install` installs the snap and every `.comp` in the directory, reconnects the interfaces
and preserves the engine already selected. To change the engine on a fresh installation — or
after `./dev/install.sh --clean`, which wipes the configuration — pass `--engine`:

```shell
./dev/install.sh --engine=amd-gpu
```

`make init` downloads the default 0.6B Q4_K_M GGUF and verifies its sha256. To
download all model variants (0.6B, 4B, 8B), use `make init-all` instead.
To use a local copy, place it at `components/model-q4-k-m-0-6b-gguf/Qwen3Guard-Gen-0.6B.Q4_K_M.gguf`
(and similarly for the other variants) and run `make verify-model` (or
`make verify-extra-models`).
