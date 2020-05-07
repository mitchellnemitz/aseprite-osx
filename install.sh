#!/usr/bin/env bash

install() {
    rm -rf /Applications/Aseprite.app
    cp -R Aseprite.app /Applications/Aseprite.app
}

printf "Install Aseprite to /Applications/Aseprite.app? (y/n) "
read -r -n1 choice
printf "\n"

case "$choice" in
  y|Y) install ;;
esac
