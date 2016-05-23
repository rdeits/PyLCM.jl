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

@linux? (
    begin
        deps = [
            python = library_dependency("python", aliases=["libpython2.7.so", "libpython3.2.so", "libpython3.3.so", "libpython3.4.so", "libpython3.5.so", "libpython3.6.so", "libpython3.7.so"], validate=cflags_validator("python"))
            glib = library_dependency("glib", aliases=["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"], depends=[python], validate=cflags_validator("glib-2.0"))
            lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])

            provides(AptGet, Dict("python-dev" => python, "libglib2.0-dev" => glib))
        ]
    end
    : begin
        deps = [
            glib = library_dependency("glib", aliases = ["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"])
            lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])
        ]
    end
    )

prefix = joinpath(BinDeps.depsdir(lcm), "usr")
@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", glib, os=:Darwin)
    ENV["PKG_CONFIG_PATH"] = get(ENV, "PKG_CONFIG_PATH", "") * ":" * joinpath(Homebrew.prefix(), "lib", "pkgconfig")
    ENV["INCLUDE_PATH"] = get(ENV, "INCLUDE_PATH", "") * ":" * joinpath(Homebrew.prefix(), "include")
end

provides(Yum,
    Dict("glib" => glib))

provides(Sources,
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.1/lcm-1.3.1.zip"),
    lcm)

provides(BuildProcess, Dict(Autotools(libtarget="lcm/liblcm.la") => lcm), onload="""
using PyCall
sys = pyimport("sys")
unshift!(PyVector(sys["path"]), joinpath("$(prefix)", "lib", "python" * string(sys[:version_info][1]) * "." * string(sys[:version_info][2]), "site-packages"))
"""
)

@BinDeps.install Dict(:lcm => :liblcm)
