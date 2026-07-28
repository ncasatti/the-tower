# Pyworks/Molten - Guía Completa

Pyworks es un meta-plugin que integra **Molten** (ejecución de código estilo Jupyter) + **Jupytext** (conversión de notebooks) + **Image.nvim** (visualización inline).

---

## 🎯 ¿Qué hace Pyworks/Molten?

**Molten** te permite trabajar con archivos Python normales (`.py`) como si fueran Jupyter Notebooks:

- ✅ Ejecutar bloques de código (celdas) y ver el output **inline** en nvim
- ✅ Mantener un kernel de Python en ejecución (como Jupyter)
- ✅ Ver gráficos de matplotlib/plotly **dentro de nvim** (si usás Kitty terminal)
- ✅ Trabajar con variables persistentes entre ejecuciones
- ✅ Convertir notebooks `.ipynb` a `.py` y viceversa (con Jupytext)

**DIFERENCIA con Iron.nvim:**
- **Iron.nvim**: REPL tradicional, envías código → ves output en terminal
- **Molten**: Output inline en el mismo buffer, kernel persistente, visualizaciones

---

## 📦 Prerequisites (IMPORTANTE)

Ya instalaste lo básico con pacman, pero para funcionalidad completa:

```bash
# Básico (ya instalado)
sudo pacman -S python-pynvim python-jupyter-client python-jupyter_core

# Para visualizaciones (opcional pero recomendado para Data Science)
pip install --user matplotlib numpy pandas plotly ipython
```

**NOTA**: Pyworks funciona mejor en **Kitty terminal** (que ya usás) para mostrar imágenes inline.

---

## 🚀 Workflow básico: Python como Notebook

### 1. Crear "celdas" en archivo Python

Molten reconoce celdas con comentarios especiales:

```python
# %%
# Esta es una celda - similar a Jupyter
import numpy as np
import matplotlib.pyplot as plt

datos = np.random.randn(100)
print(f"Media: {datos.mean():.2f}")
print(f"Desviación: {datos.std():.2f}")

# %%
# Otra celda - las variables persisten
plt.hist(datos, bins=20)
plt.title("Distribución de datos aleatorios")
plt.show()

# %%
# Celda 3
resultado = datos.sum()
print(f"Suma total: {resultado}")
```

**Importante**: El separador `# %%` define celdas (como Jupyter).

### 2. Inicializar Kernel

Abrí el archivo Python y ejecutá:

```vim
<leader>mi    " Molten Init
```

Te va a preguntar qué kernel usar:
- Elegí `python3` (o el nombre de tu virtualenv si tenés uno activo)

**Verás un mensaje**: `Molten kernel initialized: python3`

### 3. Ejecutar Celdas

**Método 1: Ejecutar celda actual**

- Poné el cursor en cualquier línea de una celda
- `<leader>mc` (Molten re-evaluate Cell)
- El output aparece **inline** debajo de la celda

**Método 2: Ejecutar selección**

- Seleccioná código en visual mode
- `<leader>me` (Molten Evaluate)
- Solo ejecuta lo seleccionado

**Método 3: Ejecutar línea**

- `<leader>ml` (Molten evaluate Line)

### 4. Ver/Ocultar Output

```vim
<leader>mk    " Molten show output (si está oculto)
<leader>mh    " Molten hide output (ocultar)
```

### 5. Navegar entre Celdas

```vim
]m    " Next cell (siguiente celda)
[m    " Previous cell (celda anterior)
```

### 6. Limpiar/Resetear

```vim
<leader>md    " Molten Delete output de celda actual
<leader>mx    " Molten interrupt execution (si se colgó)
<leader>mD    " Molten Deinit (cerrar kernel)
```

---

## 📊 Ejemplo Completo: Data Science

Creá un archivo `analisis.py`:

