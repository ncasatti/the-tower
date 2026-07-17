# gbrain — Notas de continuación (TEMP)

> Archivo temporal para retomar. Fecha: 2026-06-19 · gbrain v0.42.51.0 · host: the-tower (NixOS).
> No es doc del repo — borrar cuando se cierre la instalación.

## TL;DR — dónde estamos

Instalando **gbrain** (knowledge base con RAG, corre sobre Bun+TS) en NixOS, **adaptando** las instrucciones oficiales (no siguiéndolas literal). Vamos por la **estrategia A (pragmática)**. Pasos 1 y 2 hechos; falta secrets, init e scheduling. Y **decisión pendiente**: postura de secrets (A/B/C, ver abajo).

---

## 1. Decisión arquitectónica

gbrain es **auto-mutante por diseño** (se auto-actualiza, corre migraciones, baja deps en runtime). Eso define todo:

| Opción | Qué es | Veredicto |
|---|---|---|
| **A — Pragmática** ✅ | Nix declara el ENTORNO (toolchain + secrets + timers); gbrain queda mutable | **ELEGIDA** — respeta el diseño de la herramienta |
| B — Derivation pura | Empaquetar gbrain como derivation Nix | Descartada: alto esfuerzo, rompe `gbrain upgrade`/migraciones |
| C — Flake input | gbrain como input del overlay | Parkeada: hay fork+flake de backup, pero pelea igual que B |

**Reparto de A:** Nix declara lo reproducible (toolchain, scheduling) · lo mutable (binario, DB, secrets) vive fuera de Nix.

## 2. Working directories

```
/home/flyn/.the-grid/systems/opensource/gbrain   ← UPSTREAM — acá laburamos (A)
/home/flyn/.the-grid/systems/github/grid-brain     ← fork+flake — PARKEADO (backup C)
```

---

## 3. Pasos de instalación

```
[✓] Paso 1 — Toolchain: `bun` agregado a nix/packages/languages.nix
            (nixpkgs trae 1.3.13; gbrain requiere >=1.3.10). Falta: rebuild del host.
[✓] Paso 2 — Binario: `bun install && bun link` en el clone upstream.
            PATH ya era declarativo: fish/conf.d/00-env.fish:12 (BUN_INSTALL=$HOME/.bun)
            + 01-path.fish:13. Link en ~/.bun/bin/gbrain → ...node_modules/gbrain/src/cli.ts
            (gbrain NO tiene build step: el bin apunta directo a src/cli.ts).
[ ] Paso 3 — Secrets: ~/.config/gbrain/secrets.env (chmod 600) — SIN agenix (nunca funcionó).
[ ] Paso 4 — Init + estado: `gbrain init` (DB PGLite local) + `gbrain import ~/brain/`.
[ ] Paso 5 — Scheduling: systemd.user timers (Home Manager), NO `gbrain autopilot --install`.
```

## 4. DECISIÓN PENDIENTE — postura de secrets

| Postura | Embedding | Chat (think/dream) | Key | Costo |
|---|---|---|---|---|
| **A) Full local** | ollama (local) | — (sin síntesis) | ninguna | cero |
| **B) Híbrida** ★ | ollama (local) | Anthropic | 1 (Anthropic) | bajo |
| **C) Turnkey** | ZeroEntropy | Anthropic | 2 | embedding pago |

Recomendación CLU: **B**. El usuario hoy tiene **cero API keys**.

---

## 5. FUNDAMENTOS de IA revisados (la parte de capacitación)

### gbrain = ORQUESTADOR, no motor
gbrain es un cliente (Bun/TS). No tiene pesos ni hace inferencia. **Dirige la orquesta**: chunkea, llama por HTTP al provider del rol, guarda/combina. Incluso lo "local" (ollama) es otro proceso al que le habla por HTTP. Lo que gbrain SÍ ejecuta él mismo (cero IA): chunking, BM25, grafo, fusión híbrida, DB.

### Es un sistema RAG (Retrieval-Augmented Generation)
```
pregunta → [embedding] → [vector search + BM25] → [rerank] → [Claude sintetiza] → respuesta
           ───────────── RETRIEVAL (encuentra) ──────────     ── GENERATION (explica) ──
```
**Retrieval ENCUENTRA (no es Claude) · Claude EXPLICA.** El LLM no "se sabe" tus notas: se las inyectás en el contexto tras encontrarlas con embeddings.

