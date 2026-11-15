#!/bin/bash

HOME=/home/root

if [ -e "$HOME/recover_data/upgrade.cfg" ]; then
    echo "'upgrade.cfg' exist!!"
    source $HOME/recover_data/upgrade.cfg
    
    # ==================== Brightness ========================
    if [ ! "$BRIGHTNESS" = "" ]; then 
      echo "$BRIGHTNESS" > /sys/class/backlight/lcd/brightness
      echo " [####======] Brightness set to '$BRIGHTNESS'"
    fi
    # =========== Daemons variod, sensord and dropbear.socket(ssh) ====
    # Restore variod, sensord and ssh status 
    for daemon in sensord variod dropbear.socket; do
      case $daemon in 
        dropbear.socket) d_state="$ssh_d";;
        sensord)         d_state="$sensord";;
        variod)          d_state="$variod";;
      esac
      case $d_state in
        enabled)  /bin/systemctl  enable --quiet --now $daemon
                  /bin/systemctl   start --quiet --now $daemon
                  echo " [#####=====] $daemon has been enabled."
                  ;;
        disabled) /bin/systemctl disable --quiet --now $daemon
                  echo " [#####=====] $daemon has been disabled."
                  ;;
      esac
    done
    # ==================== Recover Data ======================
    if [ "$UPGRADE_TYPE" == "2" ]; then
      if ! mountpoint -q "$DATADIR"; then
        echo "data partition is not mounted; keeping ~/.xcsoar" >> $DEBUG_LOG
      else
        /usr/bin/psplash-message "Restoring flight data..." 2>/dev/null || true
        mkdir -p "$DATADIR/OpenSoarData" "$DATADIR/XCSoarData"
        copy_ok=1
        for f in "$HOME/.xcsoar"/*; do
          [ -e "$f" ] || continue
          base=${f##*/}
          case "$base" in
            *.prf) xdest="$DATADIR/XCSoarData/profiles" ;;
            *.xci) xdest="$DATADIR/XCSoarData/input" ;;
            *.xcm) xdest="$DATADIR/XCSoarData/maps" ;;
            *) xdest="$DATADIR/XCSoarData" ;;
          esac
          mkdir -p "$xdest" || copy_ok=0
          # Profiles, input and maps are read from those directories.
          rsync -a --ignore-existing "$f" "$xdest/" || copy_ok=0
          rsync -a --ignore-existing "$f" "$DATADIR/OpenSoarData/" || copy_ok=0
        done
        sync
        if [ "$copy_ok" = 1 ]; then
          rm -rf "$HOME/.xcsoar"/*
          echo "copied ~/.xcsoar into XCSoarData and OpenSoarData" >> $DEBUG_LOG
        else
          echo "copy of ~/.xcsoar failed; source kept" >> $DEBUG_LOG
        fi
        if [ -d "$HOME/.glider_club" ]; then
          mkdir -p "$DATADIR/.glider_club"
          if rsync -a --ignore-existing "$HOME/.glider_club/" "$DATADIR/.glider_club/"; then
            rm -rf "$HOME/.glider_club"
          fi
          sync
        fi
      fi
    fi
    # ==================== End ===============================
    mv $HOME/recover_data/upgrade.cfg $HOME/recover_data/_upgrade.cfg
fi

