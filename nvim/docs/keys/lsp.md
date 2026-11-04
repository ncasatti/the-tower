# LSP

Buffer-local on LSP attach. Snacks pickers used for symbols/references.

## HCL (`.tf`, `.tfvars`, `.hcl`)

Neovim detects three filetypes: `.tf` → `terraform`, `.tfvars` → `terraform-vars`,
`.hcl` → `hcl`. Two different tools cover them.

- **Server** — `terraform-ls` (HashiCorp), configured in
  `lua/plugins/lsp/servers/hcl.lua`. Works without the `terraform` binary;
  provider-backed completion needs `terraform` or `tofu` installed.
  It implements the `terraform` and `terraform-vars` language ids **only** —
  registering the generic `hcl` filetype makes the client attach with
  `languageId=hcl` and every request fail with "no feature found for
  language hcl". Generic `.hcl` (Packer, Vault, Consul, Nomad) therefore has
  no LSP; there is no mason server for generic HCL.
  Two names are in play: mason's `ensure_installed` wants the lspconfig
  server name `terraformls` (the mason package is `terraform-ls`), while
  `vim.lsp.config`/`vim.lsp.enable` use our own name `terraform_ls`.
  `terraformls` is excluded from mason-lspconfig's `automatic_enable` —
  otherwise the builtin from nvim-lspconfig's runtimepath attaches too,
  giving two clients on the same binary and duplicated diagnostics.
- **Outline** — `<leader>ss` lists the file's blocks as a flat index:
  `variable "region"`, `resource "aws_instance" "web"`, `module "vpc"`,
  `output "public_ip"`. This is the same picker markdown uses for headings.
  Available in `.tf` and `.tfvars`.
- **Format** — `<leader>ll` runs conform with the builtin `hcl` formatter,
  which shells out to the `hclfmt` binary (hashicorp/hcl). conform resolves
  formatters by **module name**, not binary name — the entry is `"hcl"` while
  the binary is `hclfmt`. `terraform-ls` does not implement
  `textDocument/formatting`, so conform is the only formatting path.
  Unlike the LSP, this covers all three filetypes including generic `.hcl`.

## Navigation

- `gd` — Goto definition (Snacks picker)
- `gD` — Goto declaration
- `gr` — Goto references (Snacks picker)
- `gI` — Goto implementation
- `gy` — Goto type definition (Snacks picker)
- `K` — Hover documentation
- `<C-k>` — Signature help

## Actions

- `<leader>rn` — Rename symbol
- `<leader>ca` — Code action
- `<leader>D` — Type definition
- `<leader>ll` — Format buffer (Conform; also visual selection)
- `<leader>lf` — Toggle format on save

## Symbols

- `<leader>ds` — Document symbols (Snacks)
- `<leader>ws` — Workspace symbols (Snacks)
- `<leader>ss` — LSP symbols picker
- `<leader>sS` — LSP workspace symbols picker

## Diagnostics

- `[d` / `]d` — Previous / next diagnostic
- `<leader>le` — Diagnostic float
- `<leader>lq` — Send diagnostics to loclist

## Workspace folders

- `<leader>lwa` — Add folder
- `<leader>lwr` — Remove folder
- `<leader>lwl` — List folders
