# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
    nixCats.inputs.flake-utils.follows = "flake-utils";
    "plugins-hlargs" = {
      url = "github:m-demare/hlargs.nvim";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nixCats,
    ...
  } @ inputs: let
    inherit (nixCats) utils;
    luaPath = "${./.}";
    forEachSystem = flake-utils.lib.eachSystem flake-utils.lib.allSystems;
    extra_pkg_config = {
      # allowUnfree = true;
    };
    system_resolved = forEachSystem (system: let
      standardPluginOverlay = utils.standardPluginOverlay;
      dependencyOverlays =
        (import ./overlays inputs)
        ++ [
          (standardPluginOverlay inputs)
        ];
    in {inherit dependencyOverlays;});
    inherit (system_resolved) dependencyOverlays;
    categoryDefinitions = {
      pkgs,
      settings,
      categories,
      name,
      ...
    } @ packageDef: {
      propagatedBuildInputs = {
        generalBuildInputs = with pkgs; [
        ];
      };
      lspsAndRuntimeDeps = {
        general = with pkgs; [
          universal-ctags
          ripgrep
          fd
          zig # here as a c compiler
        ];
        csharpdev = with pkgs; [
          omnisharp-roslyn # lsp
          netcoredbg # debugger
          uncrustify # formatter
        ];
        zigdev = with pkgs; [
          zls # lsp
          lldb # debugger
        ];
        neonixdev = {
          inherit (pkgs) nix-doc nil lua-language-server nixd alejandra;
        };
      };
      startupPlugins = {
        debug = with pkgs.vimPlugins; [
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
        ];
        neonixdev = with pkgs.vimPlugins; [
          neodev-nvim
          neoconf-nvim
        ];
        markdown = with pkgs.vimPlugins; [
          markdown-preview-nvim
        ];
        lazy = with pkgs.vimPlugins; [
          lazy-nvim
        ];
        general = {
          gitPlugins = with pkgs.neovimPlugins; [
            hlargs
          ];
          vimPlugins = {
            # you can make a subcategory
            cmp = with pkgs.vimPlugins; [
              # cmp stuff
              nvim-cmp
              luasnip
              friendly-snippets
              cmp_luasnip
              cmp-buffer
              cmp-path
              cmp-nvim-lua
              cmp-nvim-lsp
              cmp-cmdline
              cmp-nvim-lsp-signature-help
              cmp-cmdline-history
              lspkind-nvim
            ];
            general = with pkgs.vimPlugins; [
              telescope-fzf-native-nvim
              plenary-nvim
              telescope-nvim
              # treesitter
              nvim-treesitter-textobjects
              nvim-treesitter.withAllGrammars
              # This is for if you only want some of the grammars
              # (nvim-treesitter.withPlugins (
              #   plugins: with plugins; [
              #     nix
              #     lua
              #   ]
              # ))
              # other
              nvim-lspconfig
              fidget-nvim
              # lualine-lsp-progress
              lualine-nvim
              gitsigns-nvim
              which-key-nvim
              comment-nvim
              vim-sleuth
              vim-fugitive
              vim-rhubarb
              vim-repeat
              undotree
              nvim-surround
              indent-blankline-nvim
              nvim-web-devicons
              oil-nvim

              eyeliner-nvim
              toggleterm-nvim
              neo-tree-nvim
              statuscol-nvim
              nvim-osc52
              nvim-ufo
              conform-nvim
              diffview-nvim
            ];
          };
        };
        themer = with pkgs.vimPlugins; (
          builtins.getAttr categories.colorscheme {
            "onedark" = onedark-nvim;
            "catppuccin" = catppuccin-nvim;
            "catppuccin-mocha" = catppuccin-nvim;
            "tokyonight" = tokyonight-nvim;
            "tokyonight-day" = tokyonight-nvim;
          }
        );
      };
      optionalPlugins = {
        customPlugins = with pkgs.nixCatsBuilds; [];
        gitPlugins = with pkgs.neovimPlugins; [];
        general = with pkgs.vimPlugins; [];
      };
      sharedLibraries = {
        general = with pkgs; [
          # libgit2
        ];
      };
      environmentVariables = {
        test = {
          CATTESTVAR = "It worked!";
        };
      };
      extraWrapperArgs = {
        test = [
          ''--set CATTESTVAR2 "It worked again!"''
        ];
      };
      extraPython3Packages = {
        test = _: [];
      };
      extraPythonPackages = {
        test = _: [];
      };
      extraLuaPackages = {
        test = [(_: [])];
      };
    };
    packageDefinitions = {
      nixCats = {pkgs, ...}: {
        settings = {
          wrapRc = true;
          aliases = ["vim"];
        };
        categories = {
          generalBuildInputs = true;
          markdown = true;
          general.vimPlugins = true;
          general.gitPlugins = true;
          custom = true;
          neonixdev = true;
          test = {
            subtest1 = true;
          };
          debug = false;
          lspDebugMode = false;
          lazy = false;
          themer = true;
          colorscheme = "onedark";
          theBestCat = "says meow!!";
          theWorstCat = {
            thing'1 = ["MEOW" "HISSS"];
            thing2 = [
              {
                thing3 = ["give" "treat"];
              }
              "I LOVE KEYBOARDS"
            ];
            thing4 = "couch is for scratching";
          };
          # see :help nixCats
        };
      };
    };
    defaultPackageName = "nixCats";
  in
    forEachSystem (system: let
      inherit (utils) baseBuilder;
      customPackager =
        baseBuilder luaPath {
          inherit nixpkgs system dependencyOverlays extra_pkg_config;
        }
        categoryDefinitions;
      nixCatsBuilder = customPackager packageDefinitions;
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = utils.mkPackages nixCatsBuilder packageDefinitions defaultPackageName;
      devShells = {
        default = pkgs.mkShell {
          name = defaultPackageName;
          packages = [(nixCatsBuilder defaultPackageName)];
          inputsFrom = [];
          shellHook = ''
          '';
        };
      };
      inherit customPackager;
    })
    // {
      overlays =
        utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays extra_pkg_config;
        }
        categoryDefinitions
        packageDefinitions
        defaultPackageName;

      nixosModules.default = utils.mkNixosModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          nixpkgs
          ;
      };
      homeModule = utils.mkHomeModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          nixpkgs
          ;
      };
      inherit utils categoryDefinitions packageDefinitions dependencyOverlays;
      inherit (utils) templates baseBuilder;
      keepLuaBuilder = utils.baseBuilder luaPath;
    };
}