### Los 4 roles de IA (cada uno = string `provider:model` independiente)
| Rol | Qué hace | Cuándo |
|---|---|---|
| Embedding | texto → vector (base semántica) | import, embed |
| Reranking | reordena con cross-encoder | solo modo tokenmax |
| Expansion | reescribe la query | solo tokenmax |
| Chat/LLM | razona y sintetiza | think, dream synthesize |

### Embedding vs LLM (el contraste clave)
| | Embedding | LLM (Claude) |
|---|---|---|
| Produce | vector fijo (ej. 1280 floats) | texto (token a token) |
| Trabajo | representar significado como geometría | razonar y generar |
| Arquitectura | encoder (BERT-like) | decoder autoregresivo |
| Determinismo | determinista | estocástico |
| Tamaño | chico/barato/rápido | grande/caro |

Metáfora: embedding = **bibliotecario que cataloga** (coordenada GPS de significado, nunca escribe ensayos) · LLM = **erudito** que lee y redacta. Propiedad mágica del embedding: **cercanía de significado = cercanía geométrica**.

### Dónde entra Claude
Rol **Chat** (`think`, `dream synthesize`) y por default **Expansion** (Haiku). NO hace embedding (Anthropic no tiene modelo de embedding) ni reranking.

---

## 6. Mapa de API keys / providers (VERIFICADO contra el código)

### Requiere key
- `import`/`embed` (embedding) — salvo `--no-embed` o embedding local
- `think` (chat — degrada con gracia: sin key da solo "gather", no síntesis)
- `dream --phase synthesize` / `extract_atoms` (chat)
- `search`/`query` en modo **tokenmax** (rerank + expansion)
- `autopilot` (chat)

### NO requiere key (offline)
- `init`, `doctor`, `stats`, `list/get/put/delete`, `tag/link/graph/timeline/history`
- `search`/`query` en `conservative` y `balanced`
- `dream --phase lint/patterns/consolidate/publish`

### Providers por rol (17 recipes en src/core/ai/recipes/index.ts)
| Rol | Remotos (key) | Local / keyless |
|---|---|---|
| Embedding | zeroentropy*, openai, google, voyage, together… | **ollama, llama-server** (`auth_env.required:[]`) |
| Reranking | zeroentropy (zerank-2) | **llama-server-reranker** |
| Expansion | anthropic, openai, google… | ❌ remoto only |
| Chat | anthropic, openai, google, openrouter, groq, together, deepseek | ❌ **NO hay chat local en gbrain** |

> ⚠️ Verificado: ollama/llama-server/litellm-proxy solo declaran touchpoint `embedding`, NO `chat`. → Embedding y rerank pueden ser 100% locales, pero `think`/`dream synthesize` SIEMPRE necesitan chat remoto (o degradan).
> ⚠️ Anthropic NO tiene embedding (anthropic.ts:6). El README oficial es engañoso: el import default igual requiere key salvo ollama o `--no-embed`.

### Defaults (verificados)
| Rol | Default | Source |
|---|---|---|
| Embedding | `zeroentropyai:zembed-1` (1280 dims) | defaults.ts:20-21 |
| Chat | `anthropic:claude-sonnet-4-6` | gateway.ts:110 |
| Expansion | `anthropic:claude-haiku-4-5-20251001` | gateway.ts:109 |
| Reranker | `zeroentropyai:zerank-2` | gateway.ts:114 |

## 7. Configuración

**Precedencia (gana arriba):** env vars → `~/.gbrain/config.json` → DB-plane (`gbrain config set`) → defaults.

```bash
gbrain config set embedding_model ollama:nomic-embed-text   # embedding → local
gbrain config set chat_model anthropic:claude-sonnet-4-6     # chat → remoto
gbrain config set search.mode balanced                       # sin rerank/expansion
gbrain doctor --json                                         # qué roles están listos
```
Formato siempre `provider:model`. Modos de búsqueda: `conservative` < `balanced` (default rec.) < `tokenmax` (rerank+expansion ON).

---

## 8. Próximo paso al retomar
Decidir postura de secrets (§4 → recomendado **B**) → armar `~/.config/gbrain/secrets.env` → `gbrain init` → systemd timers.
