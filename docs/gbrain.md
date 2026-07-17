# SDD — gbrain (knowledge brain) + MCP server + LiteLLM proxy + ollama

**Status:** Draft v1 · **Target:** `nixosConfigurations.main` (+ opcional `notebook`) · **Date:** 2026-07-08
**Replaces:** `gbrain-notes.md` (borrar una vez implementado y verificado end-to-end)

---

## 1. Intent

Convertir `gbrain` (RAG personal sobre Bun+TS) en una herramienta **usable por los agentes del Tower** — primeramente por mí (CLU) — vía el **servidor MCP built-in** que trae de fábrica. Tres ejes:

1. **Knowledge base propia**, sincronizable con el Zettelkasten existente (`~/zettel-music-bak/` y/o directorio a definir — ver §9).
2. **Stack de IA 100% declarado en Nix**: toolchain + services + secrets + timers. Lo mutable (DB PGLite, binario gbrain auto-actualizado) vive fuera de Nix.
3. **Asistente con memoria** para los agentes: `query`, `search`, `ask` sobre tus notas como herramientas MCP first-class.

### Use cases
- "User, ¿qué我说过 sobre X?" → `query` al brain desde cualquier agente (incluido OpenCode).
- Memorias técnicas (decisiones, gotchas, observaciones) en una DB local que sobrevive a `git clean`.
- Daily check-in vía `gbrain advisor --json` (skill oficial) cuando esté integrada.

### Out of scope (deliberado)
- Exponer el brain vía HTTP para otros agentes remotos — stdio local alcanza para tu caso.
- `musnix` o realtime tuning para `ollama serve` — corremos CPU, no GPU, los `nomic-embed-text` (137M params) entran en cualquier RAM.
- Scheduler de dream cycle (`synthesize`/`patterns`/`consolidate`) — MCP **no puede** dispararlos (ver §2.ADR-007), se dejan para una v2 con timer dedicado.
- Importar TODO el `home` del usuario — empieza con un directorio acotado y se expande.

---

## 2. Architectural Decisions (ADRs)

Cada decisión es trazable. Las alternativas se evaluaron contra el código fuente de gbrain v0.42.51.0 (verificado).

### ADR-001 · Postura de secrets (FINAL)

| Tier | Provider | Cómo | Razón |
|---|---|---|---|
| **Embedding** | `ollama:nomic-embed-text` | local, sin key | Gratis, offline, privado. Subscription Key de MiniMax no autoriza `/v1/embeddings` (verificado: `status_code: 2049, status_msg: "invalid api key"`). |
| **Chat / Expansion** | LiteLLM proxy → MiniMax-M3 / M2.7-highspeed | local proxy sobre Subscription Key | LiteLLM es el patrón oficial upstream (`recipes/litellm-proxy.ts`). MiniMax expone `/anthropic` interface para Subscription Key (verificado contra doc oficial). |
| **Rerank** | OFF | — | Solo activo en modo `tokenmax` (ver §3). Costo/beneficio desfavorable en v1. |

**Rechazadas:**
- *Postura A pura (ollama local chat)* — gbrain **no tiene chat provider local** (verificado: `recipes/ollama.ts` solo declara touchpoint `embedding`). `think`/`dream synthesize` degradarían a gather-only.
- *Postura C (turnkey ZeroEntropy + Anthropic)* — paga por embedding cuando ollama es gratis. Gasta la cuota antes de tiempo.
- *Pagar PayGo API Key de MiniMax solo para embedding* — explícitamente descartado por el User ("no pago por api").

### ADR-002 · Estrategia de empaquetado de gbrain: **Pragmática (A)**

**Decisión:** gbrain NO se empaqueta como derivation Nix. Vive como binario auto-mutante en `~/.bun/install/global/` y se actualiza vía `gbrain self-upgrade`.

