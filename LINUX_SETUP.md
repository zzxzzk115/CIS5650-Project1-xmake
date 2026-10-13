# Linux CUDA Setup

Use xmake, VS Code, clangd, and NVIDIA Nsight. Visual Studio is not required on Linux. For native Windows builds and CUDA debugging, see [Windows Setup](WINDOWS_SETUP.md).

## Build and run

Install CUDA Toolkit, a working NVIDIA driver, GCC, xmake, GLFW, GLEW, GLM, and OpenGL development libraries. Keep `cuda-gdb` on `PATH`.

From the repository root:

```sh
xmake f -m debug -y
xmake
xmake run cis5650_boids
```

Press Esc to close the window. The starter prints the provided Thrust sorting example and displays stationary particles until the simulation TODOs are implemented. Drag with the left mouse button to orbit; drag vertically with the right button to zoom.

`src/xmake.lua` defines the target. The run hook selects XWayland and NVIDIA rendering on Linux. Its working directory is the repository root so `shaders/` is found without copying assets.

For performance measurements:

```sh
xmake f -m release -y
xmake
```

Binaries are in `build/{debug,release}/`. Debug includes CUDA device symbols; Release includes line information without device debug instrumentation.

For a custom toolkit, use `xmake f --cuda=/path/to/cuda`. To build without GPU access, set an architecture such as `--cuda_arch=sm_89`. CUDA 13's `include/cccl` directory is added automatically when present.

## VS Code workspace

```sh
code CIS5650-Project1.code-workspace
```

Install the recommended Nsight, clangd, C/C++, and xmake extensions. Shared settings also support opening the repository directly with `code .`.

Keep personal colors and Todo Tree's local ripgrep path in `CIS5650-Project1.local.code-workspace`, which is ignored by Git. Start from the shared workspace file when setting up another machine.

clangd reads the root `compile_commands.json`, updated by xmake after builds. xmake generates `.clangd` from `.clangd.in` with the detected CUDA path and architecture. Both generated files are ignored by Git. Automatic header insertion is disabled in the project config so CUDA completions do not insert Clang internal headers.

The xmake extension's separate compilation database generation and C/C++ IntelliSense are disabled. Compilation uses nvcc and GCC; clangd provides completion and navigation.

The starter's two VBO kernel launches use standard `<<<...>>>` delimiters for clangd compatibility.

## CUDA debugging

1. Set a breakpoint in `kernGenerateRandomPosArray` in `src/kernel.cu`.
2. Select **CUDA: boids (xmake debug)** in Run and Debug.
3. Focus the source editor and press **F5** to build and stop at `main`; continue to reach the GPU breakpoint.
4. Inspect CUDA threads, blocks, and warps. Add `blockIdx.x`, `threadIdx.x`, and `index` to Watch after stepping past the index assignment.
5. Press **Shift+F5** to stop.

**Ctrl+Shift+B** builds Debug. `scripts/cuda-gdb` handles the Linux rendering environment for debugging. If another extension captures **F5**, use the start button in Run and Debug; disable **C/C++ Compile Run** for this workspace if installed.

## Nsight Systems

Install `nsys` and `nsys-ui`. With a Release build, collect three seconds:

```sh
mkdir -p build/profiles
nsys profile --duration=3 --kill=sigterm --trace=cuda,nvtx,opengl \
  --sample=none --cpuctxsw=none --force-overwrite=true \
  --output=build/profiles/boids-systems xmake run cis5650_boids
nsys-ui build/profiles/boids-systems.nsys-rep
```

The application closes after collection. Exit code 143 is expected with SIGTERM; check that the report was generated.

1. Open **Analysis Summary** to check the GPU and collected events.
2. Switch to **Timeline View** and expand CUDA hardware, CUDA API, and OpenGL rows. Select a kernel interval to inspect its duration.
3. Open **Stats System View > CUDA GPU Kernel Summary** for launch counts and average duration.

## Nsight Compute

Install `ncu` and `ncu-ui`. With the same Release build, capture one kernel launch:

```sh
mkdir -p build/profiles
ncu --target-processes all --set=basic --launch-count=1 --kill=yes \
  --force-overwrite --export=build/profiles/boids-compute \
  xmake run cis5650_boids
ncu-ui build/profiles/boids-compute.ncu-repz
```

`--target-processes all` includes the child application launched by xmake. Compute replays the selected launch for its counters, then closes the application. To select a simulation kernel after implementing it, add `--kernel-name=regex:YOUR_KERNEL_NAME`.

1. Select a kernel in **Summary** for duration, SM throughput, and memory throughput.
2. Open **Details > Launch Statistics** and **Occupancy** for launch dimensions and active warps.
3. Replace `--set=basic` with `--set=full` for more metrics; collection takes longer.

Run `nsys-ui` or `ncu-ui` without arguments to open the GUI, then use **File > Open** for saved reports. Reports stay in the ignored `build/profiles/` directory; the commands above overwrite reports with the same names.

See the [Systems guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html) and [Compute guide](https://docs.nvidia.com/nsight-compute/NsightCompute/index.html) for additional profiling options.
