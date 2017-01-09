VERSION >= v"0.4.0-dev+6521" && __precompile__()

module PyLCM

using Base.Dates: Period, Millisecond
using PyCall
export LCM, publish, subscribe, handle, @pyimport

const pylcm = PyNULL()

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

"Wait for and dispatch the next incoming message"
function handle(lc::LCM)
    pycall(lc.lcm_obj[:handle], PyObject)
    nothing
end

"""
    handle(lc, timeout)

Wait for and dispatch the next incoming message, with a timeout expressed
as any Base.Dates.Period type. For example:

    handle(lc, Millisecond(10))

or

    handle(lc, Second(1))

Returns true if a message was handled, false if the function timed out.
"""
function handle(lc::LCM, timeout::Period)
    timeout_ms = convert(Int, convert(Millisecond, timeout))
    convert(Bool, pycall(lc.lcm_obj[:handle_timeout], PyObject, timeout_ms))
end

function __init__()
	depsjl = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
	isfile(depsjl) ? include(depsjl) : error("PyLCM not properly ",
	    "installed. Please run\nPkg.build(\"PyLCM\")")
    copy!(pylcm, pyimport("lcm"))
end

end # module
