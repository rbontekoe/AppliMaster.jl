# domain.jl

# Trait definition dispatcher
abstract type Dispatcher end
struct T0 <: Dispatcher end
struct T1 <: Dispatcher end
struct T2 <: Dispatcher end
struct T3 <: Dispatcher end

Dispatcher(::Type{<: String}) = T0()
Dispatcher(::Type{<: Array{AppliSales.Order, 1}}) = T1()
Dispatcher(::Type{<: Array{AppliGeneralLedger.JournalEntry,1}}) = T2()
Dispatcher(::Type{<: Array{AppliAR.BankStatement,1}}) = T3()

# dispatch(x::T) where {T} = dispatch(Dispatcher(T), x)
# end Trait defenition
