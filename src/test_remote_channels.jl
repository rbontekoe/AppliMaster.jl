# test_remote3.jl

# enable distrbuted computing
using Distributed

# activateing logging
# see: https://discourse.julialang.org/t/how-to-save-logging-output-to-a-log-file/14004/5
using Logging
io = open("log_master.txt", "w+")
logger = SimpleLogger(io)
global_logger(logger)

# get tasks
include("./api/myfunctions2.jl");

# this should be the next step.
# in the future we will run the tasks in different containers.
addprocs(4)
p = 3 # invoicing
q = 4 # general ledger
r = 5

# activate the packages
@everywhere using AppliSales
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

# start dispatcher
rx = dispatcher()

# Processing the orders
orders = AppliSales.process()
put!(rx, orders)

sleep(0.1)

# processing the uppaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)
put!(rx, stms)

# unkown type
test = "Unkown"
put!(rx, test)

# write output to log_master.txt
flush(io)
