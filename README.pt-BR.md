# Snap de inferência do Qwen3Guard

[![qwen3guard](https://snapcraft.io/qwen3guard/badge.svg)](https://snapcraft.io/qwen3guard)

<!-- README-I18N:START -->

[English](./README.md) | **Português (Brasil)** | [简体中文](./README.zh-CN.md)

<!-- README-I18N:END -->

O **[Qwen3Guard-Gen](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)** é a família de modelos
de guardrail de segurança da [Alibaba Cloud (Qwen Team)](https://qwen.ai), projetada para
moderação de conteúdo em tempo real e classificação de segurança em fluxos de tokens. Três
tamanhos estão disponíveis:

* **0.6B**: ultraleve, ideal para implantação em edge e no próprio dispositivo
* **4B**: equilíbrio entre qualidade e uso de recursos
* **8B**: maior precisão para cargas de trabalho exigentes

Use este snap para instalar rapidamente um ambiente otimizado para inferência local com o
Qwen3Guard.

O snap inclui os seguintes motores de inferência otimizados por hardware:

* cpu: otimizado para CPUs x64 e ARM (armv8, armv9)
* nvidia-gpu: aceleração por GPU com CUDA

O motor mais adequado é selecionado automaticamente de acordo com o hardware disponível.

#### Instalação
```shell
sudo snap install qwen3guard
```

#### Execução
```shell
qwen3guard
```

> [!TIP]
> Alguns aceleradores exigem [drivers](https://documentation.ubuntu.com/inference-snaps/how-to/setup/drivers/) adicionais para funcionar com este snap.

## Variantes do modelo

Três tamanhos de modelo estão disponíveis. A variante 0.6B (Q4_K_M) é o padrão; troque com
`sudo qwen3guard use-model <variante>` e reinicie o serviço:

| Variante | Parâmetros | Disco (instalado) | Observações |
| --- | --- | --- | --- |
| `qwen3guard-0.6b` (padrão) | 0.6B | ~0,7 GB | Ultraleve, recomendado para edge/no dispositivo |
| `qwen3guard-4b` | 4B | ~2,9 GB | Equilíbrio entre qualidade e uso de recursos |
| `qwen3guard-8b` | 8B | ~5,3 GB | Maior precisão para cargas de trabalho exigentes |

```shell
sudo qwen3guard use-model qwen3guard-4b
sudo snap restart qwen3guard
```

## Requisitos

Medidos como o pico de RSS do processo `llama-server`, com os pesos Q4_K_M incluídos
e o runtime llama.cpp da versão fixada, no motor cpu:

| Variante | Tamanho de contexto | Pico de memória (est.) |
| --- | --- | --- |
| 0.6B | 4 096 | ~1 GB |
| 4B | 4 096 | ~3,5 GB |
| 8B | 4 096 | ~6 GB |

O uso de disco é de ~0,7 GB após a instalação (snap, componente do llama.cpp e pesos) para a
variante 0.6B, mais ~1,1 GB se o motor nvidia-gpu for selecionado. As variantes maiores
acrescentam ~2,2 GB (4B) ou ~4,6 GB (8B).

O tamanho do contexto não é fixo: o recurso `--fit` do llama.cpp o dimensiona conforme a
memória disponível, usando `--fit-ctx` (padrão 4096) como piso.

## Configuração

O motor lê as suas opções da configuração do snap:

| Opção | Padrão | Para que serve |
| --- | --- | --- |
| `min-context-size` | `4096` | Piso do `--fit-ctx`; o `--fit` amplia o contexto até o limite do modelo |
| `sleep-idle-seconds` | `600` | Tempo ocioso antes de o `llama-server` descarregar o modelo |
| `http.port` / `http.host` | `8364` / `127.0.0.1` | API compatível com OpenAI |
| `webui.http.port` / `webui.http.host` | `8365` / `127.0.0.1` | Web UI incluída no snap |

Leia com `qwen3guard get`; alterar exige root (`sudo qwen3guard set`), e o serviço precisa ser
reiniciado para aplicar:

```shell
qwen3guard get
sudo qwen3guard set sleep-idle-seconds=300
sudo snap restart qwen3guard
```

## Uso como guardrail

O Qwen3Guard foi projetado para classificar a segurança de conteúdo. Envie texto ao endpoint de
chat completions e o modelo responderá com uma avaliação de segurança:

```shell
curl -s http://127.0.0.1:8364/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3guard-0.6b",
  "messages": [{"role": "user", "content": "Seu texto para avaliar aqui"}],
  "max_tokens": 256}'
```

## Recursos

📚 **[Documentação](https://documentation.ubuntu.com/inference-snaps/)**, aprenda a usar snaps de inferência

🤗 **[Card do modelo (0.6B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-0.6B)**, documentação do modelo no upstream

🤗 **[Card do modelo (4B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-4B)**, documentação do modelo no upstream

🤗 **[Card do modelo (8B)](https://huggingface.co/Qwen/Qwen3Guard-Gen-8B)**, documentação do modelo no upstream

📄 **[Relatório técnico](https://arxiv.org/abs/2510.14276)**, artigo do Qwen3Guard

💻 **[Código do Qwen3Guard](https://github.com/QwenLM/Qwen3Guard)**, repositório upstream

🐛 **[Issues](https://github.com/amenezes/qwen3guard-snap/issues)**, relate problemas e solicite novos recursos

## Notas sobre este snap

* **Versão fixada do runtime:** o llama.cpp está fixado no build `b10344`. Este é o build
  também usado pelos snaps `phi4`, `smollm2`, `gemma4` e `minicpm5-2b`. A arquitetura Qwen3
  é suportada desde builds anteriores. As atualizações chegam como PRs revisados pelo Renovate
  e precisam passar nos smoke tests.
* **Chat template:** o motor passa `--jinja` para garantir que o llama.cpp aplique corretamente
  o chat template do Qwen3 embutido no GGUF.
* **Sem reasoning/thinking:** o Qwen3Guard não é um modelo de raciocínio; nenhuma flag
  `--reasoning-preserve` é necessária.
* **Amostragem:** o motor usa os padrões do llama.cpp para os parâmetros de amostragem. Ao
  contrário do MiniCPM5, o Qwen3Guard não requer `--min-p 0.0`.
* **Licença do modelo:** Apache-2.0 (Alibaba Cloud / Qwen Team). O código de empacotamento é GPL-3.0.
* **Seleção de motor:** o motor `nvidia-gpu` é escolhido sempre que existe uma GPU NVIDIA no
  barramento PCI, mesmo que o driver não esteja utilizável. Nesse caso o CUDA falha ao
  inicializar e o llama.cpp cai para o backend de CPU; rode
  `sudo qwen3guard use-engine cpu` para voltar e liberar o componente de ~1,1 GB. A seleção roda
  na instalação e precisa da interface `hardware-observe`; se a auto-conexão dela ainda não tiver
  sido concedida, conecte e rode a seleção manualmente:
  ```shell
  sudo snap connect qwen3guard:hardware-observe
  sudo qwen3guard use-engine --auto
  ```
* **Provider:** o snap exporta um slot de conteúdo `inference-provider`, para que outro snap
  consuma este endpoint em vez de rodar o próprio modelo.
* **API local:** o endpoint não tem autenticação e permite requisições cross-origin, o que a web
  UI incluída precisa. Ele escuta apenas em `127.0.0.1` — não reaponte `http.host` para uma
  interface pública.

## Compilar e instalar a partir do código-fonte

Clone o repositório:
```shell
git clone <this-repo>
```

Inicialize o ambiente de desenvolvimento:
```shell
make init
```

Por padrão o `snapcraft` compila dentro de um contêiner, então é preciso ter um provedor de build
disponível. Com LXD, inicialize-o uma vez (`--storage-backend=dir` evita um pool ZFS em loop):

```shell
lxd init --auto --storage-backend=dir
```

Sem provedor, compile no próprio host com
`sudo snapcraft pack --destructive-mode --platform amd64`.

Compile e instale o snap:
```shell
make build
make install
```

O `make init` baixa o GGUF Q4_K_M padrão de 0.6B e verifica o seu sha256. Para baixar todas as
variantes do modelo (0.6B, 4B, 8B), use `make init-all`. Para usar uma cópia local, coloque-a em
`components/model-q4-k-m-0-6b-gguf/Qwen3Guard-Gen-0.6B.Q4_K_M.gguf` (e de forma semelhante para
as outras variantes) e execute `make verify-model` (ou `make verify-extra-models`).

## Publicação na Snap Store

Dois pedidos à loja são pré-requisitos, e ambos demoram, então abra-os cedo:

* **Permissão de upload de componentes** — os pesos e o runtime llama.cpp viajam como
  [componentes](https://snapcraft.io/docs/explanation/how-snaps-work/snap-components/), e o upload
  de componentes é restrito a contas na allow-list da loja. Peça no
  [fórum do Snapcraft](https://forum.snapcraft.io/c/store-requests/).
* **Auto-conexão de `hardware-observe`** — a interface não é auto-conectada por padrão, então uma
  instalação vinda da loja não detecta o hardware no `use-engine --auto` até o pedido ser
  aprovado (ver o
  [processo](https://snapcraft.io/docs/reference/administration/process-for-aliases-auto-connections-and-tracks/)).

O primeiro upload também exige o nome registrado e um repositório que exista de fato: a página da
loja aponta para `website`, `source-code`, `issues` e `contact` do `snap/snapcraft.yaml`.

```shell
snapcraft login
snapcraft register qwen3guard
make build
./dev/upload.sh latest/edge   # snapcraft upload <snap> --component ... --release=latest/edge
```

O `.github/workflows/cicd.yaml` publica em `latest/edge` a cada push na `main` quando o secret
`SNAPCRAFT_STORE_CREDENTIALS` (saída de `snapcraft export-login`) estiver configurado.
