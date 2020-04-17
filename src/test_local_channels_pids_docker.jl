# test_remote_channels_pids.jl

# remove old stuff
cmd = `rm invoicing.sqlite ledger.txt journal.txt`
run(cmd)


# enable distrbuted computing
using Distributed

#addprocs(4)
#addprocs([("rob@172.17.0.2", 1), ("rob@172.17.0.3", 1)]; exeflags=`--project=$(Base.active_project())`)
addprocs([("rob@172.17.0.2", 1), ("rob@172.17.0.3", 1)]; exeflags=`--project=$(Base.active_project())`)
addprocs([("rob@192.168.2.77:2222", :auto)]; exeflags=`--project=$(Base.active_project())`)

p = 2 # invoicing (orders/bankstatements)
q = 3 # general ledger

# define local path fot AppliInvoicing
@everywhere push!(LOAD_PATH, "/home/rob/julia-projects/tc/AppliInvoicing")

# activate the packages
@everywhere using AppliSales
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

# get tasks
include("./api/myfunctions_pids.jl")

# start dispatcher
rx = dispatcher()

# start application
put!(rx, "START")

# processing the uppaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)
put!(rx, stms)

# unkown type
test = "Test unkown type"
put!(rx, test)
