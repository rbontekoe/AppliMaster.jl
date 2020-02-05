# test_remote_channels.jl
@info("test_remote_channels.jl")

# enable distrbuted computing
using Distributed
@info("Enabled distributed computing")

# this should be the next step
np = addprocs(4)
@info("number of processes is $(length(np))")

# get tasks and dispatcher
include("./api/myfunctions.jl");
@info("Loaded ./api/myfunctions.jl")

# activate the packages (before the processes are created)
using AppliSales # only used by
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

@info("running test_remote_channel.jl")

# start dispatcher
rx = dispatcher()
@info("Dispatcher started")

# Processing the orders
@info("Master will ask for 3 test orders from the AppliSales module")
orders = AppliSales.process()
@info("Master received $(length(orders)) orders")
@info("Master will put $(length(orders)) orders on rx channel")
put!(rx, orders)

# processing the uppaid invoices
@info("Master will read file with 2 bank statements")
stms = AppliInvoicing.read_bank_statements(PATH_CSV)
@info("Master got $(length(stms)) bank statements")
@info("Master will put $(length(stms)) bank statements on rx channel")
put!(rx, stms)

# unkown type
test = "Test unkown type"
put!(rx, test)
