# test.jl

using AppliSQLite
using AppliSales
using AppliGeneralLedger
using AppliInvoicing

const PATH_DB = "./invoicing.sqlite"

const PATH_CSV = "./bank.csv"

# get orders
orders = AppliSales.process()

# process orders
db = connect(PATH_DB)

journal_entries_1 = AppliInvoicing.process(db, orders)

# get Bank statemnets and unpaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

unpaid_invoices = retrieve_unpaid_invoices(db)

# process unpaid invoices and bank staements
journal_entries_2 = AppliInvoicing.process(db, unpaid_invoices, stms)

# =============================

# process journal entries
db2 = connect("./ledger.sqlite")

AppliGeneralLedger.process(db2, journal_entries_1)

# process journal entries
AppliGeneralLedger.process(db2, journal_entries_2)

# get data form general ledger
using AppliSQLite

# read all general ledger accounts
r = retrieve(db2, "LEDGER")

println(r)

# get status of accouts receivable
r = retrieve(db2, "LEDGER", "accountid = 1300")

account_receivable = sum(r.debit - r.credit)

println("Status accounts receivable: € $account_receivable") # should be € 1210.0

# get status of sales
r = retrieve(db2, "LEDGER", "accountid = 8000")

sales = sum(r.credit - r.debit) # should return € 4000.0

println("Sales: € $sales")

# cleanup
stm = `rm invoicing.sqlite ledger.sqlite`

run(stm)
