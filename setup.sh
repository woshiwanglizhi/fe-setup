#!/bin/bash
#
# fe-setup — One-script frontend-dev environment setup (macOS / Debian / WSL)
#
# Platforms: macOS, Debian/Ubuntu, Windows (via WSL)
#
# Stack: Ghostty + (Fish or Zsh) + Starship + Nerd Font (MesloLGS)
# Tools: bat, eza, fd, ripgrep, btop, zoxide, jq, tldr, delta, lazygit, fzf
# Node:  fnm (Fast Node Manager) — works with both Fish and Zsh
# Theme: Catppuccin Mocha (Starship)
#
# Usage:
#   ./setup.sh                                      # interactive shell choice, terminal base only
#   ./setup.sh --fish                               # use Fish
#   ./setup.sh --zsh                                # use Zsh (with fish-like plugins)
#   ./setup.sh --dry-run                            # preview what would be done (no changes)
#
# Optional macOS-only extensions (opt-in, disabled by default):
#   --frontend    Install frontend CLI + GUI apps
#                 (pnpm / yarn / bun / gh / mkcert / nss + rectangle / keka / obsidian
#                  + google-chrome / cursor / visual-studio-code / arc when absent)
#   --ai          Clone + build OpenClaw (https://github.com/maoruiQa/open-claw-code)
#                 into ~/tools/open-claw
#   --accounts    Configure git identity + generate SSH ed25519 key + ssh-agent keychain
#                 + npm npmmirror registry + Finder preferences
#                 + Cursor agent-done notification hook (~/.cursor/hooks.json)
#   --full        Shorthand for --frontend --ai --accounts
#   --name  X     Git user.name  (with --accounts; or export SETUP_GIT_NAME)
#   --email X     Git user.email (with --accounts; or export SETUP_GIT_EMAIL)
#
# Examples:
#   ./setup.sh --zsh --full                                    # everything, asks for name/email
#   ./setup.sh --zsh --full --name "Your Name" --email y@z.com # everything, fully non-interactive
#   ./setup.sh --zsh --frontend                                # terminal + frontend CLI/GUI only
#   ./setup.sh --dry-run --full                                # preview the full flow
#

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Dry-run support ────────────────────────────────────────────────
DRY_RUN=false

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# run_cmd: execute a command, or just print it in dry-run mode
run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# ─── Parse Arguments ────────────────────────────────────────────────
SHELL_CHOICE=""
INSTALL_FRONTEND=false
INSTALL_AI=false
INSTALL_ACCOUNTS=false
GIT_NAME=""
GIT_EMAIL=""

# Use while+shift so we can accept value-bearing flags (--name X / --email Y).
# Equals-style (--name=X / --email=Y) is also supported for convenience.
while (( $# )); do
    case "$1" in
        --fish)       SHELL_CHOICE="fish" ;;
        --zsh)        SHELL_CHOICE="zsh" ;;
        --dry-run)    DRY_RUN=true ;;
        --frontend)   INSTALL_FRONTEND=true ;;
        --ai)         INSTALL_AI=true ;;
        --accounts)   INSTALL_ACCOUNTS=true ;;
        --full)       INSTALL_FRONTEND=true; INSTALL_AI=true; INSTALL_ACCOUNTS=true ;;
        --name)       GIT_NAME="${2:-}";  shift ;;
        --name=*)     GIT_NAME="${1#*=}" ;;
        --email)      GIT_EMAIL="${2:-}"; shift ;;
        --email=*)    GIT_EMAIL="${1#*=}" ;;
        -h|--help)
            grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            warn "Unknown argument: $1 (ignored)"
            ;;
    esac
    shift
done

if $DRY_RUN; then
    echo ""
    echo -e "${YELLOW}${BOLD}  ⚠  DRY-RUN MODE — no changes will be made${NC}"
    echo ""
fi

# ─── OS Detection ───────────────────────────────────────────────────
# Possible values: macos, debian, wsl, unsupported
detect_os() {
    local uname_out
    uname_out="$(uname -s)"

    case "$uname_out" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            # Check if running inside WSL
            if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
                echo "wsl"
            elif [[ -f /etc/debian_version ]] || grep -qi 'debian\|ubuntu' /etc/os-release 2>/dev/null; then
                echo "debian"
            else
                echo "unsupported"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows-native"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

OS="$(detect_os)"

case "$OS" in
    macos)
        info "Detected ${BOLD}macOS${NC}"
        ;;
    debian)
        info "Detected ${BOLD}Debian/Ubuntu Linux${NC}"
        ;;
    wsl)
        info "Detected ${BOLD}Windows WSL${NC} (Debian/Ubuntu layer)"
        ;;
    windows-native)
        error "Native Windows (MINGW/MSYS/Cygwin) is not supported.\n  Please install WSL: https://learn.microsoft.com/en-us/windows/wsl/install\n  Then run this script inside WSL."
        ;;
    *)
        error "Unsupported OS: $(uname -s)\n  This script supports macOS, Debian/Ubuntu, and Windows WSL."
        ;;
esac

# ─── Shell Choice ────────────────────────────────────────────────────
if [[ -z "$SHELL_CHOICE" ]]; then
    echo ""
    echo -e "${BOLD}Which shell do you want to use?${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Fish${NC}  — Modern shell, amazing defaults, not POSIX"
    echo -e "  ${GREEN}2)${NC} ${BOLD}Zsh${NC}   — POSIX-compatible, fish-like with plugins"
    echo ""
    while true; do
        read -rp "Choose [1/2]: " choice
        case "$choice" in
            1|fish) SHELL_CHOICE="fish"; break ;;
            2|zsh)  SHELL_CHOICE="zsh"; break ;;
            *) echo "Please enter 1 or 2." ;;
        esac
    done
fi

echo ""
info "Setting up with ${BOLD}${SHELL_CHOICE}${NC} on ${BOLD}${OS}${NC}"

# ─── Config Directory ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

# If running via curl pipe (no local configs dir), clone the repo first
if [[ ! -d "$CONFIGS_DIR" ]]; then
    info "Config files not found locally, cloning repo..."
    TMPDIR_CLONE="$(mktemp -d)"
    git clone --depth 1 https://github.com/woshiwanglizhi/fe-setup.git "$TMPDIR_CLONE/fe-setup"
    SCRIPT_DIR="$TMPDIR_CLONE/fe-setup"
    CONFIGS_DIR="$SCRIPT_DIR/configs"
fi

# ═══════════════════════════════════════════════════════════════════════
# Helper Functions (cross-platform)
# ═══════════════════════════════════════════════════════════════════════

# Install a package using the appropriate package manager
pkg_install() {
    local pkg="$1"
    case "$OS" in
        macos)
            if brew list "$pkg" &>/dev/null; then
                success "$pkg already installed"
                return 0
            fi
            info "Installing $pkg..."
            run_cmd brew install "$pkg"
            ;;
        debian|wsl)
            if dpkg -s "$pkg" &>/dev/null 2>&1; then
                success "$pkg already installed"
                return 0
            fi
            info "Installing $pkg..."
            run_cmd sudo apt-get install -y "$pkg"
            ;;
    esac
    success "$pkg installed"
}

