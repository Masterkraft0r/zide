{
  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, flakeUtils, ... }: (
    flakeUtils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (builtins) foldl';
        inherit (flakeUtils.lib) mkApp;
        inherit (pkgs) fetchFromGitHub;
        inherit (pkgs.stdenv) mkDerivation;
        inherit (pkgs.lib.attrsets) mapCartesianProduct recursiveUpdate;

        supported_combinations = mapCartesianProduct (
          combination:
            combination
        ) {
          editor = [ "helix" "kakoune" "neovom" "vim" ];
          git = [ "lazygit" "gitui" ];
          picker = [ "lf" "yazi" ];
        };

        mkZidePkg = {editor, git, picker}: (
          mkDerivation {
            pname = "zide";
            version = "3.2.1";

            src = ./.;
            autoLayout = fetchFromGitHub {
              owner = "luccahuguet";
              repo = "auto-layout.yazi";
              rev = "main";
              hash = "sha256-sTpbO2Enzhg25CWdo+IHjDjHUCMJN3dDXeTYoK2FrUQ=";
            };

            inputs = [
              pkgs.zellij
              pkgs.${editor}
              pkgs.${git}
              pkgs.${picker}
            ];
            buildInputs = [
              pkgs.makeWrapper
            ];
        
            installPhase = ''
              runHook preInstall

              mkdir -p $out/{bin,layouts,lf,yazi/plugins}

              cp -r $src/bin $out
              cp -r $src/layouts $out
              cp -r $src/lf $out
              cp -r $src/yazi $out
              cp -r $autoLayout $out/yazi/plugins/auto-layout.yazi

              runHook postInstall
            '';
          }
        );
        zidePkgs = foldl' (
          acc: {editor, git, picker}@params:
            recursiveUpdate acc { ${picker}.${git}.${editor} = mkZidePkg params; }
        ) {} supported_combinations;
        mkZideApp = {editor, git, picker}: mkApp {
          drv = zidePkgs.${picker}.${git}.${editor};
        };
        zideApps = foldl' (
          acc: {editor, git, picker}@params:
            recursiveUpdate acc { ${picker}.${git}.${editor} = mkZideApp params; }
        ) {} supported_combinations;
      in {
        apps = {
          zide = zideApps;
          default = zideApps.yazi.lazygit.helix;
        };
        packages = {
          zide = zidePkgs;
          default = zidePkgs.yazi.lazygit.helix;
        };
      }
    )
  );
}
