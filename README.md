BUSH – Bash Utils (pronounce [bʌʃ])
====================================


Usage
-----

To get it, clone the repository into your home directory as `.bash-toolkit`:

    cd ~
    git clone https://github.com/outerloper/bash-toolkit .bush

To have it active any time you log in, include the following line into your `.bash_profile`: `source "${HOME}/.bush/init.sh"`.

    echo -e '\nsource "~/.bush/core/src/profile.sh"' >> ~/.bash_profile

To enable bundled Vim tweaks, include `source ~/.bush/core/src/config/vimrc.sh` command into your `.vimrc`:

    touch ~/.vimrc
    echo -e '\nsource ~/.bash-toolkit/core/src/vimrc.sh' >> ~/.vimrc

To pull the latest version from GitHub, execute this:

    cd ~/.bush
    git pull origin

To run all unit tests, execute this:

    cd ~/.bush/test
    ./suite.sh
