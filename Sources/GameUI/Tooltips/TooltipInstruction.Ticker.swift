extension TooltipInstruction {
    @frozen public struct Ticker {
        @usableFromInline let value: String
        @usableFromInline let delta: String
        @usableFromInline let sign: Sign?

        @inlinable init(value: String, delta: String, sign: Sign?) {
            self.value = value
            self.delta = delta
            self.sign = sign
        }
    }
}
