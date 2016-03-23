using BinDeps
using Compat

@BinDeps.setup

deps = [
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0", "libgobject-2_0-0", "libgobject-2.0.so.0"])
    lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[gobject])
]

prefix = joinpath(BinDeps.depsdir(lcm), "usr")
@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", gobject, os=:Darwin)
    pkg_config_path = joinpath(Homebrew.prefix(), "lib", "pkgconfig")
    ENV["PKG_CONFIG_PATH"] = get(ENV, "PKG_CONFIG_PATH", "") * pkg_config_path
    ENV["INCLUDE_PATH"] = get(ENV, "INCLUDE_PATH", "") * joinpath(Homebrew.prefix(), "include")
end

provides(AptGet, Dict("libglib2.0-dev" => gobject))

provides(Yum,
    Dict("glib" => gobject))

provides(Sources,
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip"),
    lcm)

provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcm)
        @build_steps begin
            ChangeDirectory(joinpath(BinDeps.depsdir(lcm), "src", "lcm-1.3.0"))
            `./configure --prefix=$(prefix) --with-java=no` # disable java due to https://github.com/lcm-proj/lcm/issues/56
            MakeTargets(".", [])
            MakeTargets(".", ["install"])
        end
    end), lcm, onload="""
using PyCall
@pyimport sys
unshift!(PyVector(pyimport("sys")["path"]), joinpath("$(prefix)", "lib", "python" * string(sys.version_info[1]) * "." * string(sys.version_info[2]), "site-packages"))
"""
)

@BinDeps.install Dict(:lcm => :liblcm)
