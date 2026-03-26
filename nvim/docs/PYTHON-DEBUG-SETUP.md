# Python Debugging Setup - Testing Guide

## Parte 1: DAP Python (COMPLETADA)

### Qué se instaló:

1. **nvim-dap-python**: Plugin que conecta nvim-dap con debugpy
2. **mason-tool-installer**: Auto-instala debugpy y otras herramientas Python
3. **Configuraciones de debug**: 6 configuraciones predefinidas

### Archivos creados:

- `lua/plugins/debug/dap-python.lua` - Configuración de debugging Python
- `lua/plugins/lsp/mason-tools.lua` - Auto-instalador de debugpy, black, isort, etc.

### Configuraciones de debug disponibles:

1. **Launch file**: Corre el archivo actual
2. **Launch file with arguments**: Corre con argumentos que te pregunta
3. **Launch module**: Corre un módulo Python (ej: `-m pytest`)
4. **Attach remote**: Se conecta a un debugger remoto
5. **Django**: Corre servidor Django
6. **Flask**: Corre servidor Flask

### Detección automática de virtualenv:

El setup detecta automáticamente tu Python en este orden:
1. `./venv/bin/python` (virtualenv en proyecto)
2. `./.venv/bin/python` (virtualenv oculto)
3. `~/.virtualenvs/nvim/bin/python` (virtualenv global)
4. `/usr/bin/python3` (fallback sistema)

---

## Testing - Paso a Paso

### 1. Reiniciar Neovim e instalar plugins

```bash
# Cierra nvim si está abierto
# Abre nvim en el directorio de test
cd /tmp/nvim-python-test
nvim test_debug.py
```

Dentro de nvim:
```vim
:Lazy sync          " Sincroniza plugins
:MasonInstall debugpy black isort pylint mypy  " Instala herramientas Python
:checkhealth dap    " Verifica que DAP esté funcionando
```

### 2. Probar debugging básico

**Con el archivo `test_debug.py` abierto:**

1. **Poner breakpoint en línea 15** (dentro del loop for):
   - Mover cursor a línea 15: `15gg`
   - Presionar `F9` o `<leader>db`
   - Deberías ver el icono 🔴 en el gutter

2. **Iniciar debug**:
   - Presionar `F5` o `<leader>dc`
   - Debería abrirse el DAP UI (panel izquierdo con variables, panel inferior con consola)
   - El cursor debería parar en línea 15

3. **Navegar por el código**:
   - `F10` - Step over (ejecuta línea actual)
   - `F11` - Step into (entra en función)
   - `F12` - Step out (sale de función)
   - `F5` - Continue (continúa hasta próximo breakpoint)

4. **Inspeccionar variables**:
   - Mover cursor sobre variable `fib` y presionar `<leader>de` (evaluar expresión)
   - O ver el panel izquierdo "Scopes" que muestra todas las variables locales
   - Deberías ver cómo `fib` va creciendo en cada iteración

5. **Terminar debug**:
   - `<leader>dt` - Termina debug
   - O presionar `F5` hasta que termine el script

### 3. Probar breakpoint condicional

1. Borrar breakpoint anterior: cursor en línea 15, `F9`
2. Poner breakpoint condicional en línea 15:
   - `<leader>dB` (B mayúscula)
   - Ingresar condición: `i == 5`
   - Presionar Enter
3. Iniciar debug con `F5`
4. Debería parar SOLO cuando `i` sea igual a 5

### 4. Probar ejecución con argumentos

1. Modificar el script para aceptar argumentos (opcional)
2. Presionar `<leader>dc` para ver selector de configuraciones
3. Elegir "Launch file with arguments"
4. Ingresar argumentos cuando te pregunte

### 5. Keybindings de debugging Python