# Install a cask (macOS only, no-op on Linux)
cask_install() {
    local cask="$1"
    if [[ "$OS" != "macos" ]]; then
        warn "Cask install is macOS-only, skipping $cask on $OS"
        return 0
    fi
    if brew list --cask "$cask" &>/dev/null; then
        success "$cask already installed"
        return 0
    fi
    info "Installing $cask..."
    run_cmd brew install --cask "$cask"
    success "$cask installed"
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# fnm_install_with_retry: install a Node.js version via fnm with retries.
#
# Why this exists:
#   fnm streams the tarball download and extracts it on the fly. If the network
#   hiccups mid-stream, fnm reports a misleading error like:
#     "Can't extract the file: failed to unpack .../bin/node"
#   (bin/node is the last, 120MB+ entry in the Node tarball — most likely
#   to get truncated). A leftover .downloads/.tmp* dir can also poison
#   subsequent attempts. Cleaning tmp dirs and retrying almost always works.
#
# Usage: fnm_install_with_retry --lts
#        fnm_install_with_retry 22
fnm_install_with_retry() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} fnm install $*"
        return 0
    fi

    local max_attempts=3
    local downloads_dir=""
    if [[ -n "${FNM_DIR:-}" ]]; then
        downloads_dir="$FNM_DIR/node-versions/.downloads"
    fi

    local attempt
    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        if (( attempt > 1 )); then
            warn "fnm install attempt $((attempt - 1)) failed — cleaning tmp and retrying ($attempt/$max_attempts)..."
            if [[ -n "$downloads_dir" && -d "$downloads_dir" ]]; then
                find "$downloads_dir" -mindepth 1 -maxdepth 1 -name '.tmp*' -exec rm -rf {} + 2>/dev/null || true
                find "$downloads_dir" -mindepth 1 -maxdepth 1 -name 'tmp*'  -exec rm -rf {} + 2>/dev/null || true
            fi
            sleep 2
        fi

        if fnm install "$@"; then
            return 0
        fi
    done

    warn "fnm install $* failed after $max_attempts attempts."
    warn "This usually means network instability while streaming the Node tarball."
    warn "You can retry manually: fnm install $*"
    warn "Or fall back to: brew install node    (macOS)  /  apt install nodejs npm  (Debian/WSL)"
    return 1
}

# ─── Step 0: Xcode Command Line Tools (macOS prerequisite) ──────────
# Homebrew and almost every other build on macOS depends on the CLT (git,
# clang, make, ...). We install it BEFORE Step 1, because `brew install`
# would otherwise fail mid-way.
if [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🛠  Step 0: Xcode Command Line Tools${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"

    if xcode-select -p >/dev/null 2>&1; then
        success "Xcode CLT already installed ($(xcode-select -p))"
    else
        info "Xcode Command Line Tools not found — triggering installer..."
        if $DRY_RUN; then
            echo -e "${YELLOW}[DRY-RUN]${NC} xcode-select --install"
        else
            # `xcode-select --install` pops a GUI dialog and returns immediately,
            # so it cannot be blocked on. Wait for the user to finish before
            # continuing, otherwise Step 1 (Homebrew) will fail.
            xcode-select --install 2>/dev/null || true
            warn "A macOS dialog should appear. Click 'Install' and wait for completion (5-10 min)."
            if [[ -r /dev/tty ]]; then
                printf "Press RETURN once the installation has finished: " > /dev/tty
                read -r _ < /dev/tty
            else
                warn "No TTY available — sleeping 120s to give the installer a chance."
                sleep 120
            fi

            if ! xcode-select -p >/dev/null 2>&1; then
                error "Xcode CLT still not detected.\n  Please finish the installer and re-run this script."
            fi
            success "Xcode CLT installed ($(xcode-select -p))"
        fi
    fi
fi

# ─── Step 1: Package Manager ────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  📦 Step 1/9: Package Manager${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

case "$OS" in
    macos)
        # Helper: load brew into current shell's PATH (both Apple Silicon and Intel layouts)
        load_brew_shellenv() {
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        }

        if ! has_cmd brew; then
            info "Installing Homebrew..."

            # Homebrew's official installer reads RETURN + sudo password from stdin.
            # If THIS script was invoked via a pipe (e.g. `printf ... | bash ...` or
            # `bash <(curl ...) < some-file`), its stdin is already consumed, and the
            # Homebrew installer would see an unexpected byte and silently abort.
            # Workaround: redirect the installer's stdin to /dev/tty so it can prompt
            # the real user. If no TTY is available (true non-interactive environment),
            # fall back to Homebrew's own NONINTERACTIVE mode (requires passwordless sudo).
            if [[ -r /dev/tty ]]; then
                run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
            else
                warn "No TTY available — running Homebrew installer with NONINTERACTIVE=1."
                warn "This requires passwordless sudo; if it fails, install Homebrew manually first."
                NONINTERACTIVE=1 run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            # Load brew into current shell
            load_brew_shellenv

            # Post-install verification: the official installer sometimes exits 0
            # even when the install was aborted (e.g. wrong password, stdin consumed).
            # Explicitly verify that the brew binary actually exists and works.
            if ! has_cmd brew; then
                error "Homebrew installation failed — \`brew\` not found on PATH.\n  Please install it manually:\n    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n  Then re-run this script."
            fi

            success "Homebrew installed ($(brew --prefix))"
        else
            # Even when brew is already installed, make sure it's loaded into the
            # current shell's PATH — the script may be running in a subshell that
            # didn't source ~/.zprofile / ~/.bash_profile.
            load_brew_shellenv
            success "Homebrew already installed ($(brew --prefix))"
        fi
        ;;
    debian|wsl)
        info "Updating apt package index..."
        run_cmd sudo apt-get update
        # Ensure basic build tools are available
        pkg_install "curl"
        pkg_install "git"
        pkg_install "wget"
        pkg_install "unzip"
        pkg_install "build-essential"
        success "apt package manager ready"
        ;;
esac

# ─── Step 2: Terminal Emulator ───────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  👻 Step 2/9: Terminal Emulator${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

case "$OS" in
    macos)
        if [[ ! -d "/Applications/Ghostty.app" ]]; then
            info "Installing Ghostty..."
            run_cmd brew install --cask ghostty
            success "Ghostty installed"
        else
            success "Ghostty already installed"
        fi
        ;;
    debian)
        # Ghostty on Linux: check if already installed, otherwise try snap/flatpak or skip
        if has_cmd ghostty; then
            success "Ghostty already installed"
        else
            warn "Ghostty is not easily available on Linux via apt."
            echo -e "  Options to install Ghostty on Linux:"
            echo -e "    • Snap:    ${BOLD}sudo snap install ghostty${NC}"
            echo -e "    • Build:   ${BOLD}https://ghostty.org/docs/install/build${NC}"
            echo -e "    • Or use any other terminal (kitty, alacritty, etc.)"
            echo ""
            info "Skipping Ghostty installation — install it manually if desired."
        fi
        ;;
    wsl)
        info "WSL detected — terminal emulator runs on the Windows side."
        echo -e "  Install Ghostty for Windows: ${BOLD}https://ghostty.org${NC}"
        echo -e "  Or use Windows Terminal, which works great with WSL."
        info "Skipping terminal emulator installation."
        ;;
esac

# ─── Step 3: Nerd Font (MesloLGS NF) ────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🔤 Step 3/9: Nerd Font (MesloLGS NF)${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

# Determine font directory based on OS
case "$OS" in
    macos)
        FONT_DIR="$HOME/Library/Fonts"
        ;;
    debian|wsl)
        FONT_DIR="$HOME/.local/share/fonts"
        ;;
