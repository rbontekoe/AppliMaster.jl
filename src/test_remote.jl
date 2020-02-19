# test_remote.jl

# enable distrbuted computing
using Distributed

# then define the packages
#@everywhere using Dates
@everywhere using AppliSales
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

# this should be the next step
addprocs(4)

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"

# get the orders
orders = AppliSales.process()

journal_entries_1 = @fetch AppliInvoicing.process(PATH_DB, orders)

journal_entries_2 = @fetch begin
    # get Bank statements and the unpaid invoices
    stms = AppliInvoicing.read_bank_statements(PATH_CSV)
    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)

    # create journal entries & save paid invoices
    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
end


# =========================================================================

const PATH_DB_LEDGER = "./ledger.sqlite"

result = @fetch begin
    AppliGeneralLedger.process(PATH_DB_LEDGER, journal_entries_1)
end

result = @fetch begin
    AppliGeneralLedger.process(PATH_DB_LEDGER, journal_entries_2)
end

# =======================================================================
# inspect the database ledger.sqlite
# =======================================================================
using AppliSQLite

db2 = connect(PATH_DB_LEDGER)

# get all records
r = retrieve(db2, "LEDGER")

println(r)

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
stm = `rm invoicing.sqlite ledger.sqlite`
run(stm)
