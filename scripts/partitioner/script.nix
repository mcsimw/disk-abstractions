{ pkgs, self, ... }:

let
  originalScript = builtins.readFile ./script.sh;
  finalScript = builtins.replaceStrings [ "SELF_OUT_PATH" ] [ self.outPath ] originalScript;
in
pkgs.writeShellApplication {
  name = "DISK-PARTITIONER";
  runtimeInputs = [ pkgs.gum ];
  text = finalScript;
}
