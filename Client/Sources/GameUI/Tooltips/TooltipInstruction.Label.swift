extension TooltipInstruction {
    @frozen public struct Label {
        @usableFromInline let fortune: Fortune?
        @usableFromInline let indent: UInt
        @usableFromInline let text: String

        @inlinable init(fortune: Fortune?, indent: UInt, text: String) {
            self.fortune = fortune
            self.indent = indent
            self.text = text
        }
    }
}
