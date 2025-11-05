import ColorText
import D

@frozen public struct TooltipInstructionEncoder: ~Copyable {
    @usableFromInline var buffer: [TooltipInstruction]
    @usableFromInline var indent: UInt

    @inlinable init(buffer: [TooltipInstruction] = [], indent: UInt = 0) {
        self.buffer = buffer
        self.indent = indent
    }
}
extension TooltipInstructionEncoder {
    @inlinable var instructions: [TooltipInstruction] {
        consuming get { self.buffer }
    }
}
extension TooltipInstructionEncoder {
    @inlinable public subscript<T>(indent: (IndentNone) -> (), _ yield: (inout Self) -> T) -> T {
        mutating get {
            self[>0, yield]
        }
    }
    @inlinable public subscript<T>(indent: Indent, _ yield: (inout Self) -> T) -> T {
        mutating get {
            let indent = indent.level + 1
            self.indent += indent ; defer { self.indent -= indent }
            return yield(&self)
        }
    }
}
extension TooltipInstructionEncoder {
    /// Writes the assigned string with no indentation.
    @inlinable public subscript(indent: (IndentNone) -> ()) -> ColorText? {
        get { nil }
        set (lines) { self[>0] = lines }
    }
    /// Writes the assigned string with the specified indentation level.
    @inlinable public subscript(indent: Indent) -> ColorText? {
        get { nil }
        set (lines) {
            if let lines: ColorText {
                self.buffer.append(
                    .header(self.indent + indent.level, lines)
                )
            }
        }
    }

    @inlinable subscript(label: String, fortune: Fortune?) -> TooltipInstruction.Factor? {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Factor else {
                return
            }
            self.buffer.append(
                .factor(.init(fortune: fortune, indent: self.indent, text: label), value)
            )
        }
    }

    @inlinable public subscript<Style, Factor>(
        label: String,
        _: (Style) -> () = { (_: Fortune.None) in },
    ) -> Factor? where Style: FortuneType, Factor: NumericRepresentation {
        get { nil }
        set (value) {
            guard let factor: Factor = value else {
                return
            }
            self[label, Style.fortune] = TooltipInstruction.Factor.init(
                value: "\(factor)",
                sign: factor.sign.map { $0 ? .pos : .neg },
            )
        }
    }

    @inlinable public subscript<Style>(
        label: String,
        _: (Style) -> () = { (_: Fortune.None) in },
    ) -> TooltipInstruction.Ticker? where Style: FortuneType {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Ticker else {
                return
            }
            self.buffer.append(
                .ticker(.init(fortune: Style.fortune, indent: self.indent, text: label), value)
            )
        }
    }

    @inlinable public subscript<Style>(
        label: String,
        _: (Style) -> () = { (_: Fortune.None) in },
    ) -> TooltipInstruction.Count? where Style: FortuneType {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Count else {
                return
            }
            self.buffer.append(
                .count(.init(fortune: Style.fortune, indent: self.indent, text: label), value)
            )
        }
    }
}
