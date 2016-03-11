using BinDeps

@BinDeps.setup

deps = [
	gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0"])
	lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.so.1", "liblcm.so.1.3.4"])
	]
	# pkgconfig = library_dependency("pkgconfig", aliases = ["pkg-config"])

# @linux_only begin
# 	append!(deps, [java6 = library_dependency("openjdk-6-jdk")])
# end

@osx_only begin
	using Homebrew
	provides(Homebrew.HB, "glib", gobject, os=:Darwin)
	# provides(Homebrew.HB, "pkg-config", pkgconfig, os=:Darwin)
end

provides(AptGet,
	Dict("libglib2.0-dev" => gobject,
	     # "openjdk-6-jdk" => java6
	 # "build-essential" => pkgconfig
	 ))

provides(Yum,
    Dict("glib" => gobject,
     # "pkgconfig" => pkgconfig
     ))

provides(Sources,
	Dict(URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip") => lcm))

provides(BuildProcess,
	Dict(Autotools(configure_options=["--without-java"]) => lcm))

@BinDeps.install

