
# Select monitor layout

Select a monitor layout, powered by mons and rofi.  Without argument, it opens
a rofi dmenu window containing several monitor layout choices.

Inspired by [Dave Davenport rofi
scripts](https://github.com/DaveDavenport/RandomScripts).

Depends on:
- [rofi](https://github.com/DaveDavenport/rofi)
- [mons](https://github.com/Ventto/mons)


## Installation

Installation:
```
sudo make install
```

Installs by default under `/usr/local` (`/usr/local/bin`, `/usr/local/share`,
etc.).

To change the installation prefix:
```
make prefix=/customdir install
```
This will install files directly under the new prefix (`/customdir/bin`,
`/customdir/share`, etc.).

To change the installation root, but keep the prefix:
```
make DESTDIR=/customdir install
```
With default prefix, this will install files under `/customdir/usr/local/`
(`/customdir/usr/local/bin`, `/customdir/usr/local/share`, etc.).


