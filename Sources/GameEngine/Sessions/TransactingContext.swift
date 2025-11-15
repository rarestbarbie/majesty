protocol TransactingContext: AllocatingContext {
    mutating func transact(turn: inout Turn)
}
