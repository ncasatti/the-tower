# TaskNotes v2 — Zettelkasten Task Management

Sistema de gestión de tareas basado en notas Markdown con indexación de frontmatter YAML. Totalmente integrado con Telescope para búsquedas relacionales y compatible con el flujo de Obsidian.

## 1. ¿Cómo funciona?

TaskNotes v2 escanea tu vault (~716 archivos) y construye un **índice invertido en memoria**. Esto permite realizar búsquedas por cualquier propiedad del frontmatter (status, tags, projects, etc.) de forma instantánea.

- **Caché:** TTL de 30s con refresco incremental (solo re-parsea archivos modificados).
- **Búsqueda Multi-etapa:** Seleccionas una Llave → Seleccionas un Valor → Eliges el Archivo (con preview).
- **Gestión:** Comandos rápidos para ciclar estados, prioridades y fechas sin salir de Neovim.

---

## 2. Atajos de Teclado (Keybindings)

### Búsqueda Zettelkasten (`<leader>oz`)
| Key | Acción | Descripción |
|-----|--------|-------------|
| `t` | **Search** | Búsqueda Maestra (Key → Value → File) |
| `#` | **Tags** | Filtrado rápido por etiquetas |
| `s` | **Status** | Filtrado rápido por estado |
| `o` | **Projects** | Filtrado rápido por proyectos |
| `r` | **Refresh** | Forzar reconstrucción de la caché |

### Gestión de Tareas (`<leader>ow`)
| Key | Acción | Descripción |
|-----|--------|-------------|
| `n` | **New** | Crear nueva tarea con título |
| `s` | **Status** | Ciclar estado (open → in-progress → done...) |
| `p` | **Priority** | Ciclar prioridad (low → normal → high) |
| `c*` | **Context** | Añadir contexto (`w`: work, `f`: freelance, `s`: study, `c`: custom) |
| `d*` | **Date** | Programar (`t`: today, `m`: tomorrow, `w`: week, `d`: custom) |
| `vf` | **Find All** | Ver todas las tareas en Telescope |
| `v*` | **Views** | Vistas rápidas (`i`: inbox, `t`: todo, `w`: work, `l`: freelance, `d`: done) |
| `q*` | **Queries** | Consultas (`q`: custom, `h`: high-priority, `t`: today, `o`: overdue) |

---

## 3. Formato de Archivo
Las tareas son archivos `.md` en `TaskNotes/Tasks/` con el siguiente frontmatter:

```yaml
---
status: open
priority: normal
scheduled: 2026-03-30
tags:
  - task
contexts:
  - work
dateCreated: 2026-03-30T12:00:00-03:00
dateModified: 2026-03-30T12:00:00-03:00
---
```

*Nota: Al marcar una tarea como `done`, se añade automáticamente el campo `completedDate`.*
