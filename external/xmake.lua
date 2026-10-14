-- Install only GLM, so Linux cannot pick up the bundled Windows GLEW/GLFW
-- headers when using the source-built xmake packages for those libraries.
package("vendored_glm")
    set_kind("library", {headeronly = true})
    set_description("Repository GLM 0.9.6.3 headers")
    set_license("MIT")
    set_sourcedir(path.join(os.scriptdir(), "include"))
    on_install(function (package)
        os.cp("glm", package:installdir("include"))
    end)
    on_test(function (package)
        assert(package:has_cxxtypes("glm::vec3", {includes = "glm/glm.hpp"}))
    end)
package_end()
