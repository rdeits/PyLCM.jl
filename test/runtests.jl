using PyLCM
using Base.Test

# We need to add the current folder to the python path so it will pick up our message type
using PyCall
unshift!(PyVector(pyimport("sys")["path"]), ".")

test_data = rand(Int32, 2, 3, 4)
test_strings =  AbstractString["foo$(rand(Int32))" for i in 1:2, j in 1:size(test_data, 3)]

global got_message = false

@pyimport pylcm_test_message
msg = pylcm_test_message.multidimensional_array_t()
msg[:size_a] = size(test_data, 1)
msg[:size_b] = size(test_data, 2)
msg[:size_c] = size(test_data, 3)
msg[:data] = test_data
msg[:strarray] = test_strings

lc = LCM()

function handle_msg(channel, msg)
	global got_message = true
	for i = 1:size(test_data, 1)
		for j = 1:size(test_data, 2)
			for k = 1:size(test_data, 3)
				@test msg[:data][i,j][k] == test_data[i,j,k]
			end
		end
	end
	@test msg[:strarray] == test_strings
end

subscribe(lc, "TEST", handle_msg, pylcm_test_message.multidimensional_array_t)
publish(lc, "TEST", msg)
@test handle(lc)
@test got_message

global decoded_message = false

function decode_and_handle_msg(channel, msg_data)
	global decoded_message = true
	msg = pylcm_test_message.multidimensional_array_t[:decode](msg_data)
	for i = 1:size(test_data, 1)
		for j = 1:size(test_data, 2)
			for k = 1:size(test_data, 3)
				@test msg[:data][i,j][k] == test_data[i,j,k]
			end
		end
	end
	@test msg[:strarray] == test_strings
end

subscribe(lc, "TEST_DECODE", decode_and_handle_msg)
publish(lc, "TEST_DECODE", msg)
@test handle(lc, Dates.Second(1))
@test decoded_message
