# ============================================================================
# Auto-attach to tmux (conditional)
# ============================================================================

# Only auto-attach tmux if:
# - Not already in tmux
# - Not in VSCode integrated terminal
# - Not in SSH with X11 forwarding
# - Terminal is interactive
# - TMUX_AUTO_ATTACH is not set to "false"
if [[ -z "$TMUX" ]] && \
   [[ -z "$VSCODE_INJECTION" ]] && \
   [[ -z "$TERM_PROGRAM" ]] && \
   [[ "$TMUX_AUTO_ATTACH" != "false" ]] && \
   [[ $- == *i* ]] && \
   command -v tmux &> /dev/null; then

  # Try to attach to 'default' session, create if it doesn't exist
  tmux attach -t default 2>/dev/null || tmux new -s default
fi
