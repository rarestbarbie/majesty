protocol TransactingContext: ~Copyable, AllocatingContext {
    mutating func transact(turn: inout Turn)
}
