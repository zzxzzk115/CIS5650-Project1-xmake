target("cis5650_boids")
    set_kind("binary")
    add_files("*.cpp", "*.cu")
    add_headerfiles("*.hpp", "*.h")
    add_syslinks("glfw", "GLEW", "GL")
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
