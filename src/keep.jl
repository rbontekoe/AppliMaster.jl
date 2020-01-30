# keep.jl

# the functions
@everywhere function test(channel, value)
    println(value)
    while true
        if isready(channel)
            s = take!(channel)
            try
                println(s)
            catch e
                println("Hm... $e")
            end
        else
            wait(channel)
        end
    end
end

# init
#c1 = RemoteChannel(() -> Channel(32))

#remote_do(test, p, c1, "Hello")

#daisy = createSubscriber("Daisy")

#put!(c1, daisy)

#db = connect("rbo.sqlite")

#remote_do(updatetable, q, c1, "./rbo.sqlite", "subscribers")

#put!(c1, daisy)

#r = gather(connect("./rbo.sqlite"), "subscribers")
#println(r)