esac

MESLO_FONTS=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)

# Font source: bundled in repo (fonts/) — no download needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_SRC_DIR="$SCRIPT_DIR/fonts"

FONT_INSTALLED=true
for font in "${MESLO_FONTS[@]}"; do
    [[ ! -f "$FONT_DIR/$font" ]] && FONT_INSTALLED=false && break
done

if $FONT_INSTALLED; then
    success "MesloLGS NF fonts already installed"
else
    info "Installing MesloLGS NF fonts from repo..."
    mkdir -p "$FONT_DIR"
    for font in "${MESLO_FONTS[@]}"; do
        if [[ -f "$FONT_SRC_DIR/$font" ]]; then
            run_cmd cp "$FONT_SRC_DIR/$font" "$FONT_DIR/$font"
        else
            warn "Font not found in repo: $font — skipping"
        fi
    done
    # Rebuild font cache on Linux
    if [[ "$OS" == "debian" || "$OS" == "wsl" ]]; then
        if has_cmd fc-cache; then
            run_cmd fc-cache -fv "$FONT_DIR"
        fi
    fi
    success "MesloLGS NF fonts installed"
fi

# ─── Step 4: Shell ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    echo -e "${BOLD}  🐟 Step 4/9: Fish Shell${NC}"
else
    echo -e "${BOLD}  🐚 Step 4/9: Zsh + Fish-like Plugins${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════${NC}"

install_shell_macos() {
    if [[ "$SHELL_CHOICE" == "fish" ]]; then
        if ! has_cmd fish; then
            info "Installing Fish..."
            run_cmd brew install fish
            success "Fish installed"
        else
            success "Fish already installed"
        fi

        FISH_PATH="$(which fish)"
        if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
            info "Adding Fish to /etc/shells (may need sudo)..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi

        if [[ "$SHELL" != "$FISH_PATH" ]]; then
            info "Setting Fish as default shell..."
            run_cmd chsh -s "$FISH_PATH"
            success "Default shell changed to Fish"
        else
            success "Fish is already the default shell"
        fi
    else
        # Zsh is pre-installed on macOS, just install the plugins
        local plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
        for plugin in "${plugins[@]}"; do
            if brew list "$plugin" &>/dev/null; then
                success "$plugin already installed"
            else
                info "Installing $plugin..."
                run_cmd brew install "$plugin"
                success "$plugin installed"
            fi
        done

        ZSH_PATH="$(which zsh)"
        if [[ "$SHELL" != "$ZSH_PATH" ]]; then
            info "Setting Zsh as default shell..."
            run_cmd chsh -s "$ZSH_PATH"
            success "Default shell changed to Zsh"
        else
            success "Zsh is already the default shell"
        fi
    fi
}

install_shell_linux() {
    if [[ "$SHELL_CHOICE" == "fish" ]]; then
        if ! has_cmd fish; then
            # Fish PPA for latest version on Ubuntu/Debian
            if [[ -f /etc/lsb-release ]] && grep -qi ubuntu /etc/lsb-release 2>/dev/null; then
                info "Adding Fish PPA for latest version..."
                run_cmd sudo apt-add-repository -y ppa:fish-shell/release-3
                run_cmd sudo apt-get update
            fi
            info "Installing Fish..."
            run_cmd sudo apt-get install -y fish
            success "Fish installed"
        else
            success "Fish already installed"
        fi

        FISH_PATH="$(which fish)"
        if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
            info "Adding Fish to /etc/shells..."
            echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi

        if [[ "$SHELL" != "$FISH_PATH" ]]; then
            info "Setting Fish as default shell..."
            run_cmd chsh -s "$FISH_PATH"
            success "Default shell changed to Fish"
        else
            success "Fish is already the default shell"
        fi
    else
        # Install Zsh if not present
        if ! has_cmd zsh; then
            info "Installing Zsh..."
            run_cmd sudo apt-get install -y zsh
            success "Zsh installed"
        else
            success "Zsh already installed"
        fi

        # Install Zsh plugins from apt or git clone
        local ZSH_PLUGINS_DIR="/usr/share"
        local need_clone=false

        # zsh-autosuggestions
        if [[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
            success "zsh-autosuggestions already installed"
        elif dpkg -s zsh-autosuggestions &>/dev/null 2>&1; then
            success "zsh-autosuggestions already installed"
        else
            info "Installing zsh-autosuggestions..."
            run_cmd sudo apt-get install -y zsh-autosuggestions 2>/dev/null || {
                info "apt package not available, cloning from git..."
                run_cmd sudo git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
            }
            success "zsh-autosuggestions installed"
        fi

        # zsh-syntax-highlighting
        if [[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
            success "zsh-syntax-highlighting already installed"
        elif dpkg -s zsh-syntax-highlighting &>/dev/null 2>&1; then
            success "zsh-syntax-highlighting already installed"
        else
            info "Installing zsh-syntax-highlighting..."
            run_cmd sudo apt-get install -y zsh-syntax-highlighting 2>/dev/null || {
                info "apt package not available, cloning from git..."
                run_cmd sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
            }
            success "zsh-syntax-highlighting installed"
        fi

        ZSH_PATH="$(which zsh)"
        if [[ "$SHELL" != "$ZSH_PATH" ]]; then
            info "Setting Zsh as default shell..."
            run_cmd chsh -s "$ZSH_PATH"
            success "Default shell changed to Zsh"
        else
            success "Zsh is already the default shell"
        fi
    fi
}

case "$OS" in
    macos)  install_shell_macos ;;
    debian|wsl) install_shell_linux ;;
esac

# ─── Step 5: CLI Tools ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🛠  Step 5/9: CLI Tools${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

install_cli_tools_macos() {
    local TOOLS=(bat eza fd ripgrep btop zoxide jq tldr git-delta lazygit fzf)
    for tool in "${TOOLS[@]}"; do
        if brew list "$tool" &>/dev/null; then
            success "$tool already installed"
        else
            info "Installing $tool..."
            run_cmd brew install "$tool"
            success "$tool installed"
        fi
    done
}

install_cli_tools_linux() {
    # Tools available directly from apt (on modern Debian/Ubuntu)
    local APT_TOOLS=(bat fd-find ripgrep jq fzf)

    for tool in "${APT_TOOLS[@]}"; do
        if dpkg -s "$tool" &>/dev/null 2>&1; then
            success "$tool already installed"
        else
            info "Installing $tool..."
            run_cmd sudo apt-get install -y "$tool"
            success "$tool installed"
        fi
    done

    # btop — not in apt on older Debian/Ubuntu, use snap as fallback
    if has_cmd btop; then
        success "btop already installed"
    else
        info "Installing btop..."
        if run_cmd sudo apt-get install -y btop 2>/dev/null; then
            success "btop installed via apt"
        elif has_cmd snap; then
            info "btop not in apt, trying snap..."
            run_cmd sudo snap install btop
            success "btop installed via snap"
        else
            warn "btop not available via apt or snap — skipping (install manually: https://github.com/aristocratos/btop)"
        fi
    fi

    # zoxide — not in apt on older Debian/Ubuntu, use bundled installer as fallback
    if has_cmd zoxide; then
        success "zoxide already installed"
    else
        info "Installing zoxide..."
        if run_cmd sudo apt-get install -y zoxide 2>/dev/null; then
            success "zoxide installed via apt"
        elif has_cmd snap && run_cmd sudo snap install zoxide 2>/dev/null; then
            success "zoxide installed via snap"
        else
            info "zoxide not in apt/snap, using bundled installer..."
            run_cmd bash "$SCRIPT_DIR/scripts/install-zoxide.sh"
            success "zoxide installed via bundled script"
        fi
    fi

    # bat is installed as 'batcat' on Debian/Ubuntu — create symlink
    if has_cmd batcat && ! has_cmd bat; then
        info "Creating symlink: batcat → bat"
        mkdir -p "$HOME/.local/bin"
        run_cmd ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        success "bat symlink created"
    fi

    # fd is installed as 'fdfind' on Debian/Ubuntu — create symlink
    if has_cmd fdfind && ! has_cmd fd; then
        info "Creating symlink: fdfind → fd"
        mkdir -p "$HOME/.local/bin"
        run_cmd ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        success "fd symlink created"
    fi

    # Helper: install bundled binary from bin/linux-x86_64/
    install_bundled_bin() {
        local name="$1"
        if [[ -f "$SCRIPT_DIR/bin/linux-x86_64/$name" ]]; then
            run_cmd sudo cp "$SCRIPT_DIR/bin/linux-x86_64/$name" "/usr/local/bin/$name"
            run_cmd sudo chmod +x "/usr/local/bin/$name"
            success "$name installed from bundled binary"
            return 0
        fi
        return 1
    }

    # eza — try apt first, then bundled binary
    if has_cmd eza; then
        success "eza already installed"
    else
        info "Installing eza..."
        if run_cmd sudo apt-get install -y eza 2>/dev/null; then
            success "eza installed via apt"
        else
            install_bundled_bin eza || warn "Could not install eza — skipping"
        fi
    fi

    # tldr (tealdeer) — try apt first, then bundled binary
    if has_cmd tldr; then
        success "tldr already installed"
    else
        info "Installing tldr..."
        if run_cmd sudo apt-get install -y tealdeer 2>/dev/null; then
            success "tldr installed via apt"
        else
            install_bundled_bin tldr || warn "Could not install tldr — skipping"
        fi
    fi

    # git-delta — try apt first, then bundled binary
    if has_cmd delta; then
        success "git-delta already installed"
    else
        info "Installing git-delta..."
        if run_cmd sudo apt-get install -y git-delta 2>/dev/null; then
            success "git-delta installed via apt"
        else
            install_bundled_bin delta || warn "Could not install git-delta — skipping"
        fi
    fi

    # lazygit — try apt first, then bundled binary
    if has_cmd lazygit; then
        success "lazygit already installed"
    else
        info "Installing lazygit..."
        if run_cmd sudo apt-get install -y lazygit 2>/dev/null; then
            success "lazygit installed via apt"
        else
            install_bundled_bin lazygit || warn "Could not install lazygit — skipping"
        fi
    fi

    # Ensure ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

case "$OS" in
    macos)      install_cli_tools_macos ;;
    debian|wsl) install_cli_tools_linux ;;
esac

# ─── Step 6: Starship Prompt ────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🚀 Step 6/9: Starship Prompt${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if has_cmd starship; then
    success "Starship already installed"
else
    case "$OS" in
        macos)
            info "Installing Starship..."
            run_cmd brew install starship
            ;;
        debian|wsl)
            info "Installing Starship..."
            if [[ -f "$SCRIPT_DIR/bin/linux-x86_64/starship" ]]; then
                run_cmd sudo cp "$SCRIPT_DIR/bin/linux-x86_64/starship" /usr/local/bin/starship
                run_cmd sudo chmod +x /usr/local/bin/starship
            else
                run_cmd sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
            fi
            ;;
    esac
    success "Starship installed"
