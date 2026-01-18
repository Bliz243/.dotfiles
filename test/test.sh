#!/usr/bin/env bash
set -e

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
        ((PASS++))
    else
        echo "✗ $name"
        ((FAIL++))
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
echo "Testing: Zsh initialization..."
ZSH_OUTPUT=$(zsh -i -c 'echo "ZSH_OK"' 2>&1)
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

# Test 4: Neovim version is 0.11+
echo "Testing: Neovim version..."
NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
if [[ "$NVIM_MAJOR" -gt 0 ]] || [[ "$NVIM_MAJOR" -eq 0 && "$NVIM_MINOR" -ge 11 ]]; then
    test_result "Neovim 0.11+ ($NVIM_VERSION)" "pass"
else
    test_result "Neovim 0.11+ (got $NVIM_VERSION)" "fail"
fi

# Test 5: Neovim plugins sync
echo "Testing: Neovim plugins (this may take a moment)..."
NVIM_SYNC_OUTPUT=$(nvim --headless "+Lazy! sync" +qa 2>&1 || true)
if echo "$NVIM_SYNC_OUTPUT" | grep -qiE "(error|failed)"; then
    echo "  Plugin sync had errors"
    test_result "Neovim plugins sync" "fail"
else
    test_result "Neovim plugins sync" "pass"
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

echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
