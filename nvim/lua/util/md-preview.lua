-- nvim/lua/util/md-preview.lua
-- Pandoc → PDF live preview for markdown buffers (LaTeX math supported).
-- Toolchain: pandoc → pdflatex → zathura. Recompile on save.

local M = {}

-- bufnr → { pdf_path, autocmd_id }
local state = {}

local function compile(bufnr, on_success)
  local src = vim.api.nvim_buf_get_name(bufnr)
  if src == "" or not src:match("%.md$") then
    vim.notify("md-preview: not a .md buffer", vim.log.levels.WARN)
    return
  end

  local pdf = "/tmp/md-preview-" .. vim.fn.fnamemodify(src, ":t:r") .. ".pdf"
  local stderr_lines = {}

  vim.fn.jobstart({
    "pandoc", src,
    "-o", pdf,
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
          if on_success then on_success(pdf) end
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

function M.preview()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Already active for this buffer? Just recompile (zathura already open).
  if state[bufnr] then
    compile(bufnr)
    return
  end

  compile(bufnr, function(pdf)
    -- Detached zathura — doesn't block nvim, survives nvim exit.
    vim.fn.jobstart({ "zathura", pdf }, { detach = true })

    local autocmd_id = vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = bufnr,
      callback = function() compile(bufnr) end,
      desc = "md-preview: recompile on save",
    })

    state[bufnr] = { pdf = pdf, autocmd_id = autocmd_id }
    vim.notify("md-preview: started → " .. pdf, vim.log.levels.INFO)
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
