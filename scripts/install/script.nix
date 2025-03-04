{ pkgs, self, ... }:
pkgs.writeShellApplication {
  name = "lemon";
  runtimeInputs = [ pkgs.gum ];
  text = ''
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hello, there! Welcome to $(gum style --foreground 212 'The BEST NIX INSTALLER')."
        DRIVEPATH=$(gum input --placeholder "What your drive path?")
        ASHIFT=$(gum input --placeholder "What do you want your ashift set to?")
        DISKNAME=$(gum input --placeholder "What do you want your disk name set to?")

    	echo -e "You have set the following properites, $(gum style --foreground 212 " Your disk name is $DISKNAME, your drive path is $DRIVEPATH and your ashift is $ASHIFT" )."
    	sudo nix --experimental-features "nix-command flakes cgroups" run github:nix-community/disko/latest -- --mode destroy,format,mount  ${self.outPath}/templates/zfsonix.nix
  '';
}
