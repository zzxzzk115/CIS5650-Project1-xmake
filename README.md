**University of Pennsylvania, CIS 5650: GPU Programming and Architecture,
Project 1 - Flocking**

- Kexuan Zhang
- Personal laptop: CachyOS Linux, Intel Core i9-13900H, 32 GB RAM, NVIDIA GeForce RTX 4060 Laptop GPU (8 GB), CUDA 13.4.
- Lab PC: Windows, Intel Core i7-14700, 32 GB RAM, NVIDIA GeForce RTX 4080 SUPER (16 GB), CUDA 13.3, NVIDIA driver 617.42.
- Development tools: xmake, VS Code with clangd and NVIDIA Nsight.

I am a University of Leeds PhD student, following CIS 5650 independently to learn CUDA/GPGPU. I am not a Penn student. This repository is for personal study; no blog, LinkedIn, or other social media write-up is planned.

## Environment

Build from the repository root:

```sh
xmake f -m debug -y
xmake
xmake run cis5650_boids
```

The root `xmake.lua` includes `external/xmake.lua` and `src/xmake.lua`. Both platforms use the repository's GLM 0.9.6.3 through a local xmake package. Linux uses pinned GLFW 3.4 and GLEW 2.2.0 packages built by xmake; Windows uses the bundled x64 GLEW/GLFW libraries. System-package fallback is disabled for GLM and the Linux GLFW/GLEW packages. CUDA paths and architecture are detected automatically. The run target sets the working directory for shaders and selects XWayland and NVIDIA rendering on Linux.

Open `CIS5650-Project1.code-workspace` in VS Code. See [Linux Setup](LINUX_SETUP.md) or [Windows Setup](WINDOWS_SETUP.md) for the platform's build, editor, debugging, and profiling instructions. Native Windows CUDA debugging uses Nsight Visual Studio Edition; the committed VS Code `cuda-gdb` launch configuration is for Linux.

## Progress

- [x] Linux xmake build and CUDA/OpenGL starter verified.
- [x] Windows xmake Debug/Release builds and CUDA/OpenGL starter verified.
- [x] clangd completion and CUDA device debugging verified.
- [x] Nsight Systems and Compute captures verified.
- [x] Naive Boids simulation.
- [x] Scattered uniform grid.
- [x] Coherent uniform grid.
- [ ] Screenshots and performance analysis.

## Results

TODO: Add simulation screenshots, animations, and performance analysis after implementing the exercises.

See [project instructions](INSTRUCTION.md) and the [upstream project](https://github.com/CIS5650-Fall-2026/Project1-CUDA-Flocking).
