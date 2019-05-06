Bash Toolkit
====================================


Installation
------------

Clone the repository into your home directory as `.bash-toolkit`:

    cd ~
    git clone https://github.com/outerloper/bash-toolkit .bash-toolkit

Add `source "${HOME}/.bash-toolkit/src/init.sh"` to your `.bash_profile`. You can also do this with the following command:

    echo -e '\nsource "~/.bash-toolkit/src/init.sh"' >> ~/.bash_profile

To enable bundled Vim tweaks, include `source ~/.bush/src/resources/vimrc.sh` command into your `.vimrc`:

    touch ~/.vimrc
    echo -e '\nsource ~/.bush/src/resources/vimrc.sh' >> ~/.vimrc

To get the latest version:

    cd ~/.bash-toolkit
    git stash
    git pull origin
    git stash pop

To run tests, execute this:

    cd ~/.bash-toolkit/test
    ./suite.sh
