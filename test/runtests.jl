# runtests.jl

using Test

using AppliSQLite, AppliSales, AppliGeneralLedger, AppliInvoicing

@testset "Test AppliSales" begin
    orders = AppliSales.process()
    @test length(orders) == 3
    @test length(orders[1].students) == 1
    @test length(orders[2].students) == 2
    @test length(orders[3].students) == 1
    @test orders[1].training.price == 1000
end

@testset " Test AppliInvoicing - unpaid invoices" begin
    db = connect("./invoicing.sqlite")
    orders = AppliSales.process()
    AppliInvoicing.process(db, orders)
    unpaid_invoices = retrieve_unpaid_invoices(db)
    @test length(unpaid_invoices) == 3
    @test unpaid_invoices[1].id == "A1001"
    cmd = `rm invoicing.sqlite`
    run(cmd)
end

@testset "Test AppliInvoicing - paid invoices" begin
    db = connect("./invoicing.sqlite")
    orders = AppliSales.process()
    entries = AppliInvoicing.process(db, orders)
    @test length(entries) == 3
    @test entries[1].from == 1300
    @test entries[1].to == 8000
    @test entries[1].debit == 1000
    @test entries[1].credit == 0
    @test entries[1].vat == 210.0
    cmd = `rm invoicing.sqlite`
    run(cmd)
end

@testset "Test GeneralLedger - accounts receivable, bank, vat, sales" begin
    db_inv = connect("./invoicing.sqlite")
    db_ledger = connect("./ledger.sqlite")

    orders = AppliSales.process()

    journal_entries_unpaid_invoices = AppliInvoicing.process(db_inv, orders)
    AppliGeneralLedger.process(db_ledger, journal_entries_unpaid_invoices)

    unpaid_invoices = AppliInvoicing.retrieve_unpaid_invoices(db_inv)

    stms = AppliInvoicing.read_bank_statements("./bank.csv")

    journal_entries_paid_invoices = AppliInvoicing.process(db_inv, unpaid_invoices, stms)

    AppliGeneralLedger.process(db_ledger, journal_entries_paid_invoices)

    r = retrieve(db_ledger, "LEDGER", "accountid = 1300") # accounts receivable
    @test sum(r.debit - r.credit) == 1210
    r = retrieve(db_ledger, "LEDGER", "accountid = 1150") # bank
    @test sum(r.debit - r.credit) == 3630

    r = retrieve(db_ledger, "LEDGER", "accountid = 4000") # vat
    @test sum(r.credit - r.debit) == 840
    r = retrieve(db_ledger, "LEDGER", "accountid = 8000") # sales
    @test sum(r.credit - r.debit) == 4000

    r = retrieve(db_ledger, "LEDGER")
    @test sum(r.debit - r.credit) == 0.0

    cmd = `rm invoicing.sqlite ledger.sqlite`
    run(cmd)
end