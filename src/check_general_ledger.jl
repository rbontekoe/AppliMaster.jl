# check_generail_ledger.jl

using AppliGeneralLedger

using DataFrames

using Query

df = DataFrame(AppliGeneralLedger.read_from_file("ledger.txt"))

df2 = df |> @filter(_.accountid == 1300) |> DataFrame

balance_1300 = sum(df2.debit - df2.credit)

println("Balance accounts receivable is $balance_1300. Should be 1210.0.")

df2 = df |> @filter(_.accountid == 8000) |> DataFrame

balance_8000 = sum(df2.credit - df2.debit)

println("Sales is $balance_8000. Should be 4000.0")

#stm = `rm invoicing.sqlite ledger.sqlite log_master.txt`
stm = `rm invoicing.sqlite ledger.txt journal.txt`

run(stm)
# end
