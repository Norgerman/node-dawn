# Linux build environment pinned to Ubuntu 22.04 (glibc 2.35 / libstdc++ 12).
# Building inside this image keeps artifacts running on Ubuntu 22.04 even
# though the GitHub runner itself has moved to a newer Ubuntu release.
#
# Versions are build args and can be overridden from outside:
#   docker build \
#     --build-arg CMAKE_VERSION=4.4.2 \
#     --build-arg GO_VERSION=1.26.5 \
#     -t dawn-build:22.04 -f build-linux.Dockerfile .

FROM ubuntu:22.04

ARG TARGETARCH
ARG CMAKE_VERSION=4.4.2
ARG GO_VERSION=1.26.5

ENV DEBIAN_FRONTEND=noninteractive

# Build prerequisites plus the same X11/Wayland/Vulkan dev packages the old
# runner setup installed. g++-12 matches the newest GCC on the ubuntu-22.04
# runner image, so clang-21 sees the same libstdc++-12 headers and the artifact
# keeps the same GLIBCXX_3.4.30 ceiling.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl g++-12 git gnupg lsb-release \
        ninja-build pkg-config python3 python-is-python3 unzip wget xz-utils \
        libxkbcommon-dev libwayland-dev wayland-protocols libxrandr-dev \
        libxinerama-dev libxcursor-dev mesa-common-dev libx11-xcb-dev \
        mesa-vulkan-drivers libvulkan1 \
    && rm -rf /var/lib/apt/lists/*

# clang-21 from the official apt.llvm.org script, same as the previous setup.
RUN wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 21 \
    && rm llvm.sh \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-21 20 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-21 20 \
    && update-alternatives --set c++ /usr/bin/clang++-21 \
    && update-alternatives --set cc /usr/bin/clang-21

# CMake from the official Kitware release binaries.
# Docker's TARGETARCH is amd64/arm64; Kitware's assets use x86_64/aarch64.
RUN case "${TARGETARCH}" in \
        amd64) cmake_arch=x86_64 ;; \
        arm64) cmake_arch=aarch64 ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${cmake_arch}.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local

# Go toolchain, kept in sync with actions/setup-go in the workflow.
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local
ENV PATH="/usr/local/go/bin:${PATH}"