**Razón:** gbrain es auto-mutante por diseño (auto-updates + migraciones + baja deps en runtime). Empaquetarlo en Nix rompe su modelo de actualización y desacopla su DB de su binario. La práctica oficial (vía `INSTALL_FOR_AGENTS.md`) es `bun install -g github:garrytan/gbrain`.

**Nix solo declara lo reproducible:** toolchain (`bun`), servicios (`ollama`, `litellm`), secrets layout, scheduling, MCP wiring.

### ADR-003 · Embedding provider: ollama local, declarado en NixOS

**Decisión:** `services.ollama.enable = true` en `nix/hosts/main/default.nix` + `home.packages = [ pkgs.ollama pkgs.litellm ]` en `packages/ai.nix`. Modelo `nomic-embed-text` se descarga vía `home.activation` (idempotente).

**Tradeoffs:**
- ✅ Cero costo recurrente. Cero keys. Cero cuotas.
- ✅ El recipe `recipes/ollama.ts` está declarado `keyless` (`auth_env.required:[]`) — wire-and-go.
- ⚠️ Vector pasa de 1536 dims (ZeroEntropy default) a **768 dims** (nomic-embed-text). Si migrás embeddings en el futuro, hay que re-embedear. Para v1 no hay embeddings previos → no hay migración.
- ⚠️ Requiere `~270MB RAM` para el modelo cargado + ~1GB para `ollama serve`. Bien dentro del budget del host.

**Por qué no `voyage` o `openai`:** cero costo es cero costo. La calidad de `nomic-embed-text` (MTEB top-tier) es más que suficiente para notas personales.

### ADR-004 · Chat provider: LiteLLM proxy → MiniMax (Subscription Key)

**Decisión:** `litellm` corre como `systemd --user` service, escucha en `127.0.0.1:4000`, expone un único model alias (`minimax-m3`) que apunta a `https://api.minimaxi.com/anthropic` con `Authorization: Bearer $MINIMAX_API_KEY`. El recipe de gbrain `anthropic` + `custom_base_url` lo consume vía `LITELLM_BASE_URL`.

**Patrón oficial upstream:** El recipe `recipes/litellm-proxy.ts` documenta exactamente este flujo:
> "Users run LiteLLM in front of any provider... and point gbrain at it via `LITELLM_BASE_URL`."

**Config del proxy (LiteLLM `config.yaml`):**
```yaml
model_list:
  - model_name: minimax-m3
    litellm_params:
      model: anthropic/MiniMax-M3
      api_key: os.environ/MINIMAX_API_KEY
      api_base: https://api.minimaxi.com/anthropic
  - model_name: minimax-fast
    litellm_params:
      model: anthropic/MiniMax-M2.7-highspeed
      api_key: os.environ/MINIMAX_API_KEY
      api_base: https://api.minimaxi.com/anthropic

litellm_settings:
  drop_params: true   # MiniMax no soporta todos los params de Anthropic SDK; los dropeamos silenciosamente
```

**Wire en gbrain:**
```bash
gbrain config set chat_model anthropic:minimax-m3         # via LiteLLM
gbrain config set expansion_model anthropic:minimax-fast  # via LiteLLM
gbrain config set embedding_model ollama:nomic-embed-text # local directo
```

Hmm — **fixme**: gbrain ya tiene `provider:model` como formato. Cuando el recipe es `anthropic` con `api_base` custom, sirve. Pero hay que verificar que LiteLLM (que escucha en `127.0.0.1:4000`) acepte el path. El AI SDK de gbrain usa `@ai-sdk/openai-compatible` (verificado en `gateway.ts:30`) — apuntamos `LITELLM_BASE_URL=http://127.0.0.1:4000` y `LITELLM_API_KEY` (opcional, vacía). El recipe de LiteLLM provee esto explícitamente.

