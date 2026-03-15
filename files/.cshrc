#!/bin/csh -X
#.cshrc file:    1998-10-02
# last revision: 2026-03-16
# author:        Ichiro Furusato

set INIT_ENABLED = 0  # if enabled cd to krzos and run diagnostics

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

if ( $INIT_ENABLED ) then

    set RED    = "\033[31m"
    set GREEN  = "\033[32m"
    set CYAN   = "\033[36m"
    set RESET  = "\033[0m"

    if ($?prompt) then
        echo "${CYAN}-- running .cshrc for user: `whoami`${RESET}"
        if ($?SSH_CONNECTION) then
            echo "${CYAN}-- SSH connection detected via SSH_CONNECTION.${RESET}"
            # get current user
            set user = `whoami`
            # count number of pts sessions for this user (remote SSH sessions)
            set n_sessions = `who | grep "$user" | grep -c 'pts/'`
            echo "${CYAN}-- found $n_sessions remote login(s).${RESET}"
            if ($n_sessions == 1) then
                echo "${GREEN}-- running diagnostics.py for first SSH session…${RESET}"
                cd ~/workspaces/workspace-krzos/krzos/
                ./diagnostics.py
            else
              echo "${CYAN}-- cd krzos workspace…${RESET}"
              cd ~/workspaces/workspace-krzos/krzos/
            endif
        else
            set login_source = "`who am i`"
            if ("$login_source" =~ *"pts/"*) then
                echo "${RED}-- SSH not detected via SSH_CONNECTION, but pts/ terminal suggests remote login.${RESET}"
            else
                echo "${GREEN}-- local or console login.${RESET}"
            endif
        endif
    endif
endif

#EOF
