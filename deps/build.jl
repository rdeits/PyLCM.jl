using BinDeps

@BinDeps.setup

deps = [
	gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0"])
	lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.so.1"])
	]
	# pkgconfig = library_dependency("pkgconfig", aliases = ["pkg-config"])

@osx_only begin
	using Homebrew
	provides(Homebrew.HB, "glib", gobject, os=:Darwin)
	# provides(Homebrew.HB, "pkg-config", pkgconfig, os=:Darwin)
end

provides(AptGet,
	Dict("libglib2.0-dev" => gobject,
	 # "build-essential" => pkgconfig
	 ))

provides(Yum,
    Dict("glib" => gobject,
     # "pkgconfig" => pkgconfig
     ))

provides(Sources,
	Dict(URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip") => lcm))

provides(BuildProcess,
	Dict(Autotools() => lcm))

@BinDeps.install

