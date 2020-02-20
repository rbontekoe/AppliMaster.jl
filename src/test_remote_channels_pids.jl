# test_remote_channels_pids.jl

# enable distrbuted computing
using Distributed

# activating logging
# see: https://discourse.julialang.org/t/how-to-save-logging-output-to-a-log-file/14004/5
#using Logging
#io = open("log_master.txt", "w+")
#logger = SimpleLogger(io)
#global_logger(logger)

# this should be the next step.
# in the future we will run the tasks in different containers.
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

# Processing the orders
#=
orders = AppliSales.process()
put!(rx, orders)
=#

put!(rx, "START")

# processing the uppaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)
put!(rx, stms)

# unkown type
test = "Test unkown type"
put!(rx, test)

# write otput to log_master.txt
#flush(io)


#stm = `rm invoicing.sqlite ledger.sqlite log_master.txt`
stm = `rm invoicing.sqlite ledger.sqlite`
run(stm)
