# test.jl

using AppliSales
using AppliGeneralLedger
using AppliInvoicing

# activateing logging
# see: https://discourse.julialang.org/t/how-to-save-logging-output-to-a-log-file/14004/5
#using Logging
#io = open("log_master.txt", "w+")
#logger = SimpleLogger(io)
#global_logger(logger)

const PATH_DB = "./invoicing.sqlite"

const PATH_CSV = "./bank.csv"

# get orders
orders = AppliSales.process()
@info("Received $(length(orders)) orders from AppliSales.")

journal_entries_1 = AppliInvoicing.process(PATH_DB, orders)
@info("Saved unpaid invoices, and created $(length(journal_entries_1)) journal entries of it.")

# get Bank statemnets and unpaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)

@info("Read bankstatements and retrieved unpaid invoices.")

# process unpaid invoices and bank staements
journal_entries_2 = AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
@info("Saved paid invoices and created $(length(journal_entries_2)) journal entries of it.")

# =============================

# process journal entries
#const PATH_DB_LEDGER = "./ledger.sqlite"
const PATH_DB_LEDGER = "./ledger.txt"
const PATH_DB_JOURNAL = "./journal.txt"

AppliGeneralLedger.process(PATH_DB_JOURNAL, PATH_DB_LEDGER, journal_entries_1)
@info("Processed unpaid journal entries")

# process journal entries

AppliGeneralLedger.process(PATH_DB_JOURNAL, PATH_DB_LEDGER, journal_entries_2)
@info("Processed paid journal entries")

# read all general ledger accounts
r = AppliGeneralLedger.read_from_file(PATH_DB_LEDGER)

using DataFrames

df = DataFrame(r)

println(df)

df2 = df[df.accountid .== 1300, :]

account_receivable = sum(df2.debit - df2.credit)
@info("Balance of accounts receivable is $(account_receivable). Should be 1210")

println("Status accounts receivable: € $account_receivable") # should be € 1210.0

# get status of sales
df2 = df[df.accountid .== 8000, :]

sales = sum(df2.credit - df2.debit) # should return € 4000.0
@info("Sales is $(sales). Should be 4000.")

println("Sales: € $sales")


# cleanup
#flush(io)

stm = `rm invoicing.sqlite ledger.txt journal.txt`

run(stm)