**Tradeoffs:**
- ✅ Patrón oficial upstream; el recipe `litellm-proxy.ts` está literalmente hecho para esto.
- ✅ Mantenible: agregar/quitar modelos = editar un yaml, no tocar gbrain.
- ✅ Reusable: futuras integraciones (ej. un segundo agente) solo apuntan a `127.0.0.1:4000`.
- ⚠️ Un servicio más para mantener (~50MB RAM para LiteLLM idle).
- ⚠️ `gbrain` espera OpenAI-compatible *completo* — hay que verificar que LiteLLM's `/v1/chat/completions` no exponga peculiaridades que rompan a gbrain. **Pendiente: smoke test con `gbrain doctor --json` en T6.**

### ADR-005 · Scheduling: systemd --user timer, NO autopilot

**Decisión:** Timer único para `embed` (re-embed de páginas modificadas). NO se usa `gbrain autopilot --install`.

**Razón:** `autopilot` de gbrain es opinionated y trae su propio daemon. El usuario quiere control declarativo. Systemd `--user`:
- Vive en `home-manager`, declarativo en `nix/hosts/main/home.nix`.
- Se ve con `systemctl --user list-timers`.
- Logs en `journalctl --user`.

**Frecuencia v1:** cada 6h, `Persistent=true` (corre al boot si se perdió la última ejecución), `AccuracySec=15min` (jitter para no pegar todos al mismo segundo si hay más timers).

```nix
# fragmento en nix/hosts/main/home.nix
systemd.user.timers."gbrain-embed" = {
  description = "Re-embed stale gbrain pages";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnBootSec = "5min";
    OnUnitActiveSec = "6h";
    RandomizedDelaySec = "15min";
    Persistent = true;
  };
};

systemd.user.services."gbrain-embed" = {
  description = "Embed gbrain pages";
  serviceConfig = {
    Type = "oneshot";
    Environment = [ "BUN_INSTALL=$HOME/.bun" "PATH=$HOME/.bun/bin:/run/current-system/sw/bin" ];
  };
  script = ''
    gbrain embed --all --quiet || journalctl --user -u gbrain-embed --no-pager
  '';
};
```

### ADR-006 · MCP server: stdio local, NO HTTP

**Decisión:** Conectar OpenCode (y futuros coding agents) al brain vía `gbrain serve` (stdio).

```json
// fragmento a agregar en opencode.json (o equivalente del agente)
{
  "mcpServers": {
    "gbrain": {
      "command": "gbrain",
      "args": ["serve"]
    }
  }
}
```

**Razón:** Tu caso es personal, mismo host, sin agentes remotos. Stdio es:
- ✅ Una línea de config, cero surface de red, cero firewall.
- ✅ El `Type=notify` de gbrain lo deja disponible inmediatamente.
- ❌ NO exponemos HTTP. Si después querés abrirlo, es `gbrain serve --http` + bearer tokens + Tailscale-only.

### ADR-007 · Trust boundary respetada

**Crítico — leído del AGENTS.md del upstream:**
> "Three phase handlers (synthesize / patterns / consolidate) are PROTECTED — only trusted local callers can submit them; MCP cannot."

**Implicación:** El MCP server (con `remote=true`) **NO puede** disparar dream phases protegidas. Solo puede:
- `search`, `query`, `ask` — read-only.
- `embed` — refresh de embeddings locales.
- `think` — chat con retrieval (degradación aceptable si expansion falla).
- `list`, `get`, `tag`, `link`, `graph`, `timeline`, `history` — gestión ligera.

**No puede:**
- `dream --phase synthesize/patterns/consolidate/publish` — solo CLI local.
- `file_upload` con `remote=true` — se endurece la sandbox de filesystem.

**Operación:** El timer de §2.ADR-005 solo corre `embed`. Todo lo demás lo dispara el User manualmente desde shell. **Esto es intencional** — control humano sobre mutaciones pesadas.

---

## 3. Facts verified against repo / nixpkgs / upstream code

