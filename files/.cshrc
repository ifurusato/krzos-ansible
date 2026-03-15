#!/bin/csh -X
#.cshrc file:    1998-10-02
# last revision: 2024-09-29
# author:        Murray Altheim

setenv USER_NAME pi

setenv VIM '/usr/share/vim'

echo "#\!/bin/csh" > ~/.LSCOLORS
dircolors -c ~/.dir_colors >> ~/.LSCOLORS
chmod 770 ~/.LSCOLORS
source ~/.LSCOLORS

set path = ( \
    . \
    ~/bin \
    ~/.local/bin \
    ~/.cargo/bin \
    /usr/local/sbin \
    /usr/local/bin \
    /usr/sbin \
    /usr/bin \
    /sbin \
    /bin \
    /usr/bin/X11 )
#   . )

if ( -f ~/.aliases ) source ~/.aliases
if ( -f ~/.prompt ) source ~/.prompt

umask 022

set INIT_ENABLED = 0
if ( $INIT_ENABLED ) then
    if ($?prompt) then

        echo "-- running .cshrc for user: `whoami`"

        if ($?SSH_CONNECTION) then
            echo "-- SSH connection detected via SSH_CONNECTION."

            # Get the current user
            set user = `whoami`

            # Count number of pts sessions for this user (remote SSH sessions)
            set n_sessions = `who | grep "$user" | grep -c 'pts/'`

            echo "Found $n_sessions remote login(s)."

            if ($n_sessions == 1) then
                echo "-- running init.py for first SSH session…"
                cd ~/workspaces/workspace-krzos/krzos/
                ./init.py
            else
              echo "-- cd krzos workspace…"
              cd ~/workspaces/workspace-krzos/krzos/

            endif
        else
            set login_source = "`who am i`"
            if ("$login_source" =~ *"pts/"*) then
                echo "-- SSH not detected via SSH_CONNECTION, but pts/ terminal suggests remote login."
            else
                echo "-- local or console login."
            endif
        endif
    endif
endif

#EOF
