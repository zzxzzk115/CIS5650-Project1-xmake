# Linux CUDA Setup

Use xmake, VS Code, clangd, and NVIDIA Nsight. Visual Studio is not required on Linux. For native Windows builds and CUDA debugging, see [Windows Setup](WINDOWS_SETUP.md).

## Build and run

Install CUDA Toolkit, a working NVIDIA driver, GCC, xmake, CMake, and OpenGL/X11 development libraries. Keep `cuda-gdb` on `PATH`.

Xmake installs the repository's GLM 0.9.6.3 headers from `external/include/glm` as a local header-only package. It downloads and builds static GLFW 3.4 (X11) and GLEW 2.2.0, with system-package fallback disabled for all three dependencies. New packages are installed under `build/.packages/`; matching packages already in xmake's cache may be reused. The first configuration needs network access. System GLM, GLFW, and GLEW development packages are not required. OpenGL and X11 remain platform dependencies. The `.lib` files in `external/lib` are Windows binaries and are not used on Linux.

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

For a custom toolkit, use `xmake f --cuda=/path/to/cuda`. The default `--cuda_arch=native` queries `nvidia-smi` for each local GPU architecture, falling back to Xmake's native CUDA probe if the query is unavailable. To build without GPU access, set an architecture such as `--cuda_arch=sm_89`; use `--cuda_arch=native` to restore automatic detection. CUDA 13's `include/cccl` directory is added automatically when present.

## VS Code workspace

```sh
code CIS5650-Project1.code-workspace
```

Install the recommended Nsight, clangd, C/C++, and xmake extensions. Shared settings also support opening the repository directly with `code .`.

Better Todo Tree is recommended for TODO navigation. Disable or uninstall the original Todo Tree before using the fork; existing `todo-tree.*` settings can be imported. Keep personal colors and any local ripgrep override in `CIS5650-Project1.local.code-workspace`, which is ignored by Git. Start from the shared workspace file when setting up another machine.

Source comments retain exercise IDs and instructions: `[ ] TODO-2.3` is pending and `[x] TODO-1.2` is completed. Change only the checkbox when finishing or reopening a task. `LOOK` comments appear as blue information markers. The shared settings group entries by tag with counts, and completed entries remain clickable for review. Split comments covering multiple exercises when their completion states differ. Tree rows show exercise IDs and descriptions consistently; icons and groups show the status or information tag. Full markers remain in the source.

clangd reads the root `compile_commands.json`, updated by xmake after builds. xmake generates `.clangd` with the detected CUDA path and architecture, selecting `.clangd.nowin.in` on Linux hosts and `.clangd.win.in` on Windows hosts. Both generated files are ignored by Git; edit the platform templates for shared options. Automatic header insertion is disabled by `--header-insertion=never` in the shared VS Code arguments so CUDA completions do not insert Clang internal headers.

The xmake extension's separate compilation database generation and C/C++ IntelliSense are disabled. Compilation uses nvcc and GCC; clangd provides completion and navigation.

The starter's two VBO kernel launches use standard `<<<...>>>` delimiters for clangd compatibility.

## CUDA debugging

1. Set a breakpoint in `kernGenerateRandomPosArray` in `src/kernel.cu`.
2. Select **CUDA: boids (xmake debug)** in Run and Debug.
3. Focus the source editor and press **F5** to build and stop at `main`; continue to reach the GPU breakpoint.
4. Inspect CUDA threads, blocks, and warps. Add `blockIdx.x`, `threadIdx.x`, and `index` to Watch after stepping past the index assignment.
5. Press **Shift+F5** to stop.

**Ctrl+Shift+B** builds Debug. `scripts/cuda-gdb` handles the Linux rendering environment for debugging. If another extension captures **F5**, use the start button in Run and Debug; disable **C/C++ Compile Run** for this workspace if installed.

The CUDA launch configuration loads `scripts/glm_printers.py` so GLM vectors appear automatically in Variables > Local as `(x, y, z)` values. This avoids an Nsight expansion error for the bundled GLM's anonymous unions; adding Watch expressions is not required. Stop inside the function after initialization and select its CUDA stack frame to see its local variables.

GLM buffer pointers such as `pos` and `vel` automatically preview up to four elements, bounded by their matching `N` argument. Other GLM pointers preview only the first element because a pointer does not encode an array length. Null pointers display `nullptr`. Indexed expressions such as `pos[i]` use the same vector formatting. To inspect a longer buffer, use GDB's array expression `*pos@N` (or a smaller valid count) in Watch; the resulting array expands into formatted elements. Native arrays retain GDB's indexed expansion. Pointer previews appear inline because the current Nsight adapter does not expand dynamic pretty-printer children reliably.

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