fi

# ─── Step 7: fnm + Node.js (optional) ───────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🟢 Step 7/9: fnm + Node.js (optional)${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if has_cmd fnm; then
    success "fnm already installed"
    # Load fnm in current shell so we can install Node
    eval "$(fnm env --use-on-cd --shell bash)"
    if ! fnm list 2>/dev/null | grep -q lts; then
        info "Installing Node LTS..."
        if fnm_install_with_retry --lts; then
            run_cmd fnm default lts-latest
            run_cmd fnm use lts-latest
            success "Node LTS installed and set as default"
        else
            warn "Skipping Node LTS install — you can retry later with: fnm install --lts"
        fi
    else
        success "Node LTS already installed"
    fi
else
    echo ""
    echo -e "  ${YELLOW}⚠ WARNING: fnm manages its own Node.js versions.${NC}"
    echo -e "  ${YELLOW}  If you already have Node.js installed (e.g. via nvm, Homebrew, or system),${NC}"
    echo -e "  ${YELLOW}  fnm may shadow your existing Node/npm and tools installed globally${NC}"
    echo -e "  ${YELLOW}  (e.g. Claude Code, Codex CLI, pnpm global packages).${NC}"
    echo -e "  ${YELLOW}  Only install fnm if you need to manage multiple Node versions.${NC}"
    echo ""
    printf "  Install fnm + Node.js? (y/N, default: N): "
    read -r INSTALL_FNM
    if [[ "$INSTALL_FNM" =~ ^[Yy]$ ]]; then
        case "$OS" in
            macos)
                info "Installing fnm (Fast Node Manager)..."
                run_cmd brew install fnm
                ;;
            debian|wsl)
                info "Installing fnm via official installer..."
                run_cmd bash -c "$(curl -fsSL https://fnm.vercel.app/install)" -- --skip-shell
                export PATH="$HOME/.local/share/fnm:$PATH"
                ;;
        esac
        success "fnm installed"

        # Load fnm in current shell so we can install Node
        if has_cmd fnm; then
            eval "$(fnm env --use-on-cd --shell bash)"
            info "Installing Node LTS..."
            if fnm_install_with_retry --lts; then
                run_cmd fnm default lts-latest
                run_cmd fnm use lts-latest
                success "Node LTS installed and set as default"
            else
                warn "Skipping Node LTS install — you can retry later with: fnm install --lts"
            fi
        fi
    else
        info "Skipping fnm + Node.js"
    fi
fi

# Extra: Node 20 as a fallback for legacy projects — only if fnm is usable.
# Runs for everyone (not gated by --frontend): it costs ~40MB and matches
# how we actually set the machine up (Node 22 default + Node 20 fallback).
if has_cmd fnm; then
    # Make sure fnm's env is loaded in this (bash) subshell; the Step 7 branches
    # that skipped Node LTS install may have left us without fnm's shims.
    eval "$(fnm env --use-on-cd --shell bash)" 2>/dev/null || true

    if fnm list 2>/dev/null | grep -qE '^\s*\*?\s*v20\.'; then
        success "Node v20 already installed (legacy project fallback)"
    else
        info "Installing Node v20 (fallback for legacy projects)..."
        if fnm_install_with_retry 20; then
            success "Node v20 installed"
        else
            warn "Skipped Node v20 — you can retry manually: fnm install 20"
        fi
    fi
fi

# ─── Step 8: Zellij (optional) ──────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🪟 Step 8/9: Zellij (optional)${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if has_cmd zellij; then
    success "Zellij already installed"
