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
variant, plus ~1.1 GB if the nvidia-gpu engine is selected. Larger variants add ~2.2 GB (4B) or
~4.6 GB (8B).

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
* **Engine selection:** the `nvidia-gpu` engine is picked whenever an NVIDIA GPU is
  present on the PCI bus, even if the driver is not usable. CUDA then fails to
  initialise and llama.cpp falls back to the CPU backend; run
  `sudo qwen3guard use-engine cpu` to switch back and free the ~1.1 GB component. Selection runs
  at install time and needs the `hardware-observe` interface; if its auto-connection has not been
  granted, connect it and re-run the selection manually:
  ```shell
  sudo snap connect qwen3guard:hardware-observe
  sudo qwen3guard use-engine --auto
  ```
* **Provider:** the snap exports an `inference-provider` content slot, so another snap can consume
  this endpoint instead of running its own model.
* **Local API:** the endpoint has no authentication and allows cross-origin requests, which the
  bundled web UI needs. It listens on `127.0.0.1` only -- do not rebind `http.host` to a public
  interface.

## Build and install from source

Clone the repo:
```shell
git clone <this-repo>
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

`make init` downloads the default 0.6B Q4_K_M GGUF and verifies its sha256. To
download all model variants (0.6B, 4B, 8B), use `make init-all` instead.
To use a local copy, place it at `components/model-q4-k-m-0-6b-gguf/Qwen3Guard-Gen-0.6B.Q4_K_M.gguf`
(and similarly for the other variants) and run `make verify-model` (or
`make verify-extra-models`).

## Publishing to the Snap Store

Two store-side requests are prerequisites, and both take time, so open them early:

* **Component upload access** -- the weights and the llama.cpp runtime ship as
  [components](https://snapcraft.io/docs/explanation/how-snaps-work/snap-components/), and
  uploading components is limited to accounts on the store's allow-list. Request it on the
  [Snapcraft forum](https://forum.snapcraft.io/c/store-requests/).
* **Auto-connection of `hardware-observe`** -- the interface is not auto-connected by default, so
  a store install cannot detect the hardware during `use-engine --auto` until the request is
  granted (see the
  [process](https://snapcraft.io/docs/reference/administration/process-for-aliases-auto-connections-and-tracks/)).

The first upload also requires a registered name, and a repository that actually exists: the store
listing links to `website`, `source-code`, `issues` and `contact` from `snap/snapcraft.yaml`.

```shell
snapcraft login
snapcraft register qwen3guard
make build
./dev/upload.sh latest/edge   # snapcraft upload <snap> --component ... --release=latest/edge
```

`.github/workflows/cicd.yaml` publishes to `latest/edge` on every push to `main` once the
`SNAPCRAFT_STORE_CREDENTIALS` secret (the output of `snapcraft export-login`) is configured.
