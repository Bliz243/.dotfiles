#! /bin/bash
set -ex

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $SELF_DIR/common.sh

CONFIG_DIR="$SELF_DIR"

make_dir() {
    mkdir -p $1
    chmod 755 $1
}

link_files() {
    trap "$(shopt -p extglob)" RETURN
    shopt -s nullglob

    local base=$1
    local dst=$2
    local prefix=${3:-}

    echo "Link files from $base to $dst"
    make_dir "$dst"
    for dot in $base/*; do
        local tgt=$dst/$prefix${dot##*/}
        if [[ -d "$dot" ]]; then
            link_files "$dot" "$tgt"
        else
            echo "Link $dot -> $tgt"
            ln -sfn $(realpath $dot) "$tgt"
        fi
    done
}

# per user configs
config_user() {
    local TARGET_USER=$1
    local TARGET_GROUP=$(id -gn $TARGET_USER)
    local TARGET_HOME=$(eval echo "~$TARGET_USER")

    echo "Configuring $TARGET_USER"

    echo "Setting default shell to zsh"
    chsh -s /usr/bin/zsh $TARGET_USER

    echo "Docker access"
    usermod -aG docker $TARGET_USER

    echo "Common group access"
    usermod -aG $PROJ_GROUP $TARGET_USER

    # check setup done after redoing default shell and group mod,
    # which gets overwritten by testbed service
    if [[ -f $TARGET_HOME/.setup-done ]]; then
        return
    fi

    echo "Redirect cache to /data"
    local mount_unit=$(systemd-escape --path --suffix=mount $TARGET_HOME/.cache)
    cat > /etc/systemd/system/$mount_unit <<EOF
[Unit]
Description=Bind $TARGET_HOME/.cache to /data/cache/$TARGET_USER

[Mount]
What=/data/cache/$TARGET_USER
Where=$TARGET_HOME/.cache
Type=none
Options=bind

[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload && systemctl enable --now $mount_unit

    echo "NodeJS"
    export NVM_DIR=$TARGET_HOME/.local/share/nvm
    # tell nvm to not touch our zshrc
    export PROFILE=/dev/null
    export NODE_VERSION=lts/*
    mkdir -p $NVM_DIR
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

    # dotfiles
    echo "Linking dotfiles"
    make_dir $TARGET_HOME/.local
    link_files $CONFIG_DIR/dotfiles/home $TARGET_HOME "."
    ln -nsf $CONFIG_DIR/dotfiles/scripts $TARGET_HOME/.local/bin

    # common directories
    make_dir $TARGET_HOME/tools
    make_dir $TARGET_HOME/downloads
    make_dir $TARGET_HOME/buildbed

    # remove unused mounting point, which slows down permission changing
    # we try to directly unmount the path, as root doesn't have permission to even check if the path is mountpoint
    # i.e. `mountpoint -q -- $TARGET_HOME/my_mounting_point` returns permission denied because FUSE only allows
    # the actual user to access it.
    if umount $TARGET_HOME/my_mounting_point 2>/dev/null; then
        rmdir $TARGET_HOME/my_mounting_point
    fi

    # fix permission
    echo "Fixing permission"
    chown -R $TARGET_USER:$TARGET_GROUP $TARGET_HOME

    # initialize vim as if on first login
    su --login $TARGET_USER <<EOSU
zsh --login -c "umask 022 && source \$HOME/.zshrc && echo Initialized zsh" > $TARGET_HOME/zsh-setup.log &
nvim -es -u $TARGET_HOME/.config/nvim/init.vim -i NONE -c "PlugInstall" -c "qa" > $TARGET_HOME/vim-setup.log &
wait
EOSU

    date > $TARGET_HOME/.setup-done
}

init

for user in "$@"
do
    config_user "$user"
done