| Fact | Value | Source |
|---|---|---|
| gbrain versión actual | v0.42.51.0 | `gbrain --version` (real, output verificado) |
| `bun` en nixpkgs | requerido ≥1.3.10, nixpkgs trae 1.3.13 | `nix/packages/languages.nix` |
| gbrain MCP SDK | `@modelcontextprotocol/sdk@1.29.0` | `package.json` upstream |
| Recipe `minimax.ts` | solo touchpoint `embedding` (NO chat) | `src/core/ai/recipes/minimax.ts` |
| Recipe `litellm-proxy.ts` | "universal" + `LITELLM_BASE_URL` envvar | `src/core/ai/recipes/litellm-proxy.ts` |
| Recipe `ollama.ts` | `auth_env.required: []` (keyless) | `src/core/ai/recipes/ollama.ts` |
| AI SDK para openai-compat | `@ai-sdk/openai-compatible` import | `src/core/ai/gateway.ts:30` |
| `services.ollama` en nixpkgs | módulo NixOS oficial | nixpkgs.unstable |
| `ollama` versión en nixpkgs | 0.23.1 | `nix-instantiate --eval` |
| `litellm` versión en nixpkgs | 1.83.7 | `nix-instantiate --eval` |
| MiniMax chat endpoint (sub key) | `https://api.minimaxi.com/anthropic` (Anthropic-compat) | MiniMax doc oficial + example en `quickstart` |
| MiniMax embedding con sub key | ❌ invalida (status_code 2049) | empírico, curl real |
| MiniMax plan Plus cobertura | "开放平台上的所有模型" | `pricing-token-plan` doc oficial |
| OpenCode soporta Token Plan | ✅ listado oficialmente | MiniMax M3 page, tool grid |
| Trust boundary | `synthesize/patterns/consolidate` son PROTECTED, solo CLI local | upstream `AGENTS.md` + `CLAUDE.md` |

---

## 4. Design

### 4.1 Stack final

```
┌────────────────────────────────────────────────────────────┐
│ OpenCode (TUI/IDE)                                          │
│   └─ mcpServers.gbrain = { command: "gbrain", args:["serve"]} │
└────────────────────────────────────────────────────────────┘
                          │ stdio
                          ▼
┌────────────────────────────────────────────────────────────┐
│ gbrain v0.42.51.0  (Bun+TS, ~/bun/install/global/...)        │
│   ├─ src/mcp/server.ts  (tool router, 30+ tools)            │
│   ├─ src/core/ai/gateway.ts                                  │
│   └─ ~/.gbrain/  (PGLite DB, mutable, OUT of Nix store)      │
└────────────────────────────────────────────────────────────┘
        │                  │                  │
        │ embed            │ chat/expand      │
        ▼                  ▼                  ▼
┌──────────────┐  ┌─────────────────┐  ┌──────────────────┐
│ ollama serve │  │ LiteLLM proxy   │  │ (rerank = OFF)   │
│ :11434       │  │ :4000 (user)    │  │                  │
│ nomic-embed  │  │ MiniMax-M3 /    │  │                  │
│ -text (CPU)  │  │ M2.7-highspeed  │  │                  │
└──────────────┘  └─────────────────┘  └──────────────────┘
                          │ bearer (subscription key)
                          ▼
                https://api.minimaxi.com/anthropic
```

### 4.2 ollama (system service)

- `services.ollama.enable = true` en `nix/hosts/main/default.nix` → bindea `127.0.0.1:11434`, model dir en `/var/lib/ollama`, corre como `ollama` user.
- Modelo `nomic-embed-text` se descarga **en el primer `home.activation`** vía `ollama pull`. Esto evita un download en el rebuild (que tira el ISO si es muy grande) y lo hace idempotente.
- Aceleración: **NO forzamos GPU** (la detección de CUDA en NixOS dentro de containers a veces se cuelga). Default CPU. Si más adelante hay GPU, agregar `services.ollama.acceleration = "cuda";` (cuando sea compatible).

### 4.3 LiteLLM (user service)