else
    echo ""
    echo -e "  Zellij is a modern terminal multiplexer (like tmux, but better UX)."
    printf "  Install Zellij? (y/N): "
    read -r INSTALL_ZELLIJ
    if [[ "$INSTALL_ZELLIJ" =~ ^[Yy]$ ]]; then
        case "$OS" in
            macos)
                info "Installing Zellij..."
                run_cmd brew install zellij
                ;;
            debian|wsl)
                info "Installing Zellij..."
                if [[ -f "$SCRIPT_DIR/bin/linux-x86_64/zellij" ]]; then
                    run_cmd sudo cp "$SCRIPT_DIR/bin/linux-x86_64/zellij" /usr/local/bin/zellij
                    run_cmd sudo chmod +x /usr/local/bin/zellij
                else
                    # Use official installer
                    if $DRY_RUN; then
                        echo -e "${YELLOW}[DRY-RUN]${NC} curl -L https://zellij.dev/launch | bash"
                    else
                        curl -L https://zellij.dev/launch | bash
                    fi
                fi
                ;;
        esac
        success "Zellij installed"
    else
        info "Skipping Zellij"
    fi
fi

# ─── Step 9: Config Files ───────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  📦 Step 9/9: Deploying Configs${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

# --- Ghostty config ---
deploy_ghostty_config() {
    local ghostty_config_dir
    case "$OS" in
        macos)
            ghostty_config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
            ;;
        debian)
            ghostty_config_dir="$HOME/.config/ghostty"
            ;;
        wsl)
            info "Ghostty config: configure on the Windows side if using Ghostty for Windows."
            info "Deploying Linux-side config to ~/.config/ghostty/ for reference."
            ghostty_config_dir="$HOME/.config/ghostty"
            ;;
    esac

    mkdir -p "$ghostty_config_dir"
    if [[ -f "$ghostty_config_dir/config" ]] || [[ -f "$ghostty_config_dir/config.ghostty" ]]; then
        local existing
        existing="$(ls "$ghostty_config_dir"/config* 2>/dev/null | head -1)"
        run_cmd cp "$existing" "${existing}.bak.$(date +%s)"
        warn "Backed up existing Ghostty config"
    fi

    # macOS uses config.ghostty, Linux uses config
    case "$OS" in
        macos)
            run_cmd cp "$CONFIGS_DIR/ghostty.config" "$ghostty_config_dir/config.ghostty"
            ;;
        debian|wsl)
            run_cmd cp "$CONFIGS_DIR/ghostty.config" "$ghostty_config_dir/config"
            ;;
    esac
    success "Ghostty config deployed"
}

deploy_ghostty_config

# --- Cursor / VSCode integrated-terminal font ---
#
# Why this exists:
#   Cursor and VSCode ship their own settings.json and independently control
#   the integrated terminal's font. Installing MesloLGS NF system-wide is not
#   enough — without "terminal.integrated.fontFamily" they fall back to Menlo
#   and Starship's Nerd Font icons render as empty boxes.
_apply_ide_terminal_font() {
    local settings_path="$1"
    local font_value="$2"
    local ide_label
    ide_label="$(basename "$(dirname "$(dirname "$settings_path")")")"

    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Set $ide_label terminal.integrated.fontFamily -> $font_value"
        return 0
    fi

    mkdir -p "$(dirname "$settings_path")"

    # New install — write a minimal settings.json.
    if [[ ! -f "$settings_path" ]]; then
        printf '{\n    "terminal.integrated.fontFamily": "%s"\n}\n' "$font_value" > "$settings_path"
        success "$ide_label settings.json created with MesloLGS NF"
        return 0
    fi

    cp "$settings_path" "${settings_path}.bak.$(date +%s)"

    if ! command -v python3 &>/dev/null; then
        warn "python3 not found — cannot merge $ide_label settings.json automatically."
        warn "  Manually add: \"terminal.integrated.fontFamily\": \"$font_value\""
        return 0
    fi

    # Python merges in-place. JSONC (// and /* */ comments) is tolerated;
    # if the file is still unparseable (trailing commas etc.), we warn and skip.
    if python3 - "$settings_path" "$font_value" <<'PY'
import json, sys

path, value = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as f:
    raw = f.read()

def strip_jsonc(s):
    out, i, n = [], 0, len(s)
    in_str = esc = False
    while i < n:
        c = s[i]
        if in_str:
            out.append(c)
            if esc:            esc = False
            elif c == '\\':   esc = True
            elif c == '"':    in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if c == '/' and i + 1 < n:
            nxt = s[i + 1]
            if nxt == '/':
                while i < n and s[i] != '\n':
                    i += 1
                continue
            if nxt == '*':
                i += 2
                while i + 1 < n and not (s[i] == '*' and s[i + 1] == '/'):
                    i += 1
                i += 2; continue
        out.append(c); i += 1
    return ''.join(out)

try:
    data = json.loads(strip_jsonc(raw)) if raw.strip() else {}
except Exception as e:
    print(f"parse error: {e}", file=sys.stderr)
    sys.exit(2)

if not isinstance(data, dict):
    print("settings.json is not a JSON object", file=sys.stderr)
    sys.exit(2)

key = "terminal.integrated.fontFamily"
if data.get(key) == value:
    sys.exit(3)  # already up-to-date

data[key] = value
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write('\n')
PY
    then
        success "$ide_label integrated terminal font set to MesloLGS NF"
    else
        local rc=$?
        case $rc in
            3) success "$ide_label integrated terminal font already set" ;;
            2) warn  "$ide_label settings.json couldn't be parsed; add manually:"
               warn  "  \"terminal.integrated.fontFamily\": \"$font_value\"" ;;
            *) warn  "$ide_label settings.json update failed (exit $rc); add manually:"
               warn  "  \"terminal.integrated.fontFamily\": \"$font_value\"" ;;
        esac
    fi
}

deploy_ide_terminal_font() {
    local font_value="MesloLGS NF, Menlo, Monaco, monospace"
    local candidates=()

    case "$OS" in
        macos)
            candidates+=("$HOME/Library/Application Support/Cursor/User/settings.json")
            candidates+=("$HOME/Library/Application Support/Code/User/settings.json")
            candidates+=("$HOME/Library/Application Support/Code - Insiders/User/settings.json")
            ;;
        debian)
            candidates+=("$HOME/.config/Cursor/User/settings.json")
            candidates+=("$HOME/.config/Code/User/settings.json")
            candidates+=("$HOME/.config/Code - Insiders/User/settings.json")
            ;;
        wsl)
            info "Cursor/VSCode usually runs on the Windows host in WSL setups."
            info "  Add to the Windows-side settings.json manually:"
            info "  \"terminal.integrated.fontFamily\": \"$font_value\""
            return 0
            ;;
    esac

    local any_found=false
    local settings_path parent_dir
    for settings_path in "${candidates[@]}"; do
        parent_dir="$(dirname "$settings_path")"
        # Only touch IDEs that are actually installed (their User/ dir exists).
        # We intentionally don't create the directory for an IDE the user
        # doesn't use.
        if [[ -d "$parent_dir" ]]; then
            any_found=true
            _apply_ide_terminal_font "$settings_path" "$font_value"
        fi
    done

    if ! $any_found; then
        info "No Cursor/VSCode install detected — skipping IDE terminal font setup."
    fi
}

deploy_ide_terminal_font

# --- Starship config ---
mkdir -p "$HOME/.config"
if [[ -f "$HOME/.config/starship.toml" ]]; then
    run_cmd cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
    warn "Backed up existing starship.toml"
