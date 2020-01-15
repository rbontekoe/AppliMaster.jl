# runtests.jl

using Test

using AppliSales, AppliInvoicing, AppliGeneralLedger, AppliSQLite

@testset "Test AppliSales" begin
    orders = AppliSales.process()
    @test length(orders) == 3
    @test length(orders[1].students) == 1
    @test length(orders[2].students) == 2
    @test length(orders[3].students) == 1
    @test orders[1].training.price == 1000
end

@testset " Test AppliInvoicing - unpaid invoices" begin
    orders = AppliSales.process()
    unpaid_invoices = AppliInvoicing.process(orders)
    @test length(unpaid_invoices) == 3
    @test unpaid_invoices[1].from == 1300
    @test unpaid_invoices[1].to == 8000
    @test unpaid_invoices[1].vat == 210
    cmd = `rm invoicing.sqlite`
    run(cmd)
end

@testset " Test AppliInvoicing - paid invoices" begin
    orders = AppliSales.process()
    unpaid_invoices = AppliInvoicing.process(orders)
    paid_invoices = AppliInvoicing.process()
    @test length(paid_invoices) == 2
    @test paid_invoices[1].from == 1150
    @test paid_invoices[1].to == 1300
    @test paid_invoices[1].invoice_nbr == "Invoice A1002"
    @test paid_invoices[1].debit == 2420
    @test paid_invoices[1].credit == 0
    cmd = `rm invoicing.sqlite`
    run(cmd)
end

@testset "Test GeneralLedger - accounts receivable" begin
    orders = AppliSales.process()
    unpaid_invoices = AppliInvoicing.process(orders)
    AppliGeneralLedger.process(unpaid_invoices)
    paid_invoices = AppliInvoicing.process()
    AppliGeneralLedger.process(paid_invoices)

    db = connect("./ledger.sqlite")

    r = retrieve(db, "LEDGER", "accountid = 1300")
    @test sum(r.debit - r.credit) == 1210
    r = retrieve(db, "LEDGER", "accountid = 1150")
    @test sum(r.debit - r.credit) == 3630
    r = retrieve(db, "LEDGER", "accountid = 4000")
    @test sum(r.credit - r.debit) == 840
    r = retrieve(db, "LEDGER", "accountid = 8000")
    @test sum(r.credit - r.debit) == 4000

    cmd = `rm invoicing.sqlite ledger.sqlite`
    run(cmd)
end
