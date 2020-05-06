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
#np = addprocs([("rob@192.168.2.77:2222", :auto)]; exeflags=`--project=$(Base.active_project())`)
@info("number of processes is $(length(np))")

# activate the packages (before the processes are created)
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliAR
end;

@info("Distributed computing enabled")

# get the tasks and dispatcher
include("./api/api.jl")

# start the dispatcher
rx = dispatcher()
@info("Dispatcher started")

# start remote
include("client.jl")

# aging report
using DataFrames

sleep(10)
r = DataFrame(report())
println("\nUnpaid invoices\n============")
println(r)
