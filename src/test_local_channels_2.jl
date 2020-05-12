# test_local_channels2.jl

using Pkg
Pkg.activate(".")

# remove old stuff
cmd = `rm test_invoicing.sqlite test_ledger.txt test_journal.txt`
run(cmd)

# enable distrbuted computing
using Distributed
@info("Enable distributed computing")

# this should be the next step
np = addprocs(4; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliAR
end;

@info("Distributed computing enabled")

# get the tasks and dispatcher
include("./api/api2.jl")

# start the dispatcher
rx = dispatcher()
@info("Dispatcher started")

# start application remote
include("client.jl")

# display aging report
using DataFrames

sleep(10)
r = DataFrame(report())
println("\nUnpaid invoices\n$("="^15)")
println(r)
