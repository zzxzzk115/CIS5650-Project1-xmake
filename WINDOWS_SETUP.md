# Windows CUDA Setup

Build from the repository root with xmake. Windows uses the bundled x64 MSVC
GLEW/GLFW libraries and GLM headers in `external/`. Thrust and the other CCCL
headers come from the installed CUDA Toolkit.

## Requirements

- Windows 11 and an NVIDIA GPU.
- Visual Studio 2022 or its Build Tools, with **Desktop development with C++**.
- CUDA Toolkit 13 or newer and a compatible NVIDIA driver.
- xmake 3.0.0 or newer.

The validation machine uses an RTX 4080 SUPER (`sm_89`), NVIDIA driver 617.42,
CUDA Toolkit 13.3, MSVC 14.42.34433, and xmake 3.0.9. See the
[course Windows setup guide](https://cis5650-fall-2026.github.io/setup-windows/)
for the course environment.

## Build and run

In PowerShell, from the repository root:

```powershell
xmake f -m debug -y
xmake
xmake run cis5650_boids
```

The starter loads three shaders, prints the provided Thrust sorting example,
and displays stationary particles until the simulation TODOs are implemented.
Press Esc to close the window. Drag with the left mouse button to orbit; drag
vertically with the right button to zoom.

`xmake run` sets the working directory to the repository root so the shaders
can be found. If launching the executable directly, keep the same working
directory. The Debug executable is `build/debug/cis5650_boids.exe`.

For performance measurements:

```powershell
xmake f -m release -y
xmake
xmake run cis5650_boids
```

The Release executable is `build/release/cis5650_boids.exe`. Debug includes CUDA
device symbols (`-G`); Release includes CUDA line information (`-lineinfo`).

Xmake detects the Toolkit and GPU architecture. If the native GPU probe cannot
run, select your GPU architecture explicitly, for example:

```powershell
xmake f -m debug --cuda_arch=sm_89 -y
```

For a custom Toolkit location, add
`--cuda="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.3"` to the
configure command. The driver must support the selected Toolkit.

The Windows target uses the DLL CRT (`MD`) to match the bundled libraries and
passes `/Zc:preprocessor` to MSVC, including through nvcc, as required by CUDA
13's CCCL headers. Keep these settings in `src/xmake.lua`.

## VS Code workspace

```powershell
code CIS5650-Project1.code-workspace
```

The shared workspace uses relative paths. Install clangd and the xmake extension
from the recommended extensions. **Ctrl+Shift+B** builds Debug; **Tasks: Run
Task > xmake: run boids** builds and runs the starter. Release has its own build
task. Build diagnostics include MSVC and CUDA messages.

Xmake generates `.clangd` and `compile_commands.json` with the local Windows
Toolkit path and GPU architecture. Both files are ignored by Git. Personal
workspace settings belong in the ignored `CIS5650-Project1.local.code-workspace`.

### clangd configuration

Use clangd 23.1.0 or newer for the CUDA 13 environment; 23.1.0 is verified here.
Set `clangd.path` in local VS Code user settings if the extension still uses an
older executable. After changing it, run **clangd: Restart language server**.

Xmake selects `.clangd.win.in` on Windows hosts and `.clangd.nowin.in` on Linux
hosts, then writes a local `.clangd` with the detected Toolkit and architecture.
Windows uses the clang-cl driver and forwards C++17/CUDA flags through `/clang:`.
NVCC arguments are filtered for both CUDA sources and `kernel.h`, including
`-Xcompiler=...`; CUDA and CCCL include paths are generated without embedded
shell quotes. Header insertion is controlled by the shared VS Code arguments.

Keep the templates in Git. `.clangd`, `compile_commands.json`, and files under
`build/clangd/` are generated for the local machine and ignored by Git. Check
global `%LOCALAPPDATA%/clangd/config.yaml` if project flags are overridden: user
configuration takes precedence, and a global `-std:c++latest` is incompatible
with a CUDA command using the GNU-style driver.

Some Toolkit versions ship the CCCL `string_view` issue fixed by
[NVIDIA PR #7904](https://github.com/NVIDIA/cccl/pull/7904). When those exact
host-only deduction guide annotations are present, xmake creates a corrected
copy and a Clang VFS overlay under `build/clangd/`. Only clangd reads this overlay;
nvcc continues to compile against the installed Toolkit. The SDK and exercise
sources are not modified. Already-fixed headers need no overlay.

### TODO navigation

Install [Better Todo Tree](https://marketplace.visualstudio.com/items?itemName=FanaticPythoner.better-todo-tree)
from the recommended extensions. It provides the TODO tree and navigation and
imports existing `todo-tree.*` settings. Disable or uninstall the original
`Gruntfuggly.todo-tree` extension before using the fork, then run **Developer:
Reload Window** in each open project window.

The Windows package bundles ripgrep, so no machine-specific executable path is
needed in the shared workspace. The original Todo Tree can report
`command 'todo-tree.refresh' not found` when its older ripgrep lookup fails on
new VS Code layouts. Use **Better Todo Tree: Refresh** after migrating. Keep any
personal ripgrep override in local user settings rather than the shared
workspace, and remove stale overrides when changing operating systems.

Better Todo Tree 1.3.4 has been verified in VS Code on Windows: both the new
refresh command and its legacy alias execute, and the TODO tree includes CUDA
source files using the bundled ripgrep without a path override.

## CUDA debugging and profiling

Use [NVIDIA Nsight Visual Studio Edition](https://developer.nvidia.com/nsight-visual-studio-edition)
with Visual Studio 2022 for native Windows GPU debugging. Generate the solution:

```powershell
xmake project -k vsxmake -m "debug,release"
```

Open `vsxmake2022/CIS5650-Project1-xmake.sln`, select Debug and set
`cis5650_boids` as the startup project. Keep the debugger working directory at
the repository root so `shaders/` is found. Set a breakpoint in
`kernGenerateRandomPosArray` in `src/kernel.cu`, then choose **Start CUDA
Debugging** from the Nsight menu.

The committed VS Code CUDA launch configuration uses Linux `cuda-gdb`.
[Nsight Visual Studio Code Edition](https://developer.nvidia.com/nsight-visual-studio-code-edition)
requires a Linux development host for CUDA debugging; use the configuration on
Linux or through a supported remote Linux environment.

For native Windows profiling, use the Nsight Systems or Nsight Compute GUI with
the Release executable and the repository root as its working directory. Store
captures under the ignored `build/profiles/` directory. The shell commands in
`LINUX_SETUP.md` are for Linux.

## Validation

Debug and Release builds and `xmake run cis5650_boids` have been verified on the
validation machine. In each mode, the starter runs for six seconds, loads all
three shaders, prints sorted Thrust keys with their matching values, and reports
SM 8.9 and the RTX 4080 SUPER in its window title. Closing the window returns
exit code 0 with no stderr output.

The Visual Studio solution and clangd configuration are generated locally and
ignored by Git. Clangd 23.1.0 parses all project compilation units and headers
without syntax or configuration errors. The checks disable clangd's refactoring
self-tests (`--tweaks=`), which are separate from source diagnostics. A live
Nsight breakpoint session and Windows profiler captures have not been
validated. Simulation TODOs remain for the student to implement.