- `home.packages = [ pkgs.litellm ];` agregado a `packages/ai.nix`.
- Config en `~/.config/litellm/config.yaml`, declarada vía `home.file` con `text = ''...''`.
- Servicio `litellm.service` declarado en `nix/hosts/main/home.nix` con `Type = "simple"`, `ExecStart = "litellm --config ~/.config/litellm/config.yaml --host 127.0.0.1 --port 4000"`.
- `Environment = "MINIMAX_API_KEY=..."` viene de **`~/.config/gbrain/secrets.env`** vía `EnvironmentFile=` (systemd lee archivos `KEY=VALUE` directamente).
- `WantedBy = "default.target"`.

### 4.4 gbrain: config + secrets

- `~/.config/gbrain/secrets.env` declarado en `home.activation` con `chmod 600`, contenido `MINIMAX_API_KEY=<subscription-key>`.
- `~/.gbrain/config.json` se crea **fuera de Nix** vía `gbrain config set` post-instalación. NO se symlinkea del repo (mutable, contiene modelado fino del brain).
- Comandos post-install (en home.activation, después de ollama pull y litellm UP):
  ```bash
  gbrain config set embedding_model ollama:nomic-embed-text
  gbrain config set chat_model anthropic:minimax-m3
  gbrain config set expansion_model anthropic:minimax-fast
  gbrain config set search.mode balanced
  ```

### 4.5 Scheduling

- `gbrain-embed.timer` cada 6h (ver §2.ADR-005).
- No drone sueño en v1. Documentado como follow-up.

### 4.6 MCP wiring

`~/.config/opencode/opencode.json` (gestionado por tu setup actual) — propuesta mínima (puede requerir autorización según permisos del editor):

```json
"mcpServers": {
  "gbrain": {
    "command": "gbrain",
    "args": ["serve"]
  }
}
```

A verificar en T9 qué archivo exactamente controla tu MCP wiring actual (algunos agentes usan `opencode.json`, otros `mcp.json`, otros el config global del editor).

### 4.7 Archivos del repo a modificar

| Path | Cambio | Razón |
|---|---|---|
| `nix/hosts/main/default.nix` | Importar `nix/modules/services-ollama.nix` (nuevo) o agregar `services.ollama.enable` directamente | Servicio de sistema para embedding |
| `nix/modules/services.nix` (opcional) | ¿Llevar ollama al módulo compartido? | **No por ahora**: otros hosts (`server`, `notebook`) no necesitan embedding. Si en el futuro el notebook también necesita, refactor. |
| `nix/modules/ai.nix` (nuevo) | Módulo con `home.packages`, `home.file` del config LiteLLM, `home.activation`, `systemd.user.services.litellm` | Encapsula todo lo AI-specific para reutilizar |
| `nix/packages/ai.nix` | Agregar `pkgs.ollama` y `pkgs.litellm` al `home.packages` | Bins disponibles en el PATH del user |
| `nix/hosts/main/home.nix` | Importar `nix/modules/ai.nix` | Activación en este host |
| `nix/hosts/main/home.nix` | Agregar `systemd.user.timers."gbrain-embed"` y `systemd.user.services."gbrain-embed"` | §4.5 |
| `nix/config/opencode/opencode.json` | Agregar `mcpServers.gbrain` | Wire MCP |
| `docs/gbrain.md` | (este archivo) | El SDD |

### 4.8 Archivos fuera del repo (mutable, en $HOME)

| Path | Quién lo crea | Notas |
|---|---|---|
| `~/.bun/install/global/node_modules/gbrain/` | `bun install -g github:garrytan/gbrain` (manual v1, declarado en `dependencies.md` del proyecto) | Auto-mutante |
| `~/.config/gbrain/secrets.env` | `home.activation` (text inline) | chmod 600 |
| `~/.config/litellm/config.yaml` | `home.file` (text inline, declarative) | Read-only por root, lectura user |
| `~/.gbrain/config.json` | `gbrain config set ...` (post-install) | Mutable |
| `~/.gbrain/` (PGLite) | `gbrain init --pglite` | DB local, mutable |

---

## 5. Implementation Plan — tareas verticales

Cada tarea es **verificable** (verde/rojo). Ninguna se asume implícita.

