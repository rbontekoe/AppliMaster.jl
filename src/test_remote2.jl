# test2.jl

# enable distrbuted computing
using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

# get listener
include("./myfunctions.jl")

# this should be the next step
addprocs(4)
p = 3 # invoicing
q = 4 # general ledger
r = 5

# then define the packages
#@everywhere using Dates
@everywhere using AppliSales
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

# get the orders
orders = AppliSales.process()

const c1 = Channel(32)

@async test_idea1(c1, p) # invoicing

@async test_idea2(c1, q) # general ledger

@async test_idea3(c1, 5) # invoicing

put!(c1, orders)

stms = AppliInvoicing.read_bank_statements(PATH_CSV)

sleep(30)

put!(c1, stms)


# =======================================================================
# inspect the database ledger.sqlite
# =======================================================================
using AppliSQLite

db2 = connect(PATH_DB_LEDGER)

# get all records
#r = retrieve(db2, "LEDGER")

#println(r)

# get status of accouts receivable
# get all records of accounts receivable
r = retrieve(db2, "LEDGER", "accountid = 1300")
# calculate and print the balance
account_receivable = sum(r.debit - r.credit)
@info("Balance of accounts receivable is $(account_receivable). Should be 1210")
println("Status accounts receivable: € $account_receivable") # should be € 1210.0

# get status of sales
r = retrieve(db2, "LEDGER", "accountid = 8000")
# calculate and print the balance
sales = sum(r.credit - r.debit) # should return € 4000.0
@info("Sales is $(sales). Should be 4000.")
println("Sales: € $sales")

# cleanup
#stm = `rm invoicing.sqlite ledger.sqlite`
#run(stm)