```python
# %%
# Importar librerías
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

print("Librerías cargadas")

# %%
# Generar datos
np.random.seed(42)
df = pd.DataFrame({
    'A': np.random.randn(100),
    'B': np.random.randn(100) * 2,
    'C': np.random.randint(0, 10, 100)
})

print(df.head())
print(f"\nShape: {df.shape}")

# %%
# Estadísticas descriptivas
print(df.describe())

# %%
# Visualización
fig, axes = plt.subplots(1, 2, figsize=(12, 4))

axes[0].scatter(df['A'], df['B'], alpha=0.5)
axes[0].set_title('A vs B')
axes[0].set_xlabel('A')
axes[0].set_ylabel('B')

axes[1].hist(df['C'], bins=10, edgecolor='black')
axes[1].set_title('Distribución de C')
axes[1].set_xlabel('Valor')
axes[1].set_ylabel('Frecuencia')

plt.tight_layout()
plt.show()

# %%
# Correlación
correlacion = df[['A', 'B']].corr()
print("Matriz de correlación:")
print(correlacion)
```

**Workflow:**

1. Abrí el archivo: `nvim analisis.py`
2. `<leader>mi` → Elegí `python3`
3. Cursor en primera celda → `<leader>mc`
4. Navegá a siguiente celda: `]m`
5. Ejecutá: `<leader>mc`
6. Repetí para cada celda

**Resultado**: Vas a ver el output de cada celda inline, incluyendo el gráfico si tenés matplotlib configurado.

---

## 🔄 Jupytext: Conversión de Notebooks

Jupytext te permite trabajar con notebooks `.ipynb` como archivos `.py` normales.

### Abrir un `.ipynb` existente

```bash
nvim notebook.ipynb
```

Jupytext **automáticamente** lo convierte a formato Python con celdas `# %%`. Cuando guardás (`:w`), sincroniza con el `.ipynb`.

### Crear notebook desde `.py`

Si tenés un archivo con celdas `# %%`:

```vim
:w notebook.py
```

Jupytext detecta las celdas y crea `notebook.ipynb` automáticamente.

---

## ⚙️ Keybindings - Resumen Rápido

### Kernel Management
- `<leader>mi` - Initialize kernel
- `<leader>mD` - Deinitialize kernel

### Ejecutar Código
- `<leader>ml` - Evaluate line
- `<leader>me` - Evaluate selection (visual mode)
- `<leader>mc` - Re-evaluate cell

### Output
- `<leader>mk` - Show output
- `<leader>mh` - Hide output
- `<leader>md` - Delete cell output

### Navegación
- `]m` - Next cell
- `[m` - Previous cell

### Control
- `<leader>mx` - Interrupt execution

---

## 🆚 Cuándo Usar Qué

| Situación | Herramienta | Por qué |
|-----------|-------------|---------|
| Script simple, probás funciones rápido | **Iron.nvim** (`<leader>rs`) | Más rápido, menos overhead |
| Análisis exploratorio de datos | **Molten** (`<leader>mi`) | Variables persisten, output inline |
| Gráficos/visualizaciones | **Molten** | Ves imágenes en nvim (Kitty) |
| Debugging paso a paso | **DAP** (`F5`) | Breakpoints, inspección |
| Tests unitarios | **Neotest** (`<leader>Tr`) | Ver resultados inline |
| Compartir análisis | **Molten + Jupytext** | Generás `.ipynb` para compartir |

---

## 🐛 Troubleshooting

### "No kernel found"
```vim
<leader>mi    " Re-inicializar kernel
```
Elegí `python3` o tu virtualenv.

### "Output no aparece"
```vim
<leader>mk    " Force show output
```

### "Kernel se colgó"
```vim
<leader>mx    " Interrupt
<leader>mD    " Deinit
<leader>mi    " Re-init
```

### "No veo imágenes de matplotlib"
- Asegurate de usar **Kitty terminal**
- Instalá: `pip install --user matplotlib pillow`
- En tu código: `plt.show()` debería renderizar inline

### "Jupytext no convierte .ipynb"
Verificá que instalaste:
```bash
pip install --user jupytext
```

---

## 🎓 Próximos Pasos

1. **Probá el ejemplo de Data Science** de arriba
2. **Experimentá con visualizaciones** (matplotlib/plotly)
3. **Convertí un notebook existente** (si tenés alguno)
4. **Combiná con Iron.nvim**: Molten para análisis, Iron para REPL rápido

---

## 📚 Más Info

- [Molten Docs](https://github.com/benlubas/molten-nvim)
- [Jupytext Docs](https://github.com/GCBallesteros/jupytext.nvim)
- [Image.nvim](https://github.com/3rd/image.nvim)
