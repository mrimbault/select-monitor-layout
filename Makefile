# Standard variables.
# See: https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html
# Avoid shell being inherited from environment.
SHELL := /bin/sh
# Define installation commands.
INSTALL         := install
INSTALL_DATA    := $(INSTALL) -m 644
INSTALL_PROGRAM := $(INSTALL) -m 755
INSTALL_DIR     := $(INSTALL) -d
# Common prefix for installation directories.  This directory must exist when
# you start the install.  Often overwrote from command line
# ("make prefix=... install") or using pre configuration
# ("./configure --prefix=...").
prefix      := /usr/local
# Root of the directory tree for read-only architecture-independent data files.
datarootdir := $(prefix)/share
# Directory for installing idiosyncratic read-only architecture-independent
# data files for this program (usually the same place as datarootdir).
datadir     := $(datarootdir)
# Where to put the executables, and directories used by the compiler if
# compilation is required.
exec_prefix := $(prefix)
bindir      := $(exec_prefix)/bin
libexecdir  := $(exec_prefix)/libexec
# Where to put the Info files.
infodir     := $(datarootdir)/info

# Custom variables for packaging this program.
PKGNAME    := select-monitor-layout
PKGDESC    := Select a monitor layout, powered by mons and rofi.
SCRIPT     := $(PKGNAME).sh
MANPAGE    := $(PKGNAME).1.gz
# Note: DESTDIR is empty by default, and is usually set up from command line
# ("make DESTDIR=... install").
LICENSEDIR := $(DESTDIR)$(datadir)/licenses/$(PKGNAME)
MANDIR     := $(DESTDIR)$(datadir)/man/man1
BINDIR     := $(DESTDIR)$(bindir)
BUILD_DIR  := build

# Declare non file targets.
.PHONY: install uninstall default

# Default target (because it's the first in the Makefile), used to forbid
# running make without an argument.
default:
	@echo 'Nothing to make, use "make install" or "make uninstall".'

# Create directories and install files: man pages, license file, libs and
# scripts.  Generating man pages are set as a prerequisite.
install: $(MANPAGE)
	$(PRE_INSTALL)     # Pre-install commands follow.
	$(NORMAL_INSTALL)  # Normal commands follow.
	$(INSTALL_DIR)     "$(LICENSEDIR)"
	$(INSTALL_DIR)     "$(MANDIR)"
	$(INSTALL_DIR)     "$(BINDIR)"
	$(INSTALL_DATA)    "LICENSE"                 "$(LICENSEDIR)/LICENSE"
	$(INSTALL_DATA)    "$(BUILD_DIR)/$(MANPAGE)" "$(MANDIR)/$(MANPAGE)"
	$(INSTALL_PROGRAM) "$(SCRIPT)"               "$(BINDIR)/$(PKGNAME)"
	$(POST_INSTALL)    # Post-install commands follow.

# Generate man page from script help and version outputs.
$(MANPAGE):
	help2man -N -n "$(PKGDESC)" --help-option="-h" --version-option="-v" \
		"./$(SCRIPT)" | gzip - > "$(BUILD_DIR)/$@"

# Remove installed files.
uninstall:
	$(PRE_UNINSTALL)     # Pre-uninstall commands follow.
	$(NORMAL_UNINSTALL)  # Normal commands follow.
	$(RM) -r "$(LICENSEDIR)"
	$(RM)    "$(MANDIR)/$(MANPAGE)" "$(BINDIR)/$(PKGNAME)"
	$(POST_UNINSTALL)    # Post-uninstall commands follow.

