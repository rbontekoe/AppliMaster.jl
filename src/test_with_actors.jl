using Pkg; Pkg.activate(".")

using Rocket, AppliSales, AppliAR, AppliGeneralLedger, DataFrames, Query

# remove old stuff
cmd = `rm test_invoicing.txt test_invoicing_paid.txt test_ledger.txt test_journal.txt invoicenbr.txt`
run(cmd)

# create actors
a2 = lambda(
    on_next     = (d) -> begin
        AppliGeneralLedger.process([d])
    end,
    on_error    = (e) -> println(e),
    on_complete = ()  -> println("Completed a2")
)

a1 = lambda(
    on_next     = (d) -> begin
        entries = AppliAR.process([d])
        subscribe!(from(entries), a2)
    end,
    on_error    = (e) -> println(e),
    on_complete = ()  -> println("Completed a1")
)


a3 = lambda(
    on_next     = (d) -> begin
        unpaid_invoices = retrieve_unpaid_invoices()
        entries = AppliAR.process(unpaid_invoices, [d])
        subscribe!(from(entries), a2)
    end,
    on_error    = (e) -> println(e),
    on_complete = ()  -> println("Completed a3")
)

a0 = lambda(
    on_next     = (d) -> begin
        show(d)
        sales = AppliSales.process()
        array_source = from(sales)
        subscribe!(array_source, a1)

        sleep(10)

        try
            rm("./invoicenbr.txt")
            AppliAR.Infrastructure.add_to_file("./invoicenbr.txt", [1000])
        catch e
            AppliAR.Infrastructure.add_to_file("./invoicenbr.txt", [1000])
        end
        stms = AppliAR.read_bank_statements("./bank.csv")
        array_source2 = from(stms)
        s3 = subscribe!(array_source2, a3)
    end,
    on_error    = (e) -> println(e),
    on_complete = ()  -> println("Completed a3")
)

# start application
s0 = subscribe!(from([10]), a0)

using DataFrames

# check data
r2 = AppliGeneralLedger.read_from_file("./test_ledger.txt")
df2 = r2 |> @filter(_.accountid == 1300) |> DataFrame
println("\nAccounts receivable\n===================")
show(df2)

# unpais invoices
r1 = report(path_unpaid="./test_invoicing.txt", path_paid="./test_invoicing_paid.txt")
result = DataFrame(r1)
println("\nUnpaid invoices\n===============")
show(result)

# check general ledger
println("")
include("check_general_ledger.jl")
# end
