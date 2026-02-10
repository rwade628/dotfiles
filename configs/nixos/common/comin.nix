# GitOps continuous deployment with comin
{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/rwade628/dotfiles.git";
        branches.main.name = "nixos";
      }
    ];
    repositorySubdir = "configs/nixos";
    hostname = config.networking.hostName;
  };

  # Fix diverged history on comin start (e.g., after force-push)
  # Use || true to tolerate network unavailability at boot - comin will fetch on its own
  systemd.services.comin.preStart = ''
    REPO="/var/lib/comin/repository"
    if [ -d "$REPO/.git" ]; then
      ${pkgs.git}/bin/git -C "$REPO" fetch origin || true
      ${pkgs.git}/bin/git -C "$REPO" reset --hard origin/main || true
    fi
  '';
}
