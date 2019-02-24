#!/bin/bash
#------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2019 Mael Rimbault
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#------------------------------------------------------------------------------
#
# Select a monitor layout, powered by mons and rofi.
#
# Put bash on "strict mode".
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
# And: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# Immediately exit on any error.
set -o errexit
# Raise an error when using an undefined variable, instead of silently using
# the empty string.
set -o nounset
# Raise an error when any command involved in a pipe fails, not just the last
# one.
set -o pipefail
# Remove whitespace from default word split characters.
IFS=$'\n\t'

# Declare "die" function, used to exit with an error when preliminary checks
# fail on a script.
die() {
    local message
    message="$*"
    # FIXME also allow hints as arguments?
    # Find out what notify command to use.
    if command -v dunstify >/dev/null; then
        dunstify -a "$self" -u "critical" "$message"
    elif command -v notify-end >/dev/null; then
        notify-send -a "$self" -u "critical" "$message"
    else
        >&2 printf "ERROR: %s - %s" "${self}" "${message}"
    fi
    exit 1
}

# Declare function to send messages to the notification daemon.
notify_warn() {
    local message
    message="$*"
    # FIXME also allow hints as arguments?
    # Find out what notify command to use, and run it.
    if command -v dunstify >/dev/null; then
        # Defaults to dunstify if installed.
        dunstify -a "$self" -u "normal" "$message"
    elif command -v notify-end >/dev/null; then
        # If not, fall back to notify-send.
        notify-send -a "$self" -u "normal" "$message"
    else
        # If neither is installed, send message to stderr (but there is a fair
        # chance the message will end up completely lost).
        >&2 printf "WARNING: %s - %s" "${self}" "${message}"
    fi
}

# Print usage, formatted to generate man page using help2man.
print_usage() {

    printf 'Select a monitor layout, powered by mons and rofi.

Usage: %s [OPTION]

Without argument, it opens a rofi dmenu window containing several monitor
layout choices.

Supported options:
  -h    Prints this help and exits.
  -v    Prints version and exits.

Report bugs to <mael.rimbault@gmail.com>.
' "$self"

}

# Print version and copyright, formatted to generate man page using help2man.
print_version() {

    printf '%s %s

Copyright (C) 2019 Mael Rimbault.

License MIT: <https://opensource.org/licenses/MIT>.

Written by Mael Rimbault.
' "$self" "$version"

}

self="$(basename -s ".sh" "$0")"
version="0.1-dev"
# Define arrays used to store choices to be displayed and associated commands.
declare -A TITLES
declare -A COMMANDS

# Get script arguments.
while getopts 'hv' flag; do
  case "${flag}" in
    h) print_usage; exit 0 ;;
    v) print_version; exit 0 ;;
    *) print_usage
       die "Unknown option \"$flag\"." ;;
  esac
done

# Check if dependencies are installed.
if ! command -v mons >/dev/null; then
    die '"mons" utility must be installed.'
fi
if ! command -v rofi >/dev/null; then
    die '"rofi" utility must be installed.'
fi

# Detect number of available monitors.
mon_nb=$(mons | sed -n '/^Monitors:/ s/^Monitors:\s\+//p')
# Get verbose list of available monitors.
monitors="$(mons)"

# If only one monitor is connected (or none, obviously), no point to go
# further.
if [ "$mon_nb" -lt 2 ]; then
    notify_warn 'Only one monitor is connected.'
    exit 0
fi

# If more than two monitors are connected, don't allow to chose layouts.  mons
# allows to configure the layout for three monitors, but that would be a more
# complicated menu.  At this point, better use directly mons from a terminal.
if [ "$mon_nb" -gt 2 ]; then
    notify_warn 'More than two monitors are connected, use "mons" or "xrandr" to configure layout.'
    exit 0
fi

# Now we know we have two monitors available.  Prepare text to show on menu.
MESG="Choose the monitor layout.
<b>Escape</b> to cancel
<i>${monitors}</i>"

# List of layout choices.
COMMANDS['!o']="mons -o"
TITLES['!o']="Primary monitor only"
COMMANDS['!s']="mons -s"
TITLES['!s']="Secondary monitor only"
COMMANDS['!d']="mons -d"
TITLES['!d']="Duplicate monitors"
COMMANDS['!m']="mons -m"
TITLES['!m']="Mirror monitors"
COMMANDS['!l']="mons -e left"
TITLES['!l']="Dual, secondary monitor on the left"
COMMANDS['!r']="mons -e right"
TITLES['!r']="Dual, secondary monitor on the right"
COMMANDS['!b']="mons -e bottom"
TITLES['!b']="Dual, secondary monitor on the bottom"
COMMANDS['!t']="mons -e top"
TITLES['!t']="Dual, secondary monitor on the top"

# Generate text menu.
function print_menu() {
    # FIXME sort / align choices ?
    for key in "${!TITLES[@]}"; do
        printf "%s    %s\n" "$key" "${TITLES[$key]}"
    done
}

# Prompt text menu to rofi.  This function returns user's selected choice from
# the menu.
function start() {
    print_menu | rofi -dmenu -p "Layout" -mesg "$MESG"
}

# Run the main function.
value="$(start)"

# Split input, and grab up to first space.
choice=${value%%\ *}
# Graph remainder, minus space.
# FIXME unused?
#input=${value:$((${#choice}+1))}

# If there is no input, it means no choice was made.  This is probably due to
# the user cancelling the menu, so we exit cleanely.
if [ -z "${choice}" ]; then
    exit 0
fi

# A choice have been made, we check it is valid (ie it has a corresponding
# command).
if [ ${COMMANDS[$choice]+isset} ]; then
    # Execute the command associated to the choice.
    # FIXME eval parameters should be prefixed by a space (see "man eval").
    # FIXME why is eval necessary here?
    eval echo "Executing: ${COMMANDS[$choice]}"
    eval "${COMMANDS[$choice]}"
else
    # If the choice is not valid, prompt an error inside the rofi window.
    echo "Unknown command: ${choice}" | rofi -dmenu -p "Error"
fi

