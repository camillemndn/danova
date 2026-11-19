let
  inputs = import ./lon.nix;
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (_: prev: {
        quarto =
          (prev.quarto.override {
            pandoc = prev.stdenvNoCC.mkDerivation (finalAttrs: {
              pname = "pandoc-cli";
              version = "3.10";
              src = prev.fetchurl {
                url = "https://github.com/jgm/pandoc/releases/download/${finalAttrs.version}/pandoc-${finalAttrs.version}-linux-amd64.tar.gz";
                hash = "sha256-4PivYtDyZ9IrqlvO/m1d2joJfMxg3nlLdZ/gMVmSMkQ=";
              };
              nativeBuildInputs = [ pkgs.autoPatchelfHook ];
              buildInputs = with prev; [
                stdenv.cc.cc.lib
                zlib
              ];
              installPhase = ''
                install -Dm755 bin/pandoc $out/bin/pandoc
                ln -s pandoc $out/bin/pandoc-cli
              '';
              meta.mainProgram = "pandoc";
            });
          }).overrideAttrs
            (
              finalAttrs: old: {
                version = "1.10.18";

                src = prev.fetchurl {
                  url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${finalAttrs.version}/quarto-${finalAttrs.version}-linux-amd64.tar.gz";
                  hash = "sha256-r60HG1vSLALy0wBpV0MYnTZQ4FN6Uwc+ZUtjDP8rDHM=";
                };

                patches = (old.patches or [ ]) ++ [ ./mermaid-pdf.patch ];
              }
            );

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
                rev = "v0.0.0.9021";
                hash = "sha256-aIlpJ2Mea0huPTjvzVbaaJIpBJq/hSM8moLxgBCpU7g=";
              };
              nativeBuildInputs = [
                pkgs.cargo
                pkgs.rustc
              ];
              propagatedBuildInputs = [
                dplyr
                fda
                ggplot2
                tidyr
              ];
            };
          };
        };
      })
      (_: prev: {
        panache = prev.panache.overrideAttrs (
          finalAttrs: _: {
            version = "3.10.0";

            src = prev.fetchFromGitHub {
              owner = "jolars";
              repo = "panache";
              tag = "v${finalAttrs.version}";
              hash = "sha256-13v2J7qRgkX55vjFt0daU26J/IhmECCr1H0fVEW72rk=";
            };

            cargoDeps = prev.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) src;
              name = "panache-${finalAttrs.version}";
              hash = "sha256-D8SfoPjfIHnrvjYG6lJbqAHL1jkAI5st2105OP9md6s=";
            };
          }
        );
      })
    ];
  };

  r-deps = with pkgs.rPackages; [
    boot
    CompQuadForm
    dda
    fda_usc
    fdANOVA
    MVN
    sf
    tidyverse

    colorout
    devtools
    languageserver
    quarto
  ];

  pre-commit-hook = (import inputs.git-hooks).run {
    src = ./.;

    # git-hooks.nix resolves hook binaries from its own nixpkgs, so pin the
    # panache hooks to the same derivation as the shell.
    tools = { inherit (pkgs) panache; };

    hooks = {
      statix.enable = true;
      deadnix.enable = true;
      rfc101 = {
        enable = true;
        name = "RFC-101 formatting";
        entry = "${pkgs.lib.getExe pkgs.nixfmt}";
        files = "\\.nix$";
      };
      commitizen.enable = true;
      panache-format = {
        enable = true;
        files = "\\.(qmd|Rmd)$";
      };
      panache-lint = {
        enable = true;
        files = "\\.(qmd|Rmd)$";
      };
    };
  };
in

rec {
  devShells.default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      lon
      mermaid-cli
      (quarto.override { extraRPackages = r-deps; })
      (rWrapper.override { packages = r-deps; })
      texliveFull
      panache
      air-formatter
    ];
    shellHook = ''
      ${pre-commit-hook.shellHook}
    '';
  };

  packages.x86_64-linux = {
    website = pkgs.callPackage (
      {
        stdenv,
        glibcLocales,
        image_optim,
        mermaid-cli,
        quarto,
        texliveFull,
        which,
        ...
      }:

      stdenv.mkDerivation {
        name = "camillemondon-danova";
        src = builtins.fetchGit ./.;

        buildInputs = [
          glibcLocales
          image_optim
          mermaid-cli
          (quarto.override { extraRPackages = r-deps; })
          texliveFull
          which
        ];

        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LC_ALL = "en_US.UTF-8";
        HOME = ".";

        buildPhase = ''
          quarto render
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
