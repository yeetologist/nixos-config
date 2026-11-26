{
  description = "NixOS configuration for nixos-btw";

  # ---------------------------------------------------------------------------
  # Inputs — external flakes this config depends on.
  # All inputs that ship their own nixpkgs must follow ours to avoid duplicate
  # copies being downloaded and built.
  # ---------------------------------------------------------------------------
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-built nix-index database + the `comma` (,) runner tool.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri scrollable-tiling Wayland compositor.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Herdr terminal workspace manager (official prebuilt release binaries).
    herdr-nix = {
      url = "github:herdrdev/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Yazi file manager flake (for latest builds + RAR override).
    # yazi = {
    #   url = "github:sxyazi/yazi";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # ---------------------------------------------------------------------------
  # Outputs
  # ---------------------------------------------------------------------------
  outputs = { self, nixpkgs, home-manager, niri, nix-index-database, ... }@inputs:
  let
    # ── Machine-wide constants ───────────────────────────────────────────────
    # Edit only here; every module receives these via specialArgs / extraSpecialArgs
    # so nothing is hardcoded inside configuration.nix or home.nix.
    user     = "bam";
    system   = "x86_64-linux";
    timezone = "Asia/Jakarta";

    # One NixOS system per host folder: shared config + hosts/<host>/. `host` = folder = flake attribute.
    mkHost = host: nixpkgs.lib.nixosSystem {
      inherit system;

      # Passed as named arguments to every NixOS module function.
      specialArgs = { inherit inputs user timezone system host; };

      modules = [
        ./configuration.nix
        ./hosts/${host} # this machine's hardware, disk layout and host-only settings

        # Niri compositor system integration.
        inputs.niri.nixosModules.niri

        # nix-index DB (enables `nix-locate` and command-not-found hook).
        nix-index-database.nixosModules.nix-index

        # Home Manager integrated into nixos-rebuild — no separate `hm switch`.
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs      = true;   # share system nixpkgs, no extra eval
            useUserPackages    = true;   # HM packages land in /etc/profiles
            backupFileExtension = "backup";
            extraSpecialArgs   = {
              inherit inputs user host;
              # yazi = inputs.yazi;
            };
            users.${user}.imports = [ ./home.nix ];
          };
        }
      ];
    };

    # Every folder in hosts/ is a host: hosts/laptop -> nixosConfigurations.laptop (add-host.sh creates them).
    hostNames = builtins.attrNames
      (nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs hostNames mkHost;
  };
}
