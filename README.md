**University of Pennsylvania, CIS 5650: GPU Programming and Architecture,
Project 1 - Flocking**

- Kexuan Zhang
- Personal laptop: CachyOS Linux, Intel Core i9-13900H, 32 GB RAM, NVIDIA GeForce RTX 4060 Laptop GPU (8 GB).
- CUDA 13.4, xmake, VS Code with clangd and Nsight. Windows has not been tested.

I am a University of Leeds PhD student, following CIS 5650 independently to learn CUDA/GPGPU. I am not a Penn student. This repository is for personal study; no blog, LinkedIn, or other social media write-up is planned.

## Environment

Build from the repository root:

```sh
xmake f -m debug -y
xmake
xmake run cis5650_boids
```

The root `xmake.lua` includes `src/xmake.lua`. CUDA paths and architecture are detected automatically. The run target handles XWayland, NVIDIA rendering, and the working directory for shaders.

Open `CIS5650.code-workspace` in VS Code. See [Linux Setup](LINUX_SETUP.md) for completion, debugging, and Nsight profiling commands.

## Progress

- [x] Linux xmake build and CUDA/OpenGL starter verified.
- [x] clangd completion and CUDA device debugging verified.
- [x] Nsight Systems and Compute captures verified.
- [ ] Naive Boids simulation.
- [ ] Scattered uniform grid.
- [ ] Coherent uniform grid.
- [ ] Screenshots and performance analysis.

## Results

TODO: Add simulation screenshots, animations, and performance analysis after implementing the exercises.

See [project instructions](INSTRUCTION.md) and the [upstream project](https://github.com/CIS5650-Fall-2026/Project1-CUDA-Flocking).
