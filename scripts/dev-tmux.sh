#!/bin/bash

session="millionbithomepage"

tmux has-session -t $session 2>/dev/null

if [ $? != 0 ]; then
    tmux -2 new-session -d -s $session
    
    # GIT
    tmux new-window -t $session:1 -n 'git'
    tmux select-window -t $session:1
    tmux send-keys 'lazygit' C-m
    
    # dev server
    tmux new-window -t $session:2 -n 'devserver'
    tmux select-window -t $session:2
    tmux send-keys 'npm start' C-m
fi

tmux attach-session -t $session
