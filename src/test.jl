# test.jl

const PATH_DB = "./invoicing.sqlite"

const PATH_CSV = "./bank.csv"

# get orders
using AppliSales

orders = AppliSales.process()

# process orders
using AppliInvoicing

journal_entries_1 = AppliInvoicing.process(PATH_DB, orders)

# get Bank statemnets and unpaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

unpaid_invoices = AppliInvoicing.retrieve_unpaid_invoices(PATH_DB)

# process unpaid invoices and bank staements
journal_entries_2 = AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)

# =============================

# process journal entries
using AppliGeneralLedger

AppliGeneralLedger.process(journal_entries_1)

# process journal entries
AppliGeneralLedger.process(journal_entries_2)

# get data form general ledger
using AppliSQLite

# connect to ledger.sqlite file
db = connect("./ledger.sqlite")

# read all general ledger accounts
r = retrieve(db, "LEDGER")

println(r)

# get status of accouts receivable
r = retrieve(db, "LEDGER", "accountid = 1300")

account_receivable = sum(r.debit - r.credit)

println("Status accounts receivable: € $account_receivable") # should be € 1210.0

# get status of sales
r = retrieve(db, "LEDGER", "accountid = 8000")

sales = sum(r.credit - r.debit) # should retirn € 4000.0

println("Sales: € $sales")

# cleanup
#stm = `rm invoicing.sqlite ledger.sqlite`

#run(stm)
