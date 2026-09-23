FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Minimal bootstrap only — everything else is installed by scripts/install.sh itself,
# so this image exercises the REAL installer rather than a hand-maintained copy of it.
RUN apt-get update && apt-get install -y \
    sudo \
    ca-certificates \
    curl \
    git \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Test user with passwordless sudo (install.sh needs sudo for apt/NodeSource)
RUN useradd -m -s /bin/zsh testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser
USER testuser
WORKDIR /home/testuser

# Bring in the dotfiles and run the actual installer non-interactively.
# --ci skips the optional/interactive steps (Claude/workmux/GitHub/chsh); everything
# else — apt packages, node/bun, nvim, stow, plugin sync — runs exactly as on a real box.
COPY --chown=testuser:testuser . /home/testuser/.dotfiles/
WORKDIR /home/testuser/.dotfiles
RUN ./scripts/install.sh --local --ci

WORKDIR /home/testuser

# Default command runs the assertion suite against the installed environment
CMD ["/home/testuser/.dotfiles/test/test.sh"]