### T1 · `nix/packages/ai.nix`: agregar `ollama` y `litellm`

**Acción:**
```nix
home.packages = with pkgs; [
  claude-code opencode clingy engram codebase-memory-mcp
  gemini-cli antigravity-nix
  ollama                    # ← CLI client (no el server)
  litellm                   # ← CLI client
];
```

**Verificación:** `nix flake check` debe pasar. `home-manager build` debe incluir `ollama` y `litellm` en `$out/bin`.

### T2 · `nix/modules/ai.nix`: nuevo módulo

**Acción:** crear el archivo con:
- `home.file.".config/litellm/config.yaml".text = ''...''` (el yaml de §4.3)
- `home.activation.bootstrap-gbrain = config.lib.dag.entryAfter [ "writeBoundary" ] ''...''` script que:
  - `mkdir -p $HOME/.config/gbrain`
  - `chmod 700 $HOME/.config/gbrain`
  - `test -f $HOME/.config/gbrain/secrets.env || install -m 600 /dev/null $HOME/.config/gbrain/secrets.env` (placeholder)
  - Si ollama está disponible, intenta `ollama pull nomic-embed-text 2>/dev/null || true` (idempotente).
- `systemd.user.services.litellm = { ... };`

**Verificación:** `nix flake check`. Rebuild de main → `systemctl --user status litellm` → debe estar `active (running)`.

### T3 · `nix/hosts/main/default.nix`: habilitar ollama a nivel sistema

**Acción:**
```nix
services.ollama = {
  enable = true;
  host = "127.0.0.1";
  port = 11434;
  openFirewall = false;          # solo loopback
  home = "/var/lib/ollama";
  user = "ollama";
};
```

**Verificación:** `sudo systemctl status ollama` después del rebuild → `active (running)`. `curl http://127.0.0.1:11434/api/version` → JSON con versión.

### T4 · `nix/hosts/main/home.nix`: wire el módulo y el timer

**Acción:**
- `imports += [ ../../modules/ai.nix ];`
- Agregar `systemd.user.timers."gbrain-embed"` + `systemd.user.services."gbrain-embed"` del §2.ADR-005.

**Verificación:** `systemctl --user list-timers | grep gbrain`. `systemctl --user status gbrain-embed`.

### T5 · Aplicar el deploy

**Acción:**
```bash
sudo nixos-rebuild switch --flake .#main
```

**Verificación:** `nix flake check` retorna 0. `ollama --version`, `litellm --version`, `gbrain --version` responden. `systemctl --user status litellm` activo.

### T6 · Secrets y config de gbrain

**Acción (manual, **una sola vez**):**
```bash
# 1. Pegar la Subscription Key de MiniMax en el archivo (NO se commitea, NO va al repo)
echo 'MINIMAX_API_KEY="sk-xxx..."' > ~/.config/gbrain/secrets.env
chmod 600 ~/.config/gbrain/secrets.env

# 2. Setear modelos en gbrain (lee secrets.env si está exportado)
set -a; source ~/.config/gbrain/secrets.env; set +a
gbrain config set embedding_model ollama:nomic-embed-text
gbrain config set chat_model anthropic:minimax-m3
gbrain config set expansion_model anthropic:minimax-fast
gbrain config set search.mode balanced
```

⚠️ **Nota sobre `set -a`:** gbrain ya tiene precedencia env > config.json > db > defaults (ver §4.4 del `gbrain-notes.md`). Con `set -a` exportamos solo lo necesario para este sub-shell. **No dejamos MINIMAX_API_KEY en el environment global.**

**Verificación:** `gbrain doctor --json` → `embedding.ok=true`, `chat.ok=true`, `expansion.ok=true`.

### T7 · Init del brain + import

**Acción:**
```bash
gbrain init --pglite       # DB local en ~/.gbrain/brain.db, ~20ms
gbrain import <DIR>        # ← DIR es decisión del User, ver §9
```

