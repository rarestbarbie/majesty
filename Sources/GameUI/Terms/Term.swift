import ColorText
import D

import JavaScriptKit
import JavaScriptInterop

@frozen public struct Term {
    public let id: TermType
    public let details: TooltipInstruction
    public let tooltip: TooltipType?

    @inlinable public init(id: TermType, details: TooltipInstruction, tooltip: TooltipType?) {
        self.id = id
        self.details = details
        self.tooltip = tooltip
    }
}
extension Term {
    @inlinable public static func list(
        build: (inout TermListEncoder) -> ()
    ) -> [Self] {
        var encoder: TermListEncoder = .init()
        build(&encoder)
        return encoder.instructions
    }
}
extension Term: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case details
        case tooltip
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.details] = self.details
        js[.tooltip] = self.tooltip
    }
}
