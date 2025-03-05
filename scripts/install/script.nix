{ pkgs, self, ... }:
pkgs.writeShellApplication {
  name = "lemon";
  runtimeInputs = [ pkgs.gum ];
  text = ''
  
    gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 \
      "Hello, there! Welcome to $(gum style --foreground 212 'The BEST NIX INSTALLER')."

  
    while true; do
      DISKID=$(gum input --placeholder "Enter disk identifier (e.g., sda, nvme0n1)")
      DRIVEPATH="/dev/$DISKID"
      # Use lsblk to check if DRIVEPATH exists and is of type 'disk'
      DISK_TYPE=$(lsblk -nd -o TYPE "$DRIVEPATH" 2>/dev/null || true)
      if [ "$DISK_TYPE" = "disk" ]; then
        break
      else
        gum style --foreground 1 "Invalid disk: $DRIVEPATH is either not present or not of type 'disk'. Please try again."
      fi
    done

    ASHIFT=$(gum input --placeholder "What do you want your ashift set to?")
    DISKNAME=$(gum input --placeholder "What do you want your disk name set to?")
    SWAPSIZE=$(gum input --placeholder "What do you want as swap size?")

    # Display a summary of the provided inputs
    gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
      "You have set the following properties:
      Disk name: $DISKNAME
      Drive path: $DRIVEPATH
      Ashift: $ASHIFT
      Swap size: $SWAPSIZE"

    # Let the user select actions using gum choose with multi-selection support.
    # Use tab or ctrl+space to toggle selections, then press enter.
    ACTIONS=$(gum choose --no-limit "destroy" "format" "mount" --header "Select actions to perform (use tab or ctrl+space to select, then press enter)")

    if [ -z "$ACTIONS" ]; then
      gum style --foreground 1 "No actions selected. Exiting..."
      exit 1
    fi

    # Display the selected actions
    gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
      "You have selected: $ACTIONS"
    COUNT=$(echo "$ACTIONS" | wc -w | tr -d ' ')
    if [ "$COUNT" -eq 1 ]; then
      MODE="$ACTIONS"
    elif [ "$COUNT" -eq 2 ]; then
      if echo "$ACTIONS" | grep -q "destroy"; then
        gum style --foreground 1 "Invalid selection: combining 'destroy' with only one other action is not allowed."
        exit 1
      else
        MODE="format,mount"
      fi
    elif [ "$COUNT" -eq 3 ]; then
      MODE="destroy,format,mount"
    else
      gum style --foreground 1 "Invalid selection. Exiting..."
      exit 1
    fi

    # Ask for final confirmation with the validated mode displayed.
    if ! gum confirm "Do you want to proceed with these actions? (mode: $MODE)"; then
      gum style --foreground 1 "Operation cancelled."
      exit 0
    fi

    # Execute the installer command with the chosen mode and provided parameters.
    sudo nix --experimental-features "nix-command flakes cgroups" run \
      github:nix-community/disko/latest -- --mode "$MODE" ${self.outPath}/templates/zfsonix.nix \
      --argstr ashift "$ASHIFT" --argstr diskName "$DISKNAME" --argstr device "$DRIVEPATH" --argstr swapSize "$SWAPSIZE"
  '';
}