**Keybindings globales (disponibles siempre):**
- `F5` - Continue/Start debug
- `F6` - Pause
- `F9` - Toggle breakpoint
- `F10` - Step over
- `F11` - Step into
- `F12` - Step out
- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Conditional breakpoint
- `<leader>dc` - Continue
- `<leader>dC` - Run to cursor
- `<leader>di` - Step into
- `<leader>do` - Step over
- `<leader>dO` - Step out
- `<leader>dr` - Toggle REPL
- `<leader>dl` - Run last configuration
- `<leader>dt` - Terminate debug
- `<leader>du` - Toggle DAP UI
- `<leader>de` - Evaluate expression (normal/visual)
- `<leader>dh` - Hover variables
- `<leader>dp` - Preview

**Keybindings Python-específicos (solo en archivos .py):**
- `<leader>dtn` - Debug test method (cuando tengas pytest)
- `<leader>dtc` - Debug test class (cuando tengas pytest)
- `<leader>ds` - Debug selection (en visual mode, ejecuta código seleccionado)

---

## Troubleshooting

### Si debugpy no se instala automáticamente:

```vim
:MasonInstall debugpy
```

O manualmente con pip:
```bash
pip install debugpy
```

### Si no aparece el DAP UI:

```vim
<leader>du    " Toggle DAP UI manualmente
```

### Si no detecta tu virtualenv:

Edita `lua/plugins/debug/dap-python.lua` y hardcodea tu path:
```lua
dap_python.setup("/ruta/a/tu/venv/bin/python")
```

### Verificar que todo funcione:

```vim
:checkhealth dap
:lua print(vim.inspect(require('dap').configurations.python))
```

---

---

## Parte 2: Neotest (Test Runner) - COMPLETADA

### Qué se instaló:

1. **neotest**: Framework de testing para Neovim
2. **neotest-python**: Adapter para pytest/unittest
3. **Keybindings de testing**: Shortcuts para correr y debuggear tests

### Archivos creados:

- `lua/plugins/testing/neotest.lua` - Configuración de Neotest
- `/tmp/nvim-python-test/test_ejemplo.py` - Archivo de test de ejemplo

### Testing - Paso a Paso

**Con el archivo `test_ejemplo.py` abierto:**

1. **Reiniciar nvim e instalar plugins**:
   ```bash
   cd /tmp/nvim-python-test
   nvim test_ejemplo.py
   ```
   
   Dentro de nvim:
   ```vim
   :Lazy sync
   ```

2. **Correr un test específico**:
   - Mover cursor a `test_suma_positivos` (línea 25)
   - Presionar `<leader>Tr` (Test run nearest) - **Shift + Espacio + T + r**
   - Deberías ver el icono ✓ en el gutter si pasa

3. **Correr todos los tests del archivo**:
   - `<leader>Tf` (Test file)
   - Esperar a que corran todos los tests
   - Ver iconos en gutter: ✓ (pasó), ✗ (falló), ○ (skipped)

4. **Ver output de test fallido**:
   - Mover cursor a `test_fallido_intencional` (línea 59)
   - `<leader>Tr` para correrlo
   - Debería fallar (✗ en gutter)
   - `<leader>To` (Test output) para ver el mensaje de error

5. **Debuggear un test**:
   - Poner breakpoint (`F9`) en línea 60 (dentro de `test_fallido_intencional`)
   - Cursor en `test_fallido_intencional`
   - `<leader>Td` (Test debug)
   - Debería abrir DAP UI y parar en el breakpoint
   - Usar `F10`/`F11` para navegar

6. **Ver summary de todos los tests**:
   - `<leader>TS` (Test Summary)
   - Abre panel lateral con árbol de tests
   - Navegá con `u`/`n` (prev/next failed)
   - `r` sobre un test para correrlo
   - `d` sobre un test para debuggearlo

7. **Watch mode (auto-run al guardar)**:
   - `<leader>Tw` (Test watch)
   - Modificá un test y guardá (`:w`)
   - Debería auto-ejecutar los tests del archivo