fi
run_cmd cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml"
success "Starship config deployed"

# --- Shell-specific config ---
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    # Fish config
    FISH_CONFIG_DIR="$HOME/.config/fish"
    mkdir -p "$FISH_CONFIG_DIR"

    if [[ -f "$FISH_CONFIG_DIR/config.fish" ]]; then
        run_cmd cp "$FISH_CONFIG_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish.bak.$(date +%s)"
        warn "Backed up existing config.fish"
    fi

    # Deploy platform-appropriate fish config
    if [[ "$OS" == "macos" ]]; then
        run_cmd cp "$CONFIGS_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish"
    else
        # For Linux: use modified config without Homebrew paths
        run_cmd cp "$CONFIGS_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish"
        # Patch: replace Homebrew paths with Linux equivalents
        sed -i 's|/opt/homebrew/bin/starship|starship|g' "$FISH_CONFIG_DIR/config.fish"
        sed -i 's|fish_add_path /opt/homebrew/bin|# PATH: system paths are used on Linux|g' "$FISH_CONFIG_DIR/config.fish"
        # Fix pnpm path for Linux
        sed -i 's|\$HOME/Library/pnpm|\$HOME/.local/share/pnpm|g' "$FISH_CONFIG_DIR/config.fish"
    fi
    success "Fish config deployed"

    # Fish abbreviations (written to config.fish for Fish 3.x & 4.x compat)
    if ! grep -qF 'abbr -a ls' "$FISH_CONFIG_DIR/config.fish" 2>/dev/null; then
        info "Adding Fish abbreviations to config.fish..."
        cat >> "$FISH_CONFIG_DIR/config.fish" << 'ABBREOF'

# Abbreviations (compatible with Fish 3.x and 4.x)
if status is-interactive
    abbr -a ls "eza --icons --group-directories-first"
    abbr -a ll "eza -la --icons --group-directories-first"
    abbr -a lt "eza --tree --icons --level=2"
    abbr -a cat "bat"
    abbr -a find "fd"
    abbr -a grep "rg"
    abbr -a top "btop"
    abbr -a lg "lazygit"
    abbr -a cd "z"
end
ABBREOF
        success "Fish abbreviations added to config.fish"
    else
        success "Fish abbreviations already present"
    fi

    # Zoxide + fzf init for fish
    if ! grep -qF "zoxide" "$FISH_CONFIG_DIR/config.fish" 2>/dev/null; then
        info "Adding zoxide + fzf init to fish config..."
        cat >> "$FISH_CONFIG_DIR/config.fish" << 'FISHEOF'

# zoxide
zoxide init fish | source

# fzf
fzf --fish | source
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end
FISHEOF
        success "Zoxide + fzf init added"
    else
        success "Zoxide init already present"
    fi

    # Add ~/.local/bin to fish PATH on Linux
    if [[ "$OS" == "debian" || "$OS" == "wsl" ]]; then
        if ! grep -qF '.local/bin' "$FISH_CONFIG_DIR/config.fish" 2>/dev/null; then
            echo '' >> "$FISH_CONFIG_DIR/config.fish"
            echo '# Local bin (Linux)' >> "$FISH_CONFIG_DIR/config.fish"
            echo 'fish_add_path $HOME/.local/bin' >> "$FISH_CONFIG_DIR/config.fish"
        fi
    fi
else
    # Zsh config
    if [[ -f "$HOME/.zshrc" ]]; then
        run_cmd cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
        warn "Backed up existing .zshrc"
    fi

    if [[ "$OS" == "macos" ]]; then
        run_cmd cp "$CONFIGS_DIR/.zshrc" "$HOME/.zshrc"
    else
        # Deploy and patch for Linux
        run_cmd cp "$CONFIGS_DIR/.zshrc" "$HOME/.zshrc"

        # Patch Homebrew paths → Linux paths
        sed -i 's|export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:\$PATH"|# PATH — system paths on Linux\nexport PATH="$HOME/.local/bin:$PATH"|' "$HOME/.zshrc"

        # Patch zsh plugin source paths
        sed -i 's|/opt/homebrew/share/zsh-syntax-highlighting/|/usr/share/zsh-syntax-highlighting/|g' "$HOME/.zshrc"
        sed -i 's|/opt/homebrew/share/zsh-autosuggestions/|/usr/share/zsh-autosuggestions/|g' "$HOME/.zshrc"
        sed -i 's|/opt/homebrew/share/zsh-completions|/usr/share/zsh-completions|g' "$HOME/.zshrc"

        # Patch pnpm path for Linux
        sed -i 's|\$HOME/Library/pnpm|\$HOME/.local/share/pnpm|g' "$HOME/.zshrc"

        # Add fnm path for Linux (installed to ~/.local/share/fnm)
        if ! grep -qF '.local/share/fnm' "$HOME/.zshrc" 2>/dev/null; then
            sed -i '/# ─── fnm/i # fnm binary path (Linux)\nexport PATH="$HOME/.local/share/fnm:$PATH"\n' "$HOME/.zshrc"
        fi
    fi
    success "Zsh config deployed"
fi

# ═══════════════════════════════════════════════════════════════════════
# Optional macOS-only extensions (opt-in via --frontend / --ai / --accounts)
# ═══════════════════════════════════════════════════════════════════════

# Track manual follow-up notes that should be printed at the very end,
# so the user sees them after the "All done!" banner (not buried in logs).
POST_NOTES=()

