# Doom Emacs

My private config for Doom Emacs.


# Install

``` console
foo@bar:~$ git clone https://github.com/captain-yoshi/.doom.d ~/.config/doom
```

# Install Emacs (Source)

``` console
foo@bar:~$ git clone https://github.com/emacs-mirror/emacs.git
foo@bar:~$ git checout emacs-29.4

foo@bar:~$ cd emacs

foo@bar:~$ ./configure --with-native-compilation --with-json
foo@bar:~$ make
foo@bar:~$ sudo make install
```

# Install DoomEmacs

``` console
# https://github.com/doomemacs/doomemacs?tab=readme-ov-file#install
foo@bar:~$ git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs

foo@bar:~$ ~/.config/emacs/bin/doom install

# check for warnings
foo@bar:~$ ~/.config/emacs/bin/doom doctor

# add ~/.config/emacs/bin to path (optional)
foo@bar:~$ sudo cp -s ~/.config/emacs/bin/doom /usr/local/bin/
```


# Server Side Installation
- clang-format


```console
foo@bar:~$ sudo apt install markdown
foo@bar:~$ sudo apt install clang-format

# :lang cc
foo@bar:~$ sudo apt-get install glslang-tools

# Ubuntu 22.04
sudo apt install libstdc++-12-dev

# :lang python
foo@bar:~$ sudo apt-get install black     # code formatting
foo@bar:~$ # import management
foo@bar:~$ # import sorting
foo@bar:~$ # pipenv support
foo@bar:~$ # running tests through nose
foo@bar:~$ # running tests through pytest
foo@bar:~$ # conda

# :lang sh
foo@bar:~$ sudo apt install shfmt



```
