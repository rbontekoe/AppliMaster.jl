# test_local_channels.jl

using Pkg
Pkg.activate(".")

# remove old stuff
cmd = `rm test2_invoicing.sqlite test2_ledger.txt test2_journal.txt log_master.txt`
run(cmd)

# activateing logging
# see: https://discourse.julialang.org/t/how-to-save-logging-output-to-a-log-file/14004/5
using Logging
io = open("log_master.txt", "w+")
logger = SimpleLogger(io)
global_logger(logger)

# enable distrbuted computing
using Distributed
@info("Enable distributed computing")

# this should be the next step
np = addprocs(4; exeflags=`--project=$(Base.active_project())`)
#np = addprocs([("rob@192.168.2.77:2222", :auto)]; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# define local path for AppliAR
#@everywhere push!(LOAD_PATH, "/home/rob/.julia/dev/AppliAR")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliAR
end;

@info("Distributed computing enabled")

# get the tasks and dispatcher
include("./api/api1.jl")

# start the dispatcher
rx = dispatcher()
@info("Dispatcher started")

# start the application
@info("The Master will start the process and asks for test orders from the AppliSales module")
put!(rx, "START")


# process payments
stms = AppliAR.read_bank_statements("./bank.csv")

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
flush(io)