# ─── Step 10: Frontend CLI (--frontend) ─────────────────────────────
if $INSTALL_FRONTEND && [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🌐 Step 10: Frontend CLI${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"

    # Global npm packages (pnpm / yarn) — requires Step 7 Node.
    if has_cmd npm; then
        # Re-load fnm env in case this shell didn't pick it up yet.
        has_cmd fnm && eval "$(fnm env --use-on-cd --shell bash)" 2>/dev/null || true

        for g in pnpm yarn; do
            if has_cmd "$g"; then
                success "$g already installed ($("$g" --version 2>/dev/null | head -1))"
            else
                info "Installing $g globally via npm..."
                run_cmd npm i -g "$g"
                success "$g installed"
            fi
        done
    else
        warn "npm not found — skipping pnpm / yarn. Re-run after Step 7 finished."
    fi

    # Bun — comes from the oven-sh/bun tap, NOT a vanilla `brew install bun`.
    # (Plain `brew install bun` fails with "No available formula with the name bun".)
    if has_cmd bun; then
        success "bun already installed ($(bun --version 2>/dev/null | head -1))"
    else
        info "Installing bun via oven-sh/bun tap..."
        run_cmd brew install oven-sh/bun/bun
        success "bun installed"
    fi

    # Formula installs: gh / mkcert / nss.
    # mkcert needs nss for Firefox's certificate store to trust the local CA.
    for pkg in gh mkcert nss; do
        if brew list "$pkg" >/dev/null 2>&1; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            run_cmd brew install "$pkg"
            success "$pkg installed"
        fi
    done
fi

# ─── Step 11: GUI Apps (--frontend) ─────────────────────────────────
if $INSTALL_FRONTEND && [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🖥  Step 11: GUI Apps${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"

    # Group A: always install on a clean machine. /Applications is empty by
    # default on a new Mac; if these are already present we just skip them.
    for cask in rectangle keka obsidian; do
        if brew list --cask "$cask" >/dev/null 2>&1; then
            success "$cask already installed (via brew)"
        else
            info "Installing $cask..."
            run_cmd brew install --cask "$cask"
            success "$cask installed"
        fi
    done

    # Group B: conditional install. These apps are often hand-dropped into
    # /Applications (from a direct DMG download). In that case `brew install
    # --cask` would refuse with "It seems there is already an App at ...",
    # and `--force` would overwrite the user's existing binary (losing any
    # signed-in state). So we detect and skip instead.
    # Format: "AppName:cask-name"
    for pair in "Google Chrome:google-chrome" "Cursor:cursor" "Visual Studio Code:visual-studio-code"; do
        app="${pair%%:*}"
        cask="${pair##*:}"
        if [[ -d "/Applications/$app.app" ]]; then
            warn "/Applications/$app.app already present — skipping cask '$cask'"
            warn "  (if you want brew to manage it, run: brew install --cask $cask --force)"
        elif brew list --cask "$cask" >/dev/null 2>&1; then
            success "$cask already installed (via brew)"
        else
            info "Installing $cask..."
            run_cmd brew install --cask "$cask"
            success "$cask installed"
        fi
    done

    # Arc: often blocked by Cloudflare (403) for mainland-China IPs because
    # brew fetches releases.arc.net directly. Try once, and if it fails give
    # the user a clear manual fallback instead of killing the whole script.
    # Note: Dia (Arc's successor) is Apple-Silicon-only, so it is NOT a valid
    # fallback for Intel Macs — do not auto-install it.
    if [[ -d "/Applications/Arc.app" ]]; then
        success "Arc already installed"
    elif brew list --cask arc >/dev/null 2>&1; then
        success "Arc already installed (via brew)"
    else
        info "Installing Arc (may be blocked by Cloudflare in some regions)..."
        if $DRY_RUN; then
            echo -e "${YELLOW}[DRY-RUN]${NC} brew install --cask arc"
        elif brew install --cask arc 2>&1 | tee /tmp/arc-install-$$.log; then
            success "Arc installed"
            rm -f /tmp/arc-install-$$.log
        else
            rm -f /tmp/arc-install-$$.log
            warn "Arc download failed (likely Cloudflare 403 on releases.arc.net)."
            warn "Manual download: https://arc.net/download (may need VPN/proxy)."
            warn "Dia is NOT a drop-in replacement — it only supports Apple Silicon."
            POST_NOTES+=("Arc install was blocked. Download manually from https://arc.net/download, or skip (Chrome covers you).")
        fi
    fi
fi

# ─── Step 12: AI Tools — OpenClaw (--ai) ────────────────────────────
if $INSTALL_AI && [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🤖 Step 12: AI Tools (OpenClaw)${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"

    OPENCLAW_DIR="$HOME/tools/open-claw"
    run_cmd mkdir -p "$HOME/tools"

    if [[ -d "$OPENCLAW_DIR/.git" ]]; then
        success "OpenClaw already cloned at $OPENCLAW_DIR"
        if ! $DRY_RUN; then
            (cd "$OPENCLAW_DIR" && git pull --ff-only 2>&1 | tail -3) || warn "git pull failed, continuing with existing tree"
        fi
    else
        info "Cloning OpenClaw to $OPENCLAW_DIR..."
        run_cmd git clone https://github.com/maoruiQa/open-claw-code.git "$OPENCLAW_DIR"
        success "OpenClaw cloned"
    fi

    if [[ -f "$OPENCLAW_DIR/package.json" ]] && has_cmd npm; then
        has_cmd fnm && eval "$(fnm env --use-on-cd --shell bash)" 2>/dev/null || true

        info "Running npm install in $OPENCLAW_DIR (this can take a few minutes)..."
        if ! $DRY_RUN; then
            if (cd "$OPENCLAW_DIR" && npm install); then
                success "OpenClaw dependencies installed"
                info "Running npm run build..."
                if (cd "$OPENCLAW_DIR" && npm run build); then
                    success "OpenClaw build succeeded"
                else
                    # Build issues are not fatal — the upstream's tsconfig emits into
                    # dist/src/, while package.json's "main" points at dist/index.js.
                    # Exit code is still 0 in our testing, so this is informational.
                    warn "OpenClaw build reported issues — check $OPENCLAW_DIR output when you use it."
                fi
            else
                warn "npm install failed inside $OPENCLAW_DIR — fix network/registry and retry."
            fi
        else
            echo -e "${YELLOW}[DRY-RUN]${NC} (cd $OPENCLAW_DIR && npm install && npm run build)"
        fi
    fi

    POST_NOTES+=("Cursor: sign in to sync settings/extensions (no CLI path for this).")
fi

# ─── Step 13: Accounts & System (--accounts) ────────────────────────
if $INSTALL_ACCOUNTS && [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🔐 Step 13: Accounts & System${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"

    # --- Git identity ---
    # Priority: --name / --email flags  >  $SETUP_GIT_NAME / $SETUP_GIT_EMAIL env
    #           >  interactive prompt (requires /dev/tty)
    # No personal defaults are baked in — this script is public, so we avoid
    # anchoring every fresh clone to whoever wrote it.
    GIT_NAME="${GIT_NAME:-${SETUP_GIT_NAME:-}}"
    GIT_EMAIL="${GIT_EMAIL:-${SETUP_GIT_EMAIL:-}}"

    if [[ -z "$GIT_NAME" ]]; then
        if [[ -r /dev/tty ]]; then
            printf "Git user.name: " > /dev/tty
            read -r GIT_NAME < /dev/tty
        fi
        if [[ -z "$GIT_NAME" ]]; then
            error "Git user.name is required. Pass --name \"Your Name\", export SETUP_GIT_NAME, or run in an interactive terminal."
        fi
    fi
    if [[ -z "$GIT_EMAIL" ]]; then
        if [[ -r /dev/tty ]]; then
            printf "Git user.email: " > /dev/tty
            read -r GIT_EMAIL < /dev/tty
        fi
        if [[ -z "$GIT_EMAIL" ]]; then
            error "Git user.email is required. Pass --email you@example.com, export SETUP_GIT_EMAIL, or run in an interactive terminal."
        fi
    fi

    run_cmd git config --global user.name "$GIT_NAME"
    run_cmd git config --global user.email "$GIT_EMAIL"
    run_cmd git config --global init.defaultBranch main
    run_cmd git config --global pull.rebase true
    success "Git identity set: $GIT_NAME <$GIT_EMAIL>"

    # --- SSH ed25519 key ---
    if [[ ! -d "$HOME/.ssh" ]]; then
        run_cmd mkdir -p "$HOME/.ssh"
        run_cmd chmod 700 "$HOME/.ssh"
    fi

    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        success "$HOME/.ssh/id_ed25519 already exists (skipped ssh-keygen)"
    else
        info "Generating ed25519 SSH key at $HOME/.ssh/id_ed25519 (no passphrase)..."
        if $DRY_RUN; then
            echo -e "${YELLOW}[DRY-RUN]${NC} ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f $HOME/.ssh/id_ed25519 -N \"\""
        else
            ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N "" < /dev/null > /dev/null
            chmod 600 "$HOME/.ssh/id_ed25519"
            chmod 644 "$HOME/.ssh/id_ed25519.pub"
            success "SSH key generated"
        fi
    fi

    # --- ~/.ssh/config with keychain-aware GitHub block ---
    if [[ -f "$HOME/.ssh/config" ]] && grep -qE '^\s*Host\s+github\.com' "$HOME/.ssh/config" 2>/dev/null; then
        success "$HOME/.ssh/config already contains a github.com block"
    else
        info "Writing $HOME/.ssh/config (github.com + UseKeychain yes)..."
        if $DRY_RUN; then
            echo -e "${YELLOW}[DRY-RUN]${NC} (write ~/.ssh/config with Host github.com block)"
        else
            # Append rather than overwrite, so we don't stomp on existing hosts.
            cat >> "$HOME/.ssh/config" <<'SSHCFG'

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
SSHCFG
            chmod 600 "$HOME/.ssh/config"
            success "$HOME/.ssh/config updated"
        fi
    fi

    # --- ssh-agent + keychain ---
    if ! $DRY_RUN; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1 || true
        # --apple-use-keychain persists the passphrase in macOS Keychain so the
        # key is auto-loaded on future logins. Empty passphrase still works.
        ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null \
            || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null \
            || warn "ssh-add failed (non-fatal)"
    fi

    # --- Public key: copy to clipboard + print ---
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        pbcopy < "$HOME/.ssh/id_ed25519.pub" 2>/dev/null \
            && success "Public key copied to clipboard (paste it into GitHub if needed)"
        info "Public key:"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi

    # --- npm registry (China-friendly mirror) ---
    if has_cmd npm; then
        run_cmd npm config set registry https://registry.npmmirror.com
        success "npm registry → https://registry.npmmirror.com"
    fi

    # --- macOS Finder / NSGlobalDomain defaults ---
    info "Applying macOS defaults (Finder shows hidden files, extensions, path bar, status bar)..."
    run_cmd defaults write com.apple.finder AppleShowAllFiles -bool YES
    run_cmd defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    run_cmd defaults write com.apple.finder ShowPathbar -bool true
    run_cmd defaults write com.apple.finder ShowStatusBar -bool true
    if ! $DRY_RUN; then
        killall Finder 2>/dev/null || true
    fi
    success "macOS Finder preferences applied"

    # --- Cursor agent-done notification hook ---
    # Fires a native macOS notification whenever the Cursor agent finishes a
    # task (Cursor "stop" event), so you don't miss it when the window is in
    # the background. Safe to skip if ~/.cursor/hooks.json already exists —
    # we don't want to clobber the user's other hooks.
    CURSOR_HOOKS_DIR="$HOME/.cursor/hooks"
    CURSOR_HOOKS_JSON="$HOME/.cursor/hooks.json"

    if [[ -f "$CURSOR_HOOKS_JSON" ]]; then
        warn "$CURSOR_HOOKS_JSON already exists — leaving it alone."
        warn "  If you want the agent-done notification, add this entry to the 'stop' array:"
        warn '    { "command": "./hooks/notify-agent-done.sh", "timeout": 5 }'
    elif $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} (write $CURSOR_HOOKS_JSON and $CURSOR_HOOKS_DIR/notify-agent-done.sh)"
    else
        mkdir -p "$CURSOR_HOOKS_DIR"

        cat > "$CURSOR_HOOKS_JSON" <<'CURSORHOOKSJSON'
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "./hooks/notify-agent-done.sh",
        "timeout": 5
      }
    ]
  }
}
CURSORHOOKSJSON

        cat > "$CURSOR_HOOKS_DIR/notify-agent-done.sh" <<'NOTIFYAGENTDONE'
#!/bin/bash
set -u

# Cursor passes hook event data on stdin. We do not need to parse it for a
# simple "agent finished" notification, but reading it avoids a broken pipe
# in callers.
input="$(cat || true)"

title="Cursor"
message="Agent 任务已完成"

if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
fi

echo '{}'
exit 0
NOTIFYAGENTDONE

        chmod +x "$CURSOR_HOOKS_DIR/notify-agent-done.sh"
        success "Cursor agent-done notification hook installed"
    fi

    POST_NOTES+=("Run 'gh auth login' in Ghostty to upload the SSH public key to GitHub (needs a real TTY + browser).")
    POST_NOTES+=("Verify SSH: ssh -T git@github.com  (should greet you as '$GIT_NAME').")
    POST_NOTES+=("Cursor agent-done hook takes effect after the next Cursor restart — on first trigger macOS will ask for Notification permission, click 'Allow'.")
fi

# ─── Git config for delta ────────────────────────────────────────────
if has_cmd delta || $DRY_RUN; then
    info "Configuring git-delta as git pager..."
    run_cmd git config --global core.pager delta
    run_cmd git config --global interactive.diffFilter "delta --color-only"
    run_cmd git config --global delta.navigate true
    run_cmd git config --global delta.dark true
    run_cmd git config --global delta.line-numbers true
    run_cmd git config --global delta.side-by-side true
    run_cmd git config --global merge.conflictstyle diff3
    run_cmd git config --global diff.colorMoved default
    success "git-delta configured"
fi

# ─── Done! ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
if $DRY_RUN; then
    echo -e "${YELLOW}${BOLD}  ⚠  DRY-RUN complete — no changes were made${NC}"
else
    echo -e "${GREEN}${BOLD}  ✅ All done!${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Platform:${NC} $OS"
echo -e ""
echo -e "  ${BOLD}Your terminal stack:${NC}"
case "$OS" in
    macos)
        echo -e "    👻 Ghostty              — terminal emulator"
        ;;
    debian)
        echo -e "    👻 Ghostty              — terminal (install separately on Linux)"
        ;;
    wsl)
        echo -e "    💻 Windows Terminal      — recommended for WSL"
        ;;