### Keybindings de Testing (solo en archivos Python)

**IMPORTANTE**: Los keybindings usan `<leader>T` (T mayúscula) para evitar conflictos con búsqueda de archivos.

**Ejecutar tests:**
- `<leader>Tr` - Run nearest test (test bajo cursor)
- `<leader>Tf` - Run file (todos los tests del archivo)
- `<leader>Ta` - Run all (todos los tests del proyecto)
- `<leader>Tl` - Run last (repetir último test)
- `<leader>Ts` - Stop (detener tests en ejecución)

**Debugging:**
- `<leader>Td` - Debug nearest test (debuggea test bajo cursor)

**UI:**
- `<leader>To` - Show output (output del test bajo cursor)
- `<leader>TO` - Toggle output panel (panel con output de todos)
- `<leader>TS` - Toggle summary (árbol de tests)

**Navegación:**
- `[T` - Jump to previous failed test
- `]T` - Jump to next failed test

**Watch mode:**
- `<leader>Tw` - Toggle watch (auto-run al guardar)

### Integración con DAP

Cuando usás `<leader>Td` (debug test):
1. Neotest configura el test para correr con debugpy
2. Respeta los breakpoints que hayas puesto
3. Abre DAP UI automáticamente
4. Podés usar todos los comandos de debug (`F5`, `F10`, `F11`, etc.)

---

## Parte 3: REPL e Integración Jupyter - COMPLETADA

### Qué se instaló:

1. **iron.nvim**: REPL interactivo para Python/iPython
2. **pyworks.nvim**: Integración Jupyter (Molten + Jupytext + Image.nvim)
3. **Keybindings separados**: `<leader>r*` para REPL, `<leader>m*` para Molten

### Archivos creados/modificados:

- `lua/plugins/python/iron.lua` - Configuración de REPL
- `lua/plugins/python/pyworks.lua` - Configuración de Jupyter/Molten
- `docs/PYTHON-KEYBINDINGS.md` - Referencia completa de keybindings

### Prerequisites:

**Para Iron.nvim (REPL):**
```bash
sudo pacman -S ipython  # Recomendado
# Fallback: usa python3 (ya configurado)
```

**Para Molten (Jupyter):**
```bash
pip install jupyter pynvim jupyter-client
# Opcional para visualizaciones:
pip install matplotlib cairosvg plotly
```

### Testing - REPL (Iron.nvim)

**IMPORTANTE: Primero instalá ipython ejecutando en terminal:**
```bash
sudo pacman -S ipython
```

Luego en nvim:

1. **Abrir archivo Python y crear REPL**:
   ```bash
   cd /tmp/nvim-python-test
   nvim test_debug.py
   ```
   
   Dentro de nvim:
   ```vim
   <leader>rs  " Start REPL (abre iPython en split derecho)
   ```

2. **Enviar código al REPL**:
   - `<leader>rF` → Envía todo el archivo
   - Seleccioná líneas 4-17 (función fibonacci) en visual mode
   - `<leader>rS` → Envía la selección
   - En REPL verás la función definida

3. **Probar código interactivamente**:
   - En REPL escribí: `calcular_fibonacci(10)`
   - Deberías ver el resultado inmediato

---

## Próximos pasos

✅ **Parte 1: DAP Python** - COMPLETADA
✅ **Parte 2: Neotest** - COMPLETADA
✅ **Parte 3: REPL/Jupyter** - COMPLETADA

**Referencia rápida:** Ver `docs/PYTHON-KEYBINDINGS.md` para todos los shortcuts.

**Próximas mejoras opcionales:**
- Formatters (black, isort) - Ya instalados con Mason
- Type checking (mypy)
- Snippets personalizados

**Acción requerida:** 
1. Instalá ipython: `sudo pacman -S ipython`
2. Reiniciá nvim: `:Lazy sync`
3. Probá REPL con `<leader>rs` en archivo Python
