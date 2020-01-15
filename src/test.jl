# test.jl

# get orders
using AppliSales

orders = AppliSales.process()

# create unpaid invoices from order and journal entries for generalledger
using AppliInvoicing

journal_entries_unpaid_invoices = AppliInvoicing.process(orders)

# process journal entries
using AppliGeneralLedger

AppliGeneralLedger.process(journal_entries_unpaid_invoices)

# process bankstatements
journal_entries_invoices_paid = AppliInvoicing.process()

# process journal entries
AppliGeneralLedger.process(journal_entries_invoices_paid)

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

println("Status accounts receivable: € $account_receivable")

# get status of sales
r = retrieve(db, "LEDGER", "accountid = 8000")

sales = sum(r.credit - r.debit)

println("Sales: € $sales")

# cleanup
stm = `rm invoicing.sqlite ledger.sqlite`

run(stm)
