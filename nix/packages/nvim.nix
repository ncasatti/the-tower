# nix/packages/nvim.nix
# Neovim with pre-compiled Treesitter parsers via Home Manager
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    withRuby = false;
    withPython3 = false;
    # Add Treesitter with all required grammars to Neovim's runtimepath
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: with p; [
        tree-sitter-vim
        tree-sitter-lua
        tree-sitter-vimdoc
        tree-sitter-javascript
        tree-sitter-typescript
        tree-sitter-html
        tree-sitter-css
        tree-sitter-go
        tree-sitter-bash
        tree-sitter-fish
        tree-sitter-nix
        tree-sitter-python
        tree-sitter-java
        tree-sitter-kotlin
        tree-sitter-json
        tree-sitter-yaml
        tree-sitter-toml
        tree-sitter-markdown
        tree-sitter-markdown-inline
        tree-sitter-latex
        tree-sitter-sql
        # HCL. Not in pkgs.vimPlugins.nvim-treesitter-parsers (it only carries
        # the officially supported languages), but the grammar exists in
        # nixpkgs' tree-sitter-grammars and `withPlugins` accepts it. Needed for
        # the <leader>ss outline in .hcl files, which have no LSP.
        tree-sitter-grammars.tree-sitter-hcl
      ]))
    ];
  };

  home.packages = with pkgs; [
    tree-sitter
    python3Packages.pylatexenc
    pandoc
  ];
}
