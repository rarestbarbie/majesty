import ColorText
import JavaScriptInterop
import JavaScriptKit

@frozen public struct ConditionListItem: Equatable, Sendable {
    @usableFromInline let fulfilled: Bool?
    @usableFromInline let highlight: Bool
    @usableFromInline let description: ColorText
    @usableFromInline let indent: Int

    @inlinable public init(
        fulfilled: Bool?,
        highlight: Bool,
        description: ColorText,
        indent: Int = 0
    ) {
        self.fulfilled = fulfilled
        self.highlight = highlight
        self.description = description
        self.indent = indent
    }
}
extension ConditionListItem: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case fulfilled
        case highlight
        case description
        case indent
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.fulfilled] = self.fulfilled // can encode `false`, which is meaningful
        js[.highlight] = self.highlight ? self.highlight : false // elided if false
        js[.description] = self.description
        js[.indent] = self.indent
    }
}
