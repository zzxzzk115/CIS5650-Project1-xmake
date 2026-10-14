target("cis5650_boids")
    set_kind("binary")
    add_files("*.cpp", "*.cu")
    add_headerfiles("*.hpp", "*.h")
    add_packages("vendored_glm")
    if is_plat("windows") then
        -- The bundled x64 MSVC libraries use the DLL CRT in both build modes.
        set_arch("x64")
        set_runtimes("MD")
        -- CUDA 13's CCCL headers require the conforming MSVC preprocessor.
        add_cxxflags("/Zc:preprocessor")
        add_cuflags("-Xcompiler=/Zc:preprocessor")
        add_defines("GLEW_STATIC")
        add_includedirs("../external/include")
        add_linkdirs("../external/lib/vc2015")
        add_links("glew32s", "glfw3")
        add_syslinks("opengl32", "gdi32", "user32", "shell32")
    else
        add_packages("glfw", "glew")
        add_syslinks("GL")
    end
    -- The starter loads shaders relative to the repository root.
    set_rundir("$(projectdir)")
    before_run(function (target)
        if target:is_plat("linux") then
            os.setenv("WAYLAND_DISPLAY", nil)
            os.setenv("__NV_PRIME_RENDER_OFFLOAD", "1")
            os.setenv("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
        end
    end)
target_end()
