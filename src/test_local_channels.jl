# test_local_channels.jl

# remove old stuff
cmd = `rm test_invoicing.sqlite test_ledger.txt test_journal.txt`
run(cmd)

# activateing logging
# see: https://discourse.julialang.org/t/how-to-save-logging-output-to-a-log-file/14004/5
#=
using Logging
io = open("log_master.txt", "w+")
logger = SimpleLogger(io)
global_logger(logger)
=#

# enable distrbuted computing
using Distributed
@info("Enable distributed computing")

# this should be the next step
np = addprocs(4; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# define local path fot AppliInvoicing
@everywhere push!(LOAD_PATH, "/home/rob/julia-projects/tc/AppliInvoicing")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliInvoicing
end;

@info("Distributed computing enabled")

# get the tasks and dispatcher
include("./api/api.jl")
#include("./api/myfunctions2.jl");
#@info("Loaded ./api/myfunctions2.jl")using AppliSales: process

# start the dispatcher
rx = dispatcher()
@info("Dispatcher started")

# start the application
@info("The Master will start the process and asks for test orders from the AppliSales module")
put!(rx, "START")

# process payments
stms = AppliInvoicing.read_bank_statements("./bank.csv")

@info("Master got $(length(stms)) bank statements")
@info("Master will put $(length(stms)) bank statements on rx channel")
put!(rx, stms)

# unkown data type
test = "Test unkown type"
put!(rx, test)
#end

# aging report
using DataFrames
r = DataFrame(report(;path=PATH_DB))
println("\nUnpaid invoices\n============")
println(r)

# cleanup
#flush(io)
