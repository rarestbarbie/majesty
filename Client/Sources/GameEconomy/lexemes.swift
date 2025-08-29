infix operator <> : MultiplicationPrecedence
infix operator >< : MultiplicationPrecedence
infix operator *> : MultiplicationPrecedence
infix operator *< : MultiplicationPrecedence
infix operator %/ : MultiplicationPrecedence

@inlinable public func %/ (n: Int64, d: Int64) -> Fraction {
    .init(n, d)
}
