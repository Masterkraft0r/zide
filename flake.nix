{
  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, flakeUtils, ... }: let
    inherit (flakeUtils.lib) eachDefaultSystem mkApp;
  in eachDefaultSystem (
    system: let
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (pkgs.stdenv) mkDerivation;
      inherit (pkgs) fetchFromGitHub;

      zidePkg = mkDerivation {
        pname = "zide";
        version = "3.2.1";

        src = ./.;
        autoLayout = fetchFromGitHub {
          owner = "luccahuguet";
          repo = "auto-layout.yazi";
          rev = "main";
          hash = "sha256-sTpbO2Enzhg25CWdo+IHjDjHUCMJN3dDXeTYoK2FrUQ=";
        };
        
        dontBuild = true;
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
      };
      zideApp = mkApp {
        drv = zidePkg;
      };
    in {
      apps = {
        zide = zideApp;
        default = zideApp;
      };
      packages = {
        zide = zidePkg;
        default = zidePkg;
      };
    }
  );
}
