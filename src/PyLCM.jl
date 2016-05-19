VERSION >= v"0.4.0-dev+6521" && __precompile__()

module PyLCM

using PyCall
export LCM, publish, subscribe, handle, @pyimport

immutable LCM
	lcm_obj::PyObject

	LCM() = new(pylcm[:LCM]())
end

function publish(lc::LCM, channel::AbstractString, msg)
	pycall(lc.lcm_obj[:publish], PyAny, channel, pycall(msg[:encode], PyObject))
end

function subscribe(lc::LCM, channel::AbstractString, handler::Function)
	lc.lcm_obj[:subscribe](channel, pyeval("lambda chan, data, handler=h: handler(chan, bytearray(data))", h=handler))
end

function subscribe(lc::LCM, channel::AbstractString, handler::Function, msg_type::PyObject)
	lc.lcm_obj[:subscribe](channel, pyeval("lambda chan, data, handler=h, msg_type=t: handler(chan, msg_type.decode(data))", h=handler, t=msg_type))
end

function handle(lc::LCM)
	pycall(lc.lcm_obj[:handle], PyObject)
end

function __init__()
	depsjl = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
	isfile(depsjl) ? include(depsjl) : error("PyLCM not properly ",
	    "installed. Please run\nPkg.build(\"PyLCM\")")
	const global pylcm = pyimport("lcm")
end

end # module
