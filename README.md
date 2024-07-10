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

```
