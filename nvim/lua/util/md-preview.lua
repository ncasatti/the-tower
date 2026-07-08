-- nvim/lua/util/md-preview.lua
-- Pandoc → PDF for markdown buffers (LaTeX math supported).
-- Toolchain: pandoc → pdflatex → zathura. Recompile on save (preview only).
--
-- Two entry points:
--   preview() — write to /tmp/md-preview-<basename>.pdf, open in zathura,
--               wire BufWritePost to recompile. Toggled via stop().
--   export()  — write <basename>.pdf next to the .md source, no viewer, no
--               autocmd. One-shot build.

local M = {}

-- bufnr → { pdf_path, autocmd_id }
local state = {}

-- Validate buffer is a saved .md. Returns the absolute source path or nil
-- (with a user-facing WARN) if not.
local function src_path(bufnr)
  local src = vim.api.nvim_buf_get_name(bufnr)
  if src == "" or not src:match("%.md$") then
    vim.notify("md-preview: not a .md buffer", vim.log.levels.WARN)
    return nil
  end
  return src
end

-- Pure I/O: run pandoc, notify on success via on_success(pdf_path).
-- on_success is nil-safe; passing nil means "compile and forget".
local function compile(bufnr, pdf_path, on_success)
  local src = assert(src_path(bufnr))
  local stderr_lines = {}

  vim.fn.jobstart({
    "pandoc", src,
    "-o", pdf_path,
    "--pdf-engine=pdflatex",
    "--standalone",
    "-V", "geometry:margin=2cm",
    "-V", "linkcolor:blue",
  }, {
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stderr_lines, line) end
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          if on_success then on_success(pdf_path) end
        else
          local msg = "md-preview: pandoc exit " .. code
          if #stderr_lines > 0 then
            msg = msg .. "\n" .. table.concat(stderr_lines, "\n")
          end
          vim.notify(msg, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

local function preview_path(src)
  return "/tmp/md-preview-" .. vim.fn.fnamemodify(src, ":t:r") .. ".pdf"
end

local function export_path(src)
  return vim.fn.fnamemodify(src, ":p:h") .. "/" .. vim.fn.fnamemodify(src, ":t:r") .. ".pdf"
end

function M.preview()
  local bufnr = vim.api.nvim_get_current_buf()
  local src = src_path(bufnr)
  if not src then return end

  -- Already active for this buffer? Just recompile (zathura already open).
  if state[bufnr] then
    compile(bufnr, preview_path(src))
    return
  end

  local pdf = preview_path(src)
  compile(bufnr, pdf, function(out)
    -- Detached zathura — doesn't block nvim, survives nvim exit.
    vim.fn.jobstart({ "zathura", out }, { detach = true })

    local autocmd_id = vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = bufnr,
      -- Re-derive src each save so a `:w newpath.md` keeps compiling to the
      -- matching preview file.
      callback = function()
        compile(bufnr, preview_path(vim.api.nvim_buf_get_name(bufnr)))
      end,
      desc = "md-preview: recompile on save",
    })

    state[bufnr] = { pdf = out, autocmd_id = autocmd_id }
    vim.notify("md-preview: started → " .. out, vim.log.levels.INFO)
  end)
end

function M.export()
  local bufnr = vim.api.nvim_get_current_buf()
  local src = src_path(bufnr)
  if not src then return end

  local pdf = export_path(src)
  compile(bufnr, pdf, function(out)
    vim.notify("md-preview: exported → " .. out, vim.log.levels.INFO)
  end)
end

function M.stop()
  local bufnr = vim.api.nvim_get_current_buf()
  local s = state[bufnr]
  if not s then
    vim.notify("md-preview: not active for this buffer", vim.log.levels.WARN)
    return
  end
  pcall(vim.api.nvim_del_autocmd, s.autocmd_id)
  state[bufnr] = nil
  vim.notify("md-preview: stopped", vim.log.levels.INFO)
end

return M