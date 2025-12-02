let
  inputs = import ./lon.nix;
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (_: prev: {
        rPackages = prev.rPackages.override {
          overrides = with prev.rPackages; {
            colorout = buildRPackage {
              name = "colorout";
              src = pkgs.fetchFromGitHub {
                owner = "jalvesaq";
                repo = "colorout";
                rev = "v1.3-3";
                hash = "sha256-1aWDrvW1+X5bxJEZlm3RLy8Urx6UlYX7BqJwNF2bNYA=";
              };
            };

            dda = buildRPackage {
              name = "dda";
              src = pkgs.fetchFromGitHub {
                owner = "camillemndn";
                repo = "dda";
                rev = "v0.0.0.9018";
                hash = "sha256-ReqTqTTKJC9e0OVabLi9f5vXFZKVAHPQYaZ7rlIxUQU=";
              };
              propagatedBuildInputs = [
                fda
                GGally
                ggplot2
                ICS
                ICSOutlier
                memoise
              ];
            };
          };
        };
      })
    ];
  };

  r-deps = with pkgs.rPackages; [
    boot
    CompQuadForm
    dda
    fda_usc
    fdANOVA
    gstat
    MVN
    reshape2
    sf
    tidyverse

    colorout
    devtools
    languageserver
    quarto
  ];

  pre-commit-hook = (import inputs.git-hooks).run {
    src = ./.;

    hooks = {
      statix.enable = true;
      deadnix.enable = true;
      rfc101 = {
        enable = true;
        name = "RFC-101 formatting";
        entry = "${pkgs.lib.getExe pkgs.nixfmt-rfc-style}";
        files = "\\.nix$";
      };
      commitizen.enable = true;
    };
  };
in

rec {
  devShells.default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      npins
      (quarto.override { extraRPackages = r-deps; })
      (rstudioWrapper.override { packages = r-deps; })
      (rWrapper.override { packages = r-deps; })
      texliveFull
      librsvg
      chromium
    ];
    shellHook = ''
      ${pre-commit-hook.shellHook}
    '';
  };

  packages.x86_64-linux = {
    website = pkgs.callPackage (
      {
        stdenv,
        chromium,
        image_optim,
        quarto,
        texliveFull,
        which,
        ...
      }:

      stdenv.mkDerivation {
        name = "camillemondon-danova";
        src = builtins.fetchGit ./.;

        buildInputs = [
          chromium
          image_optim
          (quarto.override { extraRPackages = r-deps; })
          texliveFull
          which
        ];

        HOME = ".";

        buildPhase = ''
          quarto render index.qmd --to html
          image_optim --recursive _manuscript
        '';

        installPhase = ''
          cp -r _manuscript $out
        '';
      }
    ) { };
  };

  checks.default = {
    inherit packages;
  };
}