esac
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    echo -e "    🐟 Fish                 — shell"
else
    echo -e "    🐚 Zsh                  — shell (POSIX-compatible)"
    echo -e "    ✨ zsh-autosuggestions   — fish-like suggestions"
    echo -e "    🎨 zsh-syntax-highlight — fish-like highlighting"
fi
echo -e "    🚀 Starship             — prompt (Catppuccin Mocha)"
echo -e "    🔤 MesloLGS NF          — nerd font"
echo -e "    🟢 fnm                  — Node version manager (fast!)"
echo -e "    📦 bat eza fd rg        — modern coreutils"
echo -e "    📊 btop                 — system monitor"
echo -e "    🔀 lazygit + delta      — git tools"
echo -e "    📁 zoxide               — smart cd"
echo -e "    🔍 fzf                  — fuzzy finder"
if has_cmd zellij; then
    echo -e "    🪟 zellij               — terminal multiplexer"
fi
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "    1. Restart your terminal (or open ${BOLD}Ghostty${NC})"
echo -e "    2. Node is ready: ${BOLD}node --version${NC}"
echo -e "    3. Pin a project: ${BOLD}echo 22 > .node-version${NC} (fnm auto-switches)"
echo -e "    4. Try: ${BOLD}Ctrl+R${NC} (fzf history) / ${BOLD}Ctrl+T${NC} (fzf files)"
echo ""

# Surface any manual follow-ups collected during the optional steps.
# These need real TTY / browser / user decision and can't be automated here.
if (( ${#POST_NOTES[@]} > 0 )); then
    echo -e "  ${YELLOW}${BOLD}Manual follow-ups:${NC}"
    i=1
    for note in "${POST_NOTES[@]}"; do
        echo -e "    ${i}. ${note}"
        i=$((i + 1))
    done
    echo ""
fi
