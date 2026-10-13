set_project("CIS5650-Project1-xmake")
set_xmakever("3.0.0")
set_allowedplats("linux")
set_languages("cxx17")
set_defaultmode("debug")

-- mode.debug supplies host symbols (-g) and CUDA device symbols (-G).
add_rules("mode.debug", "mode.release", "mode.releasedbg")
add_rules("plugin.compile_commands.autoupdate", {outputdir = ".", lsp = "clangd"})

-- Configure CUDA headers and generate local clangd paths and architecture.
rule("cuda.environment")
    add_deps("cuda.gencodes")
    on_config(function (target)
        import("core.base.json")
        local cuda = target:data("cuda")
        if not cuda then
            return
        end
        local flags = table.concat(table.wrap(target:get("cuflags")), " ")
        local arch = flags:match("code=%[?sm_(%d+%a*)") or flags:match("arch=compute_(%d+%a*)")
        assert(arch, "Cannot detect CUDA architecture; configure with --cuda_arch=sm_XX")
        -- CUDA 13 installs Thrust, CUB, and libcudacxx under include/cccl.
        local cccl = path.join(cuda.sdkdir, "include", "cccl")
        if os.isdir(cccl) then
            target:add("includedirs", cccl)
        end
        local root = os.projectdir()
        local contents = io.readfile(path.join(root, ".clangd.in"))
        contents = contents:gsub("@CUDA_PATH@", function ()
            return json.encode("--cuda-path=" .. cuda.sdkdir):gsub("\\/", "/")
        end)
        contents = contents:gsub("@CUDA_ARCH@", "sm_" .. arch)
        local output = path.join(root, ".clangd")
        if not os.isfile(output) or io.readfile(output) ~= contents then
            io.writefile(output, contents)
        end
    end)
rule_end()
add_rules("cuda.environment")

option("cuda_arch")
    set_default("native")
    set_showmenu(true)
    set_description("CUDA GPU architecture (native, or an explicit value such as sm_89)")
option_end()

-- An explicit architecture permits compilation without access to a GPU.
add_cugencodes(get_config("cuda_arch"))
set_targetdir("build/$(mode)")
if is_mode("release", "releasedbg") then
    add_cuflags("-lineinfo")
end

includes("src")
