using BinDeps
using Compat

@BinDeps.setup

# Be specific about which libglib-2.0 we're looking for, since lcm actually
# needs libglib-2.0-dev.
@linux? ( begin
              glib = library_dependency("glib", aliases = ["/usr/lib/x86_64-linux-gnu/libglib-2.0.so"])
          end
        : begin
              glib = library_dependency("glib", aliases = ["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"])
          end
        )

deps = [
    glib
    lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])
]


prefix = joinpath(BinDeps.depsdir(lcm), "usr")
@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", glib, os=:Darwin)
    pkg_config_path = joinpath(Homebrew.prefix(), "lib", "pkgconfig")
    ENV["PKG_CONFIG_PATH"] = get(ENV, "PKG_CONFIG_PATH", "") * pkg_config_path
    ENV["INCLUDE_PATH"] = get(ENV, "INCLUDE_PATH", "") * joinpath(Homebrew.prefix(), "include")
end

provides(AptGet, Dict("libglib2.0-dev" => glib))

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
