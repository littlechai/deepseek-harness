# Pinned dev toolchain: Node.js 24, pnpm 11.7.0 (the version `package.json`
# pins), uv + Python 3 (the `python/` workflows), Git (Lefthook hooks), and
# bubblewrap (the Linux sandbox runner the confined shell probes for).
# `flake.lock` records the exact nixpkgs commit; update deliberately with
# `nix flake update`. Enter with `nix develop`.
{
  description = "DeepSeek Harness development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      mkDevShell = pkgs:
        let
          # nixpkgs ships pnpm_11 at 11.4.0; build the pinned release
          # through nixpkgs' own pnpm builder from the official npm tarball.
          pnpm = pkgs.callPackage (pkgs.path + "/pkgs/development/tools/pnpm/generic.nix") {
            version = "11.7.0";
            hash = "sha256-3q+n7JihIYtqBHKJuS++I5XB4i00lbtxFlMBMhjuFe4=";
          };
        in
        pkgs.mkShell {
          packages =
            [
              pnpm
              pkgs.nodejs_24
              pkgs.uv
              pkgs.python3
              pkgs.gitFull
            ]
            # The sandbox backend's Linux runner chain probes `bwrap` on PATH
            # before the Landlock launcher. Without it every confined command
            # fails closed with SANDBOX_UNAVAILABLE, so launching `dsh` from
            # this shell would still need per-call approval. macOS confines
            # through the OS `sandbox-exec`, so nothing is added there.
            ++ nixpkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.bubblewrap ];
        };
    in
    {
      devShells = genAttrs systems (
        system:
          {
            default = mkDevShell nixpkgs.legacyPackages.${system};
          }
      );
    };
}
