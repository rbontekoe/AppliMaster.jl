rob@13304c03391d:~$ cat main.jl
using Distributed

#=
The container that wants to run code on another container initiate this function.It has two arguments:
- pid, the process id created wi th the addprocs function.
- funct, to run on the container, or remote machine. funct is in this example a function that accepts only one argument.
=#
function remote_body(pid::Int, funct)
    tx = RemoteChannel(() -> Channel(32)) # local transmit channel
    rx = RemoteChannel(() -> Channel(32)) # local receive channel

    # run the code on the process id that has been passed
    @async @spawnat pid begin
        while true
	    try
                if isready(tx) # channel has data

                    # get the data from the tx-channel
                    value = take!(tx)

                    # execute the code of the function that was passed as argument
                    result = funct(value)

                    # for test purposes
                    #@show result

                    # put the result of the function on the rx-channel
                    put!(rx, result)
                else

                    # for test purposes
                    #which_funct = string(funct) * " on process " * string(myid()) * " is waiting for data."
                    #@show which_funct

                    # the code wait until there is data on the tx-channel
                    wait(tx)
                end
	    catch e
	       put!(rx, e)
	    end
        end
    end

    # return transmit and receive channel, so the calling container can communicate with the called container.
    tx, rx

end # defined remote_body

d = Dict([]) # empty directory for pids, used by the calling container

========================

julia> addprocs([("rob@172.17.0.3", 1)])

julia> remotecall_fetch(f3, 2, "subscribers")

julia> @everywhere f3(x) = begin
          db = connect("./rbo.sqlite") # connect to database
          gather(db, x) # list all items in table x
       end

julia> remotecall_fetch(f3, 2, "subscribers")

julia> include("main.jl")

julia> delete!(d, "test_sshd2")

julia> remotecall_fetch(f3, 2, "subscribers")

julia> addprocs([("rob@172.17.0.3", 1)])

julia> delete!(d, "test_sshd2")

julia> # define a new function to create a new subscriber and save it in a database
       @everywhere f2(x) = begin
                 s = createSubscriber(x) # create a subscriber
               db = connect("./rbo.sqlite") # connect to database
               create(db, "subscribers", [s]) # save subscriber in database
       end

julia> @everywhere using RbO

julia> d["test_sshd2"] = last(workers())


=============================================

julia> using Dates

julia> using AppliSales

julia> using AppliGeneralLedger

julia> using AppliInvoicing

julia> const PATH_DB = "./invoicing.sqlite"

julia> const PATH_CSV = "./bank.csv"

julia> orders = AppliSales.process()

julia> journal_entries_1 = AppliInvoicing.process(PATH_DB, orders)

julia> stms = AppliInvoicing.read_bank_statements(PATH_CSV)

julia> unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)

julia> journal_entries_2 = AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
