# test_local_channels.jl

# enable distrbuted computing
using Distributed
@info("Enabled distributed computing")

# this should be the next step
np = addprocs(4; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliInvoicing
end;

@info("Distributed computing enabled")

# get the tasks and dispatcher
include("./api/myfunctions.jl");
@info("Loaded ./api/myfunctions.jl")

# start the dispatcher
rx = dispatcher()
@info("Dispatcher started")

# start the application
@info("The Master will start the process and asks for test orders from the AppliSales module")
put!(rx, "START")

# process payments
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

@info("Master got $(length(stms)) bank statements")
@info("Master will put $(length(stms)) bank statements on rx channel")
put!(rx, stms)

# unkown data type
test = "Test unkown type"
put!(rx, test)
#end
