extension TooltipInstruction {
    @frozen public struct Count {
        @usableFromInline let value: String
        @usableFromInline let limit: String
        @usableFromInline let sign: Sign?

        @inlinable init(value: String, limit: String, sign: Sign?) {
            self.value = value
            self.limit = limit
            self.sign = sign
        }
    }
}
