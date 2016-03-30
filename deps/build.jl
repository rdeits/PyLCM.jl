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
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.1/lcm-1.3.1.zip"),
    lcm)

provides(BuildProcess, Dict(Autotools(libtarget="lcm/liblcm.la") => lcm), onload="""
using PyCall
@pyimport sys
unshift!(PyVector(pyimport("sys")["path"]), joinpath("$(prefix)", "lib", "python" * string(sys.version_info[1]) * "." * string(sys.version_info[2]), "site-packages"))
"""
)

begin
    cd(joinpath(BinDeps.depsdir(lcm), ".."))
    run(`$(joinpath(prefix, "bin", "lcm-gen")) -p test/multidim_array_t.lcm`)
end

@BinDeps.install Dict(:lcm => :liblcm)
