import ColorText
import D

@frozen public struct TermListEncoder: ~Copyable {
    @usableFromInline var buffer: [Term]
    @usableFromInline var indent: UInt

    @inlinable init(buffer: [Term] = [], indent: UInt = 0) {
        self.buffer = buffer
        self.indent = indent
    }
}
extension TermListEncoder {
    @inlinable var instructions: [Term] {
        consuming get { self.buffer }
    }
}
extension TermListEncoder {
    @inlinable public subscript<T>(
        indent: (IndentNone) -> (),
        _ yield: (inout Self) -> T
    ) -> T {
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
extension TermListEncoder {
    /// Writes the assigned string with no indentation.
    @inlinable public subscript(
        indent: (IndentNone) -> (),
        label: TermType,
        tooltip tooltip: TooltipType? = nil,
        help help: TooltipType? = nil
    ) -> ColorText? {
        get { nil }
        set (lines) { self[>0, label, tooltip: tooltip, help: help] = lines }
    }
    /// Writes the assigned string with the specified indentation level.
    @inlinable public subscript(
        indent: Indent,
        label: TermType,
        tooltip tooltip: TooltipType? = nil,
        help help: TooltipType? = nil
    ) -> ColorText? {
        get { nil }
        set (lines) {
            if let lines: ColorText {
                self.buffer.append(
                    .init(
                        id: label,
                        details: .header(self.indent + indent.level, lines),
                        tooltip: tooltip,
                        help: help
                    )
                )
            }
        }
    }

    @inlinable subscript(
        label: TermType,
        fortune: Fortune?,
        tooltip: TooltipType?,
        help: TooltipType?
    ) -> TooltipInstruction.Factor? {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Factor else {
                return
            }
            self.buffer.append(
                .init(
                    id: label,
                    details: .factor(
                        .init(fortune: fortune, indent: self.indent, text: ""),
                        value
                    ),
                    tooltip: tooltip,
                    help: help
                )
            )
        }
    }

    @inlinable public subscript<Style, Factor>(
        label: TermType,
        _: (Style) -> () = { (_: Fortune.None) in },
        tooltip tooltip: TooltipType? = nil,
        help help: TooltipType? = nil
    ) -> Factor? where Style: FortuneType, Factor: NumericRepresentation {
        get { nil }
        set (value) {
            guard let factor: Factor = value else {
                return
            }
            self[label, Style.fortune, tooltip, help] = TooltipInstruction.Factor.init(
                value: "\(factor)",
                sign: factor.sign.map { $0 ? .pos : .neg },
            )
        }
    }

    @inlinable public subscript<Style>(
        label: TermType,
        _: (Style) -> () = { (_: Fortune.None) in },
        tooltip tooltip: TooltipType? = nil,
        help help: TooltipType? = nil
    ) -> TooltipInstruction.Ticker? where Style: FortuneType {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Ticker else {
                return
            }
            self.buffer.append(
                .init(
                    id: label,
                    details: .ticker(
                        .init(fortune: Style.fortune, indent: self.indent, text: ""),
                        value
                    ),
                    tooltip: tooltip,
                    help: help
                )
            )
        }
    }

    @inlinable public subscript<Style>(
        label: TermType,
        _: (Style) -> () = { (_: Fortune.None) in },
        tooltip tooltip: TooltipType? = nil,
        help help: TooltipType? = nil
    ) -> TooltipInstruction.Count? where Style: FortuneType {
        get { nil }
        set (value) {
            guard let value: TooltipInstruction.Count else {
                return
            }
            self.buffer.append(
                .init(
                    id: label,
                    details: .count(
                        .init(fortune: Style.fortune, indent: self.indent, text: ""),
                        value
                    ),
                    tooltip: tooltip,
                    help: help
                )
            )
        }
    }
}
