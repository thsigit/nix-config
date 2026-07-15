# machines/portege-r30c/default.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelParams = lib.mkAfter [
    "initcall_blacklist=atkbd_init" # physical laptop keyboard disabled
  ];
}
