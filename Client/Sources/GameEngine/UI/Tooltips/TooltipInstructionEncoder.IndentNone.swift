extension TooltipInstructionEncoder {
    /// This type is a syntactical construct that allows writing `>0` without the `0`.
    enum IndentNone {
        static prefix func > (value: Self) -> () {
        }
    }
}
