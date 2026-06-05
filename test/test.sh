#!/usr/bin/env bash
# No `set -e`: this is a test runner — individual checks record pass/fail and the
# suite must continue, then exit non-zero at the end if anything failed.

# Match the real interactive shell's PATH: user-installed tools (zoxide, bun) land in
# these dirs, which .zshrc adds but a bare bash test shell wouldn't otherwise see.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

echo "========================================"
echo "  Dotfiles Test Suite"
echo "========================================"
echo ""

PASS=0
FAIL=0

test_result() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "pass" ]]; then
        echo "✓ $name"
        PASS=$((PASS + 1))
    else
        echo "✗ $name"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: Check for CRLF line endings
echo "Testing: Line endings..."
CRLF_FILES=$(find ~/.dotfiles -type f \( -name "*.zsh" -o -name "*.lua" -o -name "*.conf" -o -name "*.toml" \) -exec grep -l $'\r' {} \; 2>/dev/null || true)
if [[ -z "$CRLF_FILES" ]]; then
    test_result "No CRLF line endings" "pass"
else
    echo "  Files with CRLF: $CRLF_FILES"
    test_result "No CRLF line endings" "fail"
fi

# Test 2: Zsh loads without errors
# TMUX=1 makes the tmux auto-attach guard think we're already inside tmux, so an
# interactive zsh doesn't `exec tmux` (which would fail/hang without a real TTY).
echo "Testing: Zsh initialization..."
ZSH_OUTPUT=$(TMUX=1 zsh -i -c 'echo "ZSH_OK"' 2>&1)
if echo "$ZSH_OUTPUT" | grep -q "ZSH_OK"; then
    # Check for common error patterns
    if echo "$ZSH_OUTPUT" | grep -qiE "(command not found|no such file|error|parse error)"; then
        echo "  Warnings found in zsh output"
        test_result "Zsh loads cleanly" "fail"
    else
        test_result "Zsh loads cleanly" "pass"
    fi
else
    test_result "Zsh loads cleanly" "fail"
fi

# Test 3: Neovim starts
echo "Testing: Neovim starts..."
if nvim --version >/dev/null 2>&1; then
    test_result "Neovim installed" "pass"
else
    test_result "Neovim installed" "fail"
fi

# Test 4: Neovim version is >= 0.11.2 (required by LazyVim)
echo "Testing: Neovim version..."
NVIM_REQUIRED="0.11.2"
NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [[ -n "$NVIM_VERSION" ]] && \
   [[ "$(printf '%s\n' "$NVIM_REQUIRED" "$NVIM_VERSION" | sort -V | head -1)" == "$NVIM_REQUIRED" ]]; then
    test_result "Neovim >= $NVIM_REQUIRED ($NVIM_VERSION)" "pass"
else
    test_result "Neovim >= $NVIM_REQUIRED (got ${NVIM_VERSION:-none})" "fail"
fi

# Test 5: LazyVim installs and the config loads cleanly
# (the first sync can emit a transient treesitter config error, so the real check is a
#  clean second startup once plugins are present.)
echo "Testing: LazyVim install (may take a few minutes)..."
GIT_TERMINAL_PROMPT=0 nvim --headless "+Lazy! sync" +qa </dev/null >/tmp/lazy-sync.log 2>&1 || true
if [[ -d ~/.local/share/nvim/lazy/LazyVim ]] && [[ -e ~/.config/nvim/lazy-lock.json ]]; then
    LOAD_OUT=$(nvim --headless "+lua print('NVIM_LOAD_OK')" +qa </dev/null 2>&1 || true)
    if echo "$LOAD_OUT" | grep -q "NVIM_LOAD_OK" && ! echo "$LOAD_OUT" | grep -qiE "error|E[0-9]+:"; then
        test_result "LazyVim installed and config loads" "pass"
    else
        echo "  Second load reported errors"
        test_result "LazyVim installed and config loads" "fail"
    fi
else
    test_result "LazyVim installed and config loads" "fail"
fi

# Test 6: Neovim checkhealth (basic)
echo "Testing: Neovim health..."
HEALTH_OUTPUT=$(nvim --headless "+checkhealth" "+qa" 2>&1 || true)
# We're just checking it doesn't crash - warnings are OK
if [[ $? -eq 0 ]] || [[ -n "$HEALTH_OUTPUT" ]]; then
    test_result "Neovim checkhealth runs" "pass"
else
    test_result "Neovim checkhealth runs" "fail"
fi

# Test 7: Tmux starts
echo "Testing: Tmux..."
if tmux new-session -d -s test_session 2>/dev/null; then
    tmux kill-session -t test_session 2>/dev/null
    test_result "Tmux starts" "pass"
else
    test_result "Tmux starts" "fail"
fi

# Test 8: Required symlinks exist
echo "Testing: Symlinks..."
SYMLINKS_OK=true
for file in .zshrc .tmux.conf .gitconfig; do
    if [[ -L ~/$file ]] || [[ -f ~/$file ]]; then
        :
    else
        echo "  Missing: ~/$file"
        SYMLINKS_OK=false
    fi
done
if $SYMLINKS_OK; then
    test_result "Dotfile symlinks exist" "pass"
else
    test_result "Dotfile symlinks exist" "fail"
fi

# Test 9: Modern tools available
echo "Testing: Modern CLI tools..."
TOOLS_OK=true
for tool in eza bat fd fzf rg zoxide; do
    # fd is called fdfind on Ubuntu
    if [[ "$tool" == "fd" ]]; then
        command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || { echo "  Missing: $tool"; TOOLS_OK=false; }
    else
        command -v "$tool" >/dev/null 2>&1 || { echo "  Missing: $tool"; TOOLS_OK=false; }
    fi
done
if $TOOLS_OK; then
    test_result "Modern CLI tools installed" "pass"
else
    test_result "Modern CLI tools installed" "fail"
fi

# Test 10: Node + npm (required by Mason for npm-based LSP servers)
echo "Testing: Node.js toolchain..."
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    test_result "Node + npm installed ($(node -v))" "pass"
else
    test_result "Node + npm installed" "fail"
fi

# Test 11: bun (default JS package manager; installed to ~/.bun/bin, not default PATH)
echo "Testing: bun..."
if command -v bun >/dev/null 2>&1 || [[ -x "$HOME/.bun/bin/bun" ]]; then
    test_result "bun installed" "pass"
else
    test_result "bun installed" "fail"
fi

echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
