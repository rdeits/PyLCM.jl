# PyLCM: Julia bindings for LCM, using PyCall

[![Build Status](https://travis-ci.org/rdeits/PyLCM.jl.svg?branch=master)](https://travis-ci.org/rdeits/PyLCM.jl)
[![codecov.io](https://codecov.io/github/rdeits/PyLCM.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/PyLCM.jl?branch=master)

PyLCM provides an interface to the [Lightweight Communications and Marshalling (LCM) library](https://lcm-proj.github.io/) in Julia. It wraps the LCM Python interface using [PyCall](https://github.com/stevengj/PyCall.jl), so it will be slower than calling the LCM C-API directly.

# Installation

If you have a systemwide installation of LCM, PyLCM will try to use it. If you don't, then running `Pkg.build("PyLCM")` will download and install a private copy of LCM and the python bindings for you.

# Usage

### Constructing the LCM object:

```julia
using PyLCM
lc = LCM()
```
### Constructing a message:

```julia
msg = exlcm.example_t()
msg[:timestamp] = 12345
msg[:enabled] = true
msg[:position] = zeros(3)
```

### Publishing a message

```julia
publish(lc, "MY_CHANNEL", msg)
```

### Handling and subscribing to messages

You can handle and subscribe to messages with PyLCM just as you would in Python. Your handler should be a Julia function that takes two arguments: the channel and the message data. By default, the LCM python API will call your message handler function with the channel name and the raw bytes of the encoded message, so you will need to use the `:decode` static method to interpret that data inside your handler:

```julia
function handle_msg(channel, msg_data)
    msg = exlcm.example_t[:decode](msg_data)
    @show msg[:timestamp]
end

subscribe(lc, "MY_CHANNEL", handle_msg)

while true
    handle(lc)
end
```

Since that might be annoying, `PyLCM` also provides a 4-argument `subscribe()` method which also takes in the message type. When used this way, the handler will be called with the decoded message object, instead of the byte array:

```julia
function handle_msg(channel, msg)
    @show msg[:timestamp]
end

# Pass the exlcm.example_t type in to subscribe() to have message data automatically decoded
subscribe(lc, "MY_CHANNEL", handle_msg, exlcm.example_t)
while true
    handle(lc)
end
```
