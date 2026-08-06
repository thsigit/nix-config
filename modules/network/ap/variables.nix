# Shared network interface variables
{ config, lib, ... }:

{
  options.services.ap = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = "wlp1s0";
      description = "Wireless access point network interface";
    };
    band = lib.mkOption {
      type = lib.types.enum [ "2g" "5g" "6g" ];
      default = "2g";
      description = "Radio band for the access point";
    };
  };
}
