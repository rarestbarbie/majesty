@frozen public struct _AbsoluteValueExpression<T> {
    @usableFromInline let operand: T

    @inlinable init(operand: T) {
        self.operand = operand
    }
}
