{ pkgs, self, ... }:
pkgs.writeShellApplication {
  name = "DISK-PARTITIONER";
  runtimeInputs = [ pkgs.gum ];
  text = ''
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 \
    "Greetings, intrepid partitioner! Welcome to DISK PARTITIONER.

    Parting your disks is no small feat—some say it's like painting a masterpiece… but with bits!"

        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "First, let's peek at your disks. See anything that sparkles?
    (Below is 'lsblk' output for a quick overview of your block devices.)"

        # Show a tabular view of all block devices (omitting loop & RAM).
        lsblk -o NAME,MODEL,SIZE,TYPE,UUID,MOUNTPOINT -e 7 | gum format

        # Also show /dev/disk/by-id entries, if they exist, using `find` instead of `ls` to avoid SC2012
        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "And here are your /dev/disk/by-id entries (great for persistent naming!)."

        if [ -d /dev/disk/by-id ]; then
          find /dev/disk/by-id -mindepth 1 -maxdepth 1 -print0 | sort -z | xargs -0 ls -l | gum format
        else
          gum style --foreground 1 "No /dev/disk/by-id directory found on this system."
        fi

        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "Now, please type the **absolute** path of the disk you want to fiddle with!

    For example:
    /dev/sda
    /dev/nvme0n1
    /dev/disk/by-id/xyz

    (Note: DO NOT include partition numbers like /dev/sda1 or /dev/nvme0n1p2.)"

        while true; do
          DRIVEPATH=$(gum input --placeholder "/dev/nvme0n1 or /dev/disk/by-id/...")
          # Enforce that the input must start with /dev/
          if [[ "$DRIVEPATH" =~ ^/dev/ ]]; then
            DISK_TYPE=$(lsblk -nd -o TYPE "$DRIVEPATH" 2>/dev/null || true)
            if [ "$DISK_TYPE" = "disk" ]; then
              # It's a valid disk device
              break
            elif [ "$DISK_TYPE" = "part" ]; then
              gum style --foreground 1 "Oops! $DRIVEPATH appears to be a partition (type 'part'). 
    Please remove the trailing digit or partition suffix, and specify the entire disk instead."
            else
              gum style --foreground 1 "Oops! $DRIVEPATH doesn't seem to be a valid 'disk' device. Please try again."
            fi
          else
            gum style --foreground 1 "Input must start with '/dev/'. Please try again."
          fi
        done

        ASHIFT=$(gum input --placeholder "What do you want your ashift set to? (e.g., 12)")
        DISKNAME=$(gum input --placeholder "What do you want your disk name set to? (e.g., lemon)")
        SWAPSIZE=$(gum input --placeholder "What do you want as swap size? (e.g., 8G)")

        gum style --align left --border normal --margin "1" --padding "1" --foreground 212 \
    "Here are your chosen base values:

      Disk Name:   $DISKNAME
      Drive Path:  $DRIVEPATH
      Ashift:      $ASHIFT
      Swap Size:   $SWAPSIZE
    "

        gum style --border normal --margin "1" --padding "1" --border-foreground 212 \
    "Select which actions you want disko to perform.
    - 'destroy' means wipe it all out (careful!).
    - 'format' sets up new partitions.
    - 'mount' automatically mounts the freshly partitioned drive."

        ACTIONS=$(gum choose --no-limit "destroy" "format" "mount" --header "Select actions to perform (use TAB or CTRL+SPACE). Then press ENTER.")

        if [ -z "$ACTIONS" ]; then
          gum style --foreground 1 "No actions selected. Aborting..."
          exit 1
        fi

        gum style --align left --border normal --margin "1" --padding "1" --foreground 212 \
    "You have selected: $ACTIONS"

        COUNT=$(echo "$ACTIONS" | wc -w | tr -d ' ')

        # Validate or parse user selection to set the mode
        if [ "$COUNT" -eq 1 ]; then
          MODE="$ACTIONS"
        elif [ "$COUNT" -eq 2 ]; then
          # If exactly 2 and one is 'destroy', disallow
          if echo "$ACTIONS" | grep -q "destroy"; then
            gum style --foreground 1 "Alas, mixing 'destroy' with just one other action is not permissible. Exiting..."
            exit 1
          else
            MODE="format,mount"
          fi
        elif [ "$COUNT" -eq 3 ]; then
          MODE="destroy,format,mount"
        else
          gum style --foreground 1 "That combination of actions is beyond my mortal understanding. Bailing out!"
          exit 1
        fi

        # Show final chosen settings in a nicely formatted summary
        gum style --align left --border normal --margin "1" --padding "1" --foreground 212 \
    "Final summary of everything you've chosen:

      - Disk Name:   $DISKNAME
      - Drive Path:  $DRIVEPATH
      - Ashift:      $ASHIFT
      - Swap Size:   $SWAPSIZE
      - Mode:        $MODE
    "

        # Basic yes/no confirm
        if ! gum confirm "Do you really want to proceed with these actions? (mode: $MODE)?"; then
          gum style --foreground 1 "Operation cancelled by user. No harm done, phew!"
          exit 0
        fi

        # Final ultimate confirmation: Must type 'FUCK SCHOOL' in all caps
        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "Final check! Partitioning your disk can be destructive, so let's be sure you're absolutely ready.

    If you're 100% sure, type
    $(gum style --foreground 196 --bold 'FUCK SCHOOL')
    in ALL CAPS below to proceed.
    Otherwise, type anything else to abort."

        FINAL_CONFIRM=$(gum input --placeholder "Type FUCK SCHOOL in ALL CAPS to proceed...")
        if [ "$FINAL_CONFIRM" != "FUCK SCHOOL" ]; then
          gum style --foreground 1 "Operation aborted because you didn't type FUCK SCHOOL in all caps."
          exit 1
        fi

        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "Summoning the mighty 'disko' with the following incantation...
    (Brace yourself: 'sudo' may ask for a password.)"

        # run disko
        sudo nix --experimental-features "nix-command flakes cgroups" run \
          github:nix-community/disko/latest -- --mode "$MODE" ${self.outPath}/templates/zfsonix.nix \
          --argstr ashift "$ASHIFT" --argstr diskName "$DISKNAME" --argstr device "$DRIVEPATH" --argstr swapSize "$SWAPSIZE"

        gum style --align center --border normal --margin "1" --padding "1" --foreground 212 \
    "All done! Assuming success, here's a snippet you can place in your NixOS config (e.g., configuration.nix or a separate module).
    It will enable ZFS on your newly parted-and-formatted disk."

        # Display the config snippet via cat <<EOF so we don't have to worry about escaping quotes
        cat <<EOF | gum format
    $(gum style --foreground 229 --bold "{ inputs, ... }:
    {
      imports = [
        inputs.disk-abstractions.nixosModules.zfsonix
      ];
      zfsonix = {
        enable = true;
        diskName = \"$DISKNAME\";
        device = \"$DRIVEPATH\";
        ashift = \"$ASHIFT\";
        swapSize = \"$SWAPSIZE\";
      };

      # optional extras
      services.fstrim.enable = true;
      services.zfs.trim.enable = true;
      services.zfs.autoScrub.enable = true;
    }")
    EOF

        gum style --border normal --margin "1" --padding "1" --border-foreground 212 \
    "You made it to the end! FUCK YOU!"
  '';
}
