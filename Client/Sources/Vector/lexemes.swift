postfix operator ||
prefix operator ||
infix operator <> : MultiplicationPrecedence
infix operator >< : MultiplicationPrecedence

@inlinable public postfix func || (self: Vector3) -> _AbsoluteValueExpression<Vector3> {
    .init(operand: self)
}
@inlinable public prefix func || (self: _AbsoluteValueExpression<Vector3>) -> Double {
    (self.operand * self.operand).sum.squareRoot()
}
