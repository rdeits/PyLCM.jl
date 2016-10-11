using BinDeps
using Compat

@BinDeps.setup

function cflags_validator(pkg_name)
    return (name, handle) -> begin
        try
            run(`pkg-config --cflags $(pkg_name)`)
            return true
        catch ErrorException
            return false
        end
    end
end

@static if is_linux()
    deps = [
        python = library_dependency("python", aliases=["libpython2.7.so", "libpython3.2.so", "libpython3.3.so", "libpython3.4.so", "libpython3.5.so", "libpython3.6.so", "libpython3.7.so"], validate=cflags_validator("python"))
        glib = library_dependency("glib", aliases=["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"], depends=[python], validate=cflags_validator("glib-2.0"))
        lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])

        provides(AptGet, Dict("python-dev" => python, "libglib2.0-dev" => glib))
    ]
else
    deps = [
        glib = library_dependency("glib", aliases = ["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"])
        lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])
    ]
end

prefix = joinpath(BinDeps.depsdir(lcm), "usr")

@static if is_apple()
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", glib, os=:Darwin)
end

provides(Yum,
    Dict("glib" => glib))

lcm_sha = "9e53469cd0713ca8fbf37a968f6fd314f5f11584"
lcm_folder = "lcm-$(lcm_sha)"

provides(Sources,
    URI("https://github.com/lcm-proj/lcm/archive/$(lcm_sha).zip"),
    lcm,
    unpacked_dir=lcm_folder)

lcm_builddir = joinpath(BinDeps.depsdir(lcm), "builds", "lcm")
lcm_srcdir = joinpath(BinDeps.depsdir(lcm), "src", lcm_folder)
homebrew_library_dir = joinpath(BinDeps.depsdir("Homebrew"), "usr", "lib")

provides(BuildProcess,
    (@build_steps begin
        GetSources(lcm)
        CreateDirectory(lcm_builddir)
        @build_steps begin
            ChangeDirectory(lcm_builddir)
            `cmake -DCMAKE_INSTALL_PREFIX="$(prefix)" $(lcm_srcdir) -DCMAKE_LIBRARY_PATH=$(homebrew_library_dir)`
            `cmake --build . --target install`
        end
    end),
    lcm,
    onload="""
using PyCall
sys = pyimport("sys")
unshift!(PyVector(sys["path"]), joinpath("$(prefix)", "lib", "python" * string(sys[:version_info][1]) * "." * string(sys[:version_info][2]), "site-packages"))
"""
)

@BinDeps.install Dict(:lcm => :liblcm)
