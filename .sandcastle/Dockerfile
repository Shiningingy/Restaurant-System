FROM node:22-bookworm

# ---------------------------------------------------------------------------
# ONE IMAGE, THE WHOLE CI GATE. Sandcastle runs the agent INSIDE this container,
# so the image must be able to run every check .github/workflows/ci.yml runs,
# or the agent can write code and never verify it:
#
#   dart format --set-exit-if-changed packages apps
#   flutter analyze packages apps
#   dart test            (packages/domain)
#   flutter test         (apps/merchant, apps/customer)
#   deno test supabase/tests   (not in CI yet, but it is the only guard on the
#                               TS/Dart money-math mirror; see amount_test.ts)
#
# The scaffold `sandcastle init` wrote shipped git + gh + the Claude CLI and no
# Flutter and no Deno. This file adds both.
#
# SLOWEST AND MOST STABLE FIRST, so the usual rebuild is seconds: apt, then the
# Flutter SDK clone (~1 GB, pinned), then Deno, then the Claude CLI. Nothing from
# the repo is COPYed in -- the build context is empty by design, see
# Dockerfile.dockerignore beside this file (the working tree is ~9 GB with
# build/ and release/).
# ---------------------------------------------------------------------------

# System deps. git/curl/jq: the scaffold's. unzip/xz-utils/zip/libglu1-mesa: what
# flutter.dev lists for Linux. clang/cmake/ninja/pkg-config: the merchant app
# builds SQLite (sqlite3mc, root pubspec.yaml `hooks:`) from C source through a
# native build hook, which `flutter test` also runs; gcc is in the base image
# but the Flutter toolchain prefers clang.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl jq ca-certificates \
      unzip xz-utils zip libglu1-mesa \
      clang cmake ninja-build pkg-config \
  && rm -rf /var/lib/apt/lists/*

# GitHub CLI. The agent uses it to read and comment on its issue (Issues RW +
# Metadata R token, nothing more -- it cannot push or open a PR; the host does).
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# Build-args for UID/GID alignment: `sandcastle docker build-image` defaults
# these to the host user's UID/GID so image-built files and bind-mounted files
# share an owner. On Windows process.getuid is undefined, so sandcastle falls
# back to 1000 and these defaults are what its preflight compares against.
ARG AGENT_UID=1000
ARG AGENT_GID=1000

# Rename the base image's "node" user to "agent" and align UID/GID.
RUN groupmod -o -g $AGENT_GID node && usermod -o -u $AGENT_UID -g $AGENT_GID -d /home/agent -m -l agent node
USER ${AGENT_UID}:${AGENT_GID}
WORKDIR /home/agent

# Flutter, PINNED to the same version as CI (.github/workflows/ci.yml) and the
# dev machine. `dart format` output differs between versions, and CI fails on
# format, so a container on a different Flutter would produce commits CI rejects.
# Bump here and in ci.yml together, as one deliberate PR.
#
# As the agent user: the SDK writes its cache under its own tree, and a
# root-owned SDK would make every `flutter` call fail on ownership checks.
ARG FLUTTER_VERSION=3.44.2
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /home/agent/flutter
ENV PATH="/home/agent/flutter/bin:/home/agent/.pub-cache/bin:$PATH"
# `flutter --version` downloads the Dart SDK; `precache --linux` fetches the
# host-platform engine, which is what `flutter test` runs on. Done at build time
# so a run does not spend its idle window downloading toolchains.
RUN flutter config --no-analytics --no-cli-animations \
  && flutter --version \
  && flutter precache --linux --no-android --no-ios --no-web --no-windows --no-macos --no-fuchsia

# Deno, for `deno test supabase/tests` and `deno check` on the edge functions.
# Pinned to the version on the dev machine (2026-10-21).
ARG DENO_VERSION=v2.9.6
RUN curl -fsSL https://deno.land/install.sh | sh -s ${DENO_VERSION}
ENV DENO_INSTALL="/home/agent/.deno"
ENV PATH="/home/agent/.deno/bin:$PATH"

# Claude Code CLI, as the agent user: the installer writes to $HOME/.local/bin.
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/agent/.local/bin:$PATH"

# Pre-create the Claude projects dir, owned by the agent. Measured on the maple
# project (2026-10-17): if a run mounts anything under ~/.claude/projects, the
# Docker daemon creates the missing parents as ROOT, and the agent can then not
# create its own session directory, so the session capture at the end of the
# run fails. This run mounts nothing there today; the line costs nothing and
# keeps the option open.
RUN mkdir -p /home/agent/.claude/projects

# MAKE THE TOOLCHAINS SURVIVE ANY SHELL. Measured 2026-10-21 on the first smoke
# test of this image: under `bash -lc`, flutter, dart and deno were all
# "command not found" while gh and claude worked. Debian's /etc/profile
# OVERWRITES PATH for a login shell, so every ENV PATH line above is lost there,
# and the Claude CLI only survived because the skeleton ~/.profile re-adds
# ~/.local/bin. The maple image hit the same wall with a Python venv. A symlink
# in /usr/local/bin needs no PATH at all: `flutter`, `dart` and `deno` resolve
# their real location through the link, so this holds under `bash -c`,
# `bash -lc`, `sh -c` and `env -i`. Root is needed to write there; the targets
# stay agent-owned.
USER root
RUN ln -s /home/agent/flutter/bin/flutter /usr/local/bin/flutter \
  && ln -s /home/agent/flutter/bin/dart /usr/local/bin/dart \
  && ln -s /home/agent/.deno/bin/deno /usr/local/bin/deno
USER ${AGENT_UID}:${AGENT_GID}

# In worktree sandbox mode, Sandcastle bind-mounts the git worktree at
# /home/agent/workspace and overrides the working directory to it at start.
ENTRYPOINT ["sleep", "infinity"]
