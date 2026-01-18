FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install base packages
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    wget \
    stow \
    tmux \
    fzf \
    ripgrep \
    fd-find \
    bat \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install eza
RUN wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
    && apt-get update \
    && apt-get install -y eza \
    && rm -rf /var/lib/apt/lists/*

# Install zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install Neovim 0.11+ (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        NVIM_ARCH="linux-x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        NVIM_ARCH="linux-arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -LO "https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-${NVIM_ARCH}.tar.gz" && \
    tar -xzf "nvim-${NVIM_ARCH}.tar.gz" -C /opt/ && \
    ln -s "/opt/nvim-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim && \
    rm "nvim-${NVIM_ARCH}.tar.gz"

# Create symlink for bat (called batcat on Ubuntu)
RUN ln -s /usr/bin/batcat /usr/local/bin/bat

# Create test user
RUN useradd -m -s /bin/zsh testuser
USER testuser
WORKDIR /home/testuser

# Copy dotfiles
COPY --chown=testuser:testuser . /home/testuser/.dotfiles/

# Run stow (excluding test directory)
WORKDIR /home/testuser/.dotfiles
RUN stow . --target=/home/testuser --ignore=test --ignore=docs --ignore=install.sh --ignore=README.md --ignore=LICENSE

# Install tmux plugin manager
RUN git clone https://github.com/tmux-plugins/tpm /home/testuser/.tmux/plugins/tpm

WORKDIR /home/testuser

# Default command runs tests
CMD ["/home/testuser/.dotfiles/test/test.sh"]