`<DIR>` por defecto propuesto: `~/zettel-music-bak/` (existe). Alternativas candidatas: `~/the-grid/zettelkasten/`, otra carpeta. **Decisión del User en §9.**

**Verificación:** `gbrain list -n 5` muestra las primeras páginas importadas. `gbrain stats` reporta `embeddings_total > 0` después de unos segundos.

### T8 · Wire MCP a OpenCode

**Acción:** Editar el archivo de config MCP del editor principal. Investigar primero **cuál es** (T8a):
```bash
ls -la ~/.config/opencode/opencode.json ~/.config/opencode/mcp.json 2>/dev/null
```
Luego (T8b) agregar `mcpServers.gbrain = { command = "gbrain"; args = ["serve"]; }`.

**Verificación:** Reiniciar el editor. Comprobar que `gbrain` aparece como MCP server habilitado. Probar una tool (ej. `query "hola"` desde la UI).

### T9 · Verificación end-to-end

**Smoke test manual:**
```bash
# 9a. embedding rápido
echo "esto es un test" | curl http://127.0.0.1:11434/api/embeddings -d '{"model":"nomic-embed-text","prompt":"hola"}' | jq '.embedding | length'
# esperado: 768

# 9b. chat vía LiteLLM
curl http://127.0.0.1:4000/v1/chat/completions \
  -H "Authorization: Bearer dummy" \
  -d '{"model":"minimax-m3","messages":[{"role":"user","content":"respondeme OK"}]}' | jq '.choices[0].message.content'
# esperado: string corto, contiene "OK"

# 9c. gbrain end-to-end
gbrain query "qué es gbrain"
# esperado: respuesta basada en retrieval desde el brain
```

**Verde** si los 3 pasan. **Rojo** si alguno, ir a §7 (Riesgos).

---

## 6. Verification — criterios globales de éxito

| Capa | Comando | Esperado |
|---|---|---|
| Servicios | `systemctl is-active ollama litellm` (con `--user` para el segundo) | `active` ambos |
| Embedding | `ollama list` | `nomic-embed-text` listado |
| Chat | `curl 127.0.0.1:4000/v1/models` | JSON con `minimax-m3` y `minimax-fast` |
| gbrain ready | `gbrain doctor --json` | sin errores críticos |
| MCP wired | (UI del editor) | gbrain listado como MCP server |
| Persistencia | restart y rebuild → todo arriba | idempotente |

---

## 7. Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Mitigación |
|---|---|---|---|
| 1 | MiniMax changa el endpoint `/anthropic` (breaking) | Baja | LiteLLM proxy абстраи. Cambio = editar yaml + restart `litellm.service`. |
| 2 | `nomic-embed-text` no se descarga en home.activation (network blip) | Media | Script usa `\|\| true`. `gbrain doctor` lo reporta. Re-correr `ollama pull` manualmente. |
| 3 | Subscription Key excede quota (`status_code` distintos a 2049) | Media | Plan Plus = ¥49/mes. Monitorear vía web console. Si excede, fallback a ollama para `think` también (degraded mode). |
| 4 | `gbrain` rompe su schema en una migración futura | Baja-media | `gbrain apply-migrations --yes` corre on-demand. Backup de `~/.gbrain/` con timer antes (no incluido en v1). |
| 5 | LiteLLM drop_params incompatibility rompe algo de gbrain | Baja | smoke test T9b es el canary. Si falla, log de LiteLLM expone qué param. Whitelist via `litellm --drop_params false` + tuning manual. |
| 6 | MCP wiring difiere por agente (opencode.json vs .codex/config.toml vs ~/.claude.json) | Alta | T8a investigativo lo cubre. Es un punto de fricción conocido. |
| 7 | Drift entre `bun install -g` del upstream y `pkgs.bun` del nixpkgs | Baja | `bun` está en nixpkgs; gbrain se instala via `bun install -g` que usa `pkgs.bun`. Compatible. |

---

## 8. Out of scope (v2 candidates)

