# test_remote_channels.jl

# enable distrbuted computing
using Distributed
@info("Enabled distributed computing")

# this should be the next step
#np = addprocs(4)
np = addprocs(4; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliInvoicing
end

# get tasks and dispatcher
include("./api/myfunctions.jl");
@info("Loaded ./api/myfunctions.jl")



@info("running test_remote_channel.jl")

# start dispatcher
rx = dispatcher()
@info("Dispatcher started")

#runcode(channel) = begin
# start the application
@info("The Master will start the process and asks for test orders from the AppliSales module")
put!(rx, "START")

# processing the uppaid invoices
#@info("Master will read file with 2 bank statements")
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

@info("Master got $(length(stms)) bank statements")
@info("Master will put $(length(stms)) bank statements on rx channel")
put!(rx, stms)

#unkown type
test = "Test unkown type"
put!(rx, test)
#end
