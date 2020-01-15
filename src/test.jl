# test.jl

# get orders
using AppliSales

orders = AppliSales.process()

# create unpaid invoices from order
using AppliInvoicing

unpaid_invoices = AppliInvoicing.process(orders)

# process journal unpaid statements
using AppliGeneralLedger

AppliGeneralLedger.process(unpaid_invoices)

# process bankstatements
paid_invoices = AppliInvoicing.process()

# processjournal paid statements
AppliGeneralLedger.process(paid_invoices)

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
