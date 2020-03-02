# test_remote_channels_pids.jl

# enable distrbuted computing
using Distributed

#addprocs(4)
addprocs(4; exeflags=`--project=$(Base.active_project())`)
p = 3 # invoicing (orders/bankstatements)
q = 4 # general ledger

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
