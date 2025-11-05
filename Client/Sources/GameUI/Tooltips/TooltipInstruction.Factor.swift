extension TooltipInstruction {
    @frozen public struct Factor {
        @usableFromInline let value: String
        @usableFromInline let sign: Sign?

        @inlinable init(value: String, sign: Sign?) {
            self.value = value
            self.sign = sign
        }
    }
}
