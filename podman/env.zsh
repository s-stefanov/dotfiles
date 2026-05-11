if [[ "$DOTFILES_OS" == "wsl" ]]; then
    export DOCKER_HOST=unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock
fi