1. **Dream cycle timer** — `gbrain dream --phase synthesize` como cron semanal. Requiere tier-2 (deeper).
2. **Backup automatizado de `~/.gbrain/`** — `restic` o simple `tar.gz` con `systemd` timer a `/var/backups/`.
3. **HTTP MCP server** — si querés exponerlo a otro host (ej. `notebook` → `main`).
4. **`gbrain-advisor` weekly cron** — instalar la skill oficial + timer lunes 9 AM.
5. **`gbrain-upgrade` automation mode** — hoy default es `notify`. Si querés silent-auto, `gbrain config set self_upgrade.mode auto`.
6. **Brain en `~/the-grid/zettelkasten/` (syncthing-mesh)** — federar brains entre hosts (overkill para v1).

---

## 9. Open questions (UNA sola)

**¿Qué directorio inicial importamos en T7?**

Opciones viables que ya existen en tu `$HOME`:

| Candidato | Contenido probable | Tamaño esperado |
|---|---|---|
| `~/zettel-music-bak/` | notas musicales | chico, ideal v1 |
| `~/the-grid/zettelkasten/` | zettelkasten personal (sincronizado por syncthing con `server`) | medio |
| Una mezcla de ambos | — | configurable |
| Ninguno por ahora | brain vacío para laburar | cero |

**Recomendación v1:** arrancar solo con `~/zettel-music-bak/` (chico, sin riesgo de "contaminar" el brain con todo de golpe). Después expandir con `gbrain import` adicionales.

---

## Appendix A · Comandos completos en orden de ejecución

```bash
# === Despliegue del lado Nix (T1-T4-T5) ===
# Editar:
#   nix/packages/ai.nix          → +ollama +litellm
#   nix/modules/ai.nix           → NUEVO
#   nix/hosts/main/default.nix   → +services.ollama
#   nix/hosts/main/home.nix      → +modules/ai.nix +timer
sudo nixos-rebuild switch --flake .#main

# === Una vez al día cero (T6) ===
echo 'MINIMAX_API_KEY="sk-xxx..REEMPLAZAR.."' > ~/.config/gbrain/secrets.env
chmod 600 ~/.config/gbrain/secrets.env

set -a; source ~/.config/gbrain/secrets.env; set +a
gbrain config set embedding_model ollama:nomic-embed-text
gbrain config set chat_model anthropic:minimax-m3
gbrain config set expansion_model anthropic:minimax-fast
gbrain config set search.mode balanced
gbrain doctor --json

# === T7 ===
gbrain init --pglite
gbrain import ~/zettel-music-bak/   # ← decisión §9

# === T8 ===
# editar opencode.json (ver T8a para localizar)

# === T9 ===
echo "smoke tests" # ver §5
```

## Appendix B · Estructura final del repo (post-implementación)

```
the-tower/
├── nix/
│   ├── packages/ai.nix           (modificado: +ollama +litellm)
│   ├── modules/
│   │   ├── ai.nix                (NUEVO)
│   │   └── ...
│   ├── hosts/main/
│   │   ├── default.nix           (modificado: +services.ollama)
│   │   └── home.nix              (modificado: +modules/ai.nix +timer)
│   └── ...
├── docs/
│   ├── gbrain.md                 (NUEVO — este SDD)
│   ├── server-htpc-migration.md
│   ├── syncthing-sync.md
│   └── ...
└── gbrain-notes.md               (BORRAR — fue temporal)
```

## Appendix C · Referencias upstream (links) actualizados al 2026-07-08

- gbrain repo: github.com/garrytan/gbrain
- gbrain recipes: `src/core/ai/recipes/*.ts`
- gbrain MCP: `@modelcontextprotocol/sdk@1.29.0`, `src/mcp/server.ts`
- Trust boundary: `src/core/operations.ts`, mencionado en `AGENTS.md`
- LiteLLM upstream: github.com/BerriAI/litellm (v1.83.7)
- MiniMax API quickstart: platform.minimaxi.com/docs/token-plan/quickstart
