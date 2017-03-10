__precompile__()

module PyLCM

using PyCall
using Base.Dates: Period, Millisecond
using LCMCore
import LCMCore: encode, subscribe, decode

export LCM, publish, subscribe, handle, @pyimport

const pylcm = PyNULL()

# This is the only method required to enable publishing python
# LCM messages
encode(msg::PyObject) = pycall(msg[:encode], Vector{UInt8})

# We override the subscribe() method that takes in a user-supplied
# message type. That's because the method in LCMCore assumes that
# the Julia type of the message is enough to determine how to
# decode the message. That's not the case for PyLCM because all
# python LCM types are just PyObjects. 
function subscribe(lcm::LCM, channel::String, handler, msgtype::PyObject)
    function inner_handler(channel, data)
        pymsg = pycall(msgtype[:decode], PyObject, data)
        handler(channel, pymsg)
    end
    subscribe(lcm, channel, inner_handler)
end

function __init__()
    sys = pyimport("sys")
    if isdefined(LCMCore, :lcm_prefix)
        lcm_prefix = LCMCore.lcm_prefix
    else
        lcm_prefix = dirname(dirname(LCMCore.liblcm))
    end
    unshift!(PyVector(sys["path"]), joinpath(lcm_prefix, "lib", "python" * string(sys[:version_info][1]) * "." * string(sys[:version_info][2]), "site-packages"))
    copy!(pylcm, pyimport("lcm"))
end

end # module
