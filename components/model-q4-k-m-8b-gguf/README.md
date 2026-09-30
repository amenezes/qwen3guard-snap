# Qwen3Guard-Gen-8B.Q4_K_M.gguf

Model weights for [Qwen3Guard-Gen-8B](https://huggingface.co/Qwen/Qwen3Guard-Gen-8B), the
8B safety guardrail model from Alibaba Cloud (Qwen Team), quantized to Q4_K_M and published by
the community (e.g. [bartowski/Qwen3Guard-Gen-8B-GGUF](https://huggingface.co/bartowski/Qwen3Guard-Gen-8B-GGUF)).

The weights are **not** committed (`.gitignore` excludes `*.gguf`). `make init-all` downloads them
into this directory and verifies the pinned checksum:

```shell
make download-extra-models   # hf download $(GGUF_8B_REPO) $(GGUF_8B_FILE) --local-dir components/model-q4-k-m-8b-gguf
make verify-extra-models     # sha256sum --check against GGUF_8B_SHA256 in the Makefile
```

| Field | Value |
| --- | --- |
| File | `Qwen3Guard-Gen-8B.Q4_K_M.gguf` |
| Quantization | Q4_K_M (single file, no shards) |
| License | Apache-2.0 (Alibaba Cloud / Qwen Team) |

## Why this README is tracked

Same rationale as the 0.6B variant: keeps the directory in git for buildability while the weight
stays out of the repository.
