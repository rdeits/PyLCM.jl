__precompile__()

module PyLCM

export LCM, publish, subscribe, handle
global pylcm

using PyCall

immutable PyLCMWrapper
	lcm_obj::PyObject
end

function LCM()
	PyLCMWrapper(pylcm[:LCM]())
end

function publish(lc::PyLCMWrapper, channel::AbstractString, msg)
	pycall(lc.lcm_obj[:publish], PyAny, channel, pycall(msg[:encode], PyObject))
end

function subscribe(lc::PyLCMWrapper, channel::AbstractString, handler::Function)
	lc.lcm_obj[:subscribe](channel, pyeval("lambda chan, data, handler=h: handler(chan, bytearray(data))", h=handler))
end

function subscribe(lc::PyLCMWrapper, channel::AbstractString, handler::Function, msg_type::PyObject)
	lc.lcm_obj[:subscribe](channel, pyeval("lambda chan, data, handler=h, msg_type=t: handler(chan, msg_type.decode(data))", h=handler, t=msg_type))
end

function handle(lc::PyLCMWrapper)
	pycall(lc.lcm_obj[:handle], PyObject)
end

function __init__()
	global pylcm = pyimport("lcm")
end

end # module
