# check_dbs.jl

@info("running check_dbs.jl")

# =======================================================================
# inspect the database ledger.sqlite
# =======================================================================

using AppliSQLite

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

db2 = connect(PATH_DB_LEDGER)

# get status of accouts receivable
# get all records of accounts receivable
r = retrieve(db2, "LEDGER", "accountid = 1300")
# calculate and print the balance
account_receivable = sum(r.debit - r.credit)
@info("Balance of accounts receivable is $(account_receivable). Should be 1210")

# get status of sales
r = retrieve(db2, "LEDGER", "accountid = 8000")
# calculate and print the balance
sales = sum(r.credit - r.debit) # should return € 4000.0
@info("Sales is $(sales). Should be 4000.")

# cleanup
stm = `rm invoicing.sqlite ledger.sqlite log_master.txt`
run(stm)
