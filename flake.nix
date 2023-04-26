{
  description = "Lightning Network Daemon";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          tags = [ "autopilotrpc" "signrpc" "walletrpc" "chainrpc" "invoicesrpc" "watchtowerrpc" "routerrpc" "monitoring" "kvdb_postgres" "kvdb_etcd" ];
        in
          rec {
            lnd = pkgs.buildGoModule rec {
              pname = "lnd";
              version = "0.16.0-beta";

              src = pkgs.fetchFromGitHub {
                owner = "lightningnetwork";
                repo = "lnd";
                rev = "v${version}";
                sha256 = "sha256-mOGCW+tqQ4eeJe+o9TF51hTNHnKwD7oU2Uxwlhl1n9w=";
              };

              vendorSha256 = "sha256-J+xJW7tbHWVO+2oIKdsCf28xSLdEO6WP7vldToYcuyk=";
              
              subPackages = [ "cmd/lncli" "cmd/lnd" ];

              preBuild = let
                buildVars = {
                  RawTags = nixpkgs.lib.concatStringsSep "," tags;
                  GoVersion = "$(go version | egrep -o 'go[0-9]+[.][^ ]*')";
                };
                buildVarsFlags = nixpkgs.lib.concatStringsSep " " (nixpkgs.lib.mapAttrsToList (k: v: "-X github.com/lightningnetwork/lnd/build.${k}=${v}") buildVars);
              in
                nixpkgs.lib.optionalString (tags != []) ''
    buildFlagsArray+=("-tags=${nixpkgs.lib.concatStringsSep " " tags}")
    buildFlagsArray+=("-ldflags=${buildVarsFlags}")
  '';
            };
            lnd-scb = pkgs.buildGoModule rec {
              pname = "lnd";
              version = "scb_cln_issue_7301_v0.16.0-beta.rc1";

              src = pkgs.fetchFromGitHub {
                owner = "lightningnetwork";
                repo = "lnd";
                rev = "c13af011497113cd55f4f10be0cbab16788f2583";
                sha256 = "sha256-eDI5qHfukaw1rZRZY50Hc10vct8XwuUTHfh/1RCV3ac=";
              };

              vendorSha256 = "sha256-Ru3Hc3EyBYAp4piX3j0Xpq087tMzhfIeu6OW63t67ms=";

              subPackages = [ "cmd/lncli" "cmd/lnd" ];

              preBuild = let
                buildVars = {
                  RawTags =  "dev";
                  GoVersion = "$(go version | egrep -o 'go[0-9]+[.][^ ]*')";
                };
                buildVarsFlags = nixpkgs.lib.concatStringsSep " " (nixpkgs.lib.mapAttrsToList (k: v: "-X github.com/lightningnetwork/lnd/build.${k}=${v}") buildVars);
              in
                nixpkgs.lib.optionalString (tags != []) ''
    buildFlagsArray+=("-tags=dev")
    buildFlagsArray+=("-ldflags=${buildVarsFlags}")
  '';         
            };
            lnd-funds-recovery = pkgs.buildGoModule rec {
              pname = "lnd";
              version = "v0.16.1-beta-fund-recovery";

              src = pkgs.fetchFromGitHub {
                owner = "guggero";
                repo = "lnd";
                rev = "${version}";
                sha256 = "sha256-f2K7DtHcGC4N9VLKtTXBwoMu0MLE3l5EiL8UOA1OYy4=";
              };

              vendorSha256 = "sha256-yY6H2K9B9ko5bVdmsGPDJkxPXpfAs0O2fuaZryrcuc0=";

              subPackages = [ "cmd/lncli" "cmd/lnd" ];

              preBuild = let
                buildVars = {
                  RawTags =  "dev";
                  GoVersion = "$(go version | egrep -o 'go[0-9]+[.][^ ]*')";
                };
                buildVarsFlags = nixpkgs.lib.concatStringsSep " " (nixpkgs.lib.mapAttrsToList (k: v: "-X github.com/lightningnetwork/lnd/build.${k}=${v}") buildVars);
              in
                nixpkgs.lib.optionalString (tags != []) ''
    buildFlagsArray+=("-tags=dev")
    buildFlagsArray+=("-ldflags=${buildVarsFlags}")
  '';         
            };
            default = lnd;
          });
    };
}
