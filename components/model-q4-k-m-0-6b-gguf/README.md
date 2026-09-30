# Qwen3Guard-Gen-0.6B.Q4_K_M.gguf

Model weights for [Qwen3Guard-Gen-0.6B](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B), the
0.6B safety guardrail model from Alibaba Cloud (Qwen Team), quantized to Q4_K_M and published by
the community (e.g. [bartowski/Qwen3Guard-Gen-0.6B-GGUF](https://huggingface.co/bartowski/Qwen3Guard-Gen-0.6B-GGUF)).

The weights are **not** committed (`.gitignore` excludes `*.gguf`). `make init` downloads them
into this directory and verifies the pinned checksum:

```shell
make download-models   # hf download $(GGUF_REPO) $(GGUF_FILE) --local-dir components/model-q4-k-m-0-6b-gguf
make verify-model      # sha256sum --check against GGUF_06B_SHA256 in the Makefile
```

To build offline (or from an internal mirror), place the file here yourself and run
`make verify-model`; the `GGUF_06B_REPO`/`GGUF_06B_FILE`/`GGUF_06B_SHA256` variables in the
`Makefile` are overridable.

| Field | Value |
| --- | --- |
| File | `Qwen3Guard-Gen-0.6B.Q4_K_M.gguf` |
| Quantization | Q4_K_M (single file, no shards) |
| License | Apache-2.0 (Alibaba Cloud / Qwen Team) |

Single-file GGUF, so `models/qwen3guard-0.6b/model.yaml` needs no `layout`/symlinks: the weight is
mounted by the `model-q4-k-m-0-6b-gguf` component at `$SNAP_COMPONENTS/model-q4-k-m-0-6b-gguf/`
and exposed as `MODEL_FILE`.

## Why this README is tracked

`snap/snapcraft.yaml` has a `local-component-files` part with `source: components`. Keeping this
directory in git makes a fresh clone buildable (and fails with a clear "file not found" instead of
a missing source directory) while the weight stays out of the repository. The part organizes only
the `.gguf` into the component and prunes everything else, so this file is never shipped inside
the snap.
