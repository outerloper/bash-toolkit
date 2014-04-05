bash-utils
==========

Usage
-----

To get it, clone the repository into your home directory as `.bash-toolkit`:

    git clone https://github.com/outerloper/bash-toolkit .bash-toolkit

To have it active any time you log in, include: `source "${HOME}/.bash-toolkit/profile.sh"` command into your `.bash_profile`:

    echo -e '\nsource "${HOME}/.bash-toolkit/core/src/profile.sh"' >> ~/.bash_profile

To enable bundled Vim tweaks, include `source ~/.bash-toolkit/core/src/vimrc.sh` command into your `.vimrc`:

    echo -e '\nsource ~/.bash-toolkit/core/src/vimrc.sh' >> ~/.vimrc

To pull the latest version from GitHub, execute this:

    cd ~/.bash-toolkit
    git pull origin

To run all unit tests, execute this:

    cd ~/.bash-toolkit/test
    ./suite.sh
