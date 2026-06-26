# node-dawn

Dawn WebGPU binding build for nodejs.

This repo is a build only work, no npm package yet, just get artifact from action. If you need a npm package, take a look at [node-webgpu](https://github.com/dawn-gpu/node-webgpu).

The usage and build steps are almost same as node-webgpu, but there is some difference:
- no npm package yet, just download binary from action artifacts.
- cmake only building
- only build for win32-x64, win32-arm64, linux-x64, linux-arm64, osx-arm64.
- enable `DAWN_USE_BUILT_DXC` for windows build. In some case FXC will fail.
- only `D3D12`, `Vulkan`, `Metal`

If need a custom build, just fork and update `CMakePresets.json` for yourself.
