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
          {
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

              meta = with nixpkgs.lib; {
                description = "Lightning Network Daemon";
                homepage = "https://github.com/lightningnetwork/lnd";
                license = licenses.mit;
                maintainers = with maintainers; [ cypherpunk2140 prusnak ];
              };
            };
        });
      
      # Add dependencies that are only needed for development
      # devShells = forAllSystems (system:
      #   let 
      #     pkgs = nixpkgsFor.${system};
      #   in
      #   {
      #     default = pkgs.mkShell {
      #       buildInputs = with pkgs; [ go gopls gotools go-tools ];
      #     };
      #   });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      # defaultPackage = forAllSystems (system: self.packages.${system}.lnd);
    };
}
