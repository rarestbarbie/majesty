import JavaScriptKit
import JavaScriptInterop

@frozen public struct Tooltip {
    @usableFromInline let content: Content
    @usableFromInline let display: DisplayStyle?

    @inlinable init(content: Content, display: DisplayStyle?) {
        self.content = content
        self.display = display
    }
}
extension Tooltip {
    @inlinable public static func instructions(
        style: DisplayStyle? = nil,
        build: (inout TooltipInstructionEncoder) -> ()
    ) -> Self {
        var encoder: TooltipInstructionEncoder = .init()
        build(&encoder)
        return .init(content: .instructions(encoder.instructions), display: style)
    }

    @inlinable public static func conditions(_ lists: [ConditionListItem]...) -> Self {
        .init(content: .conditions(lists), display: nil)
    }
}
extension Tooltip: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString {
        case instructions
        case conditions
        case display
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        switch self.content {
        case .instructions(let content):
            js[.instructions] = content

        case .conditions(let content):
            js[.conditions] = content
        }

        js[.display] = self.display
    }
}
