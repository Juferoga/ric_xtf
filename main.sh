#!/bin/bash

SCRIPT_NAME="ric_xtf.sh"

STDOUT_LOG="stdout.log"
STDERR_LOG="stderr_filtered.log"

> "$STDOUT_LOG"
> "$STDERR_LOG"

tmux new-session -d -s my_session

tmux split-window -h
tmux split-window -v

tmux send-keys -t 0 "bash '$SCRIPT_NAME' > '$STDOUT_LOG' 2> >(grep 'error' > '$STDERR_LOG')" Enter
tmux send-keys -t 1 "watch cat '$STDOUT_LOG'" Enter
tmux send-keys -t 2 "watch cat '$STDERR_LOG'" Enter

tmux attach-session -t my_session
