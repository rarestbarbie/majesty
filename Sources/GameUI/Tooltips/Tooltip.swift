import JavaScriptInterop

@frozen public struct Tooltip {
    @usableFromInline let content: Content
    @usableFromInline let display: DisplayStyle?
    @usableFromInline let flipped: Bool

    @inlinable init(content: Content, display: DisplayStyle?, flipped: Bool) {
        self.content = content
        self.display = display
        self.flipped = flipped
    }
}
extension Tooltip {
    @inlinable public static func instructions(
        style: DisplayStyle? = nil,
        flipped: Bool = false,
        build: (inout TooltipInstructionEncoder) -> ()
    ) -> Self {
        var encoder: TooltipInstructionEncoder = .init()
        build(&encoder)
        return .init(
            content: .instructions(encoder.instructions),
            display: style,
            flipped: flipped
        )
    }

    @inlinable public static func conditions(_ lists: [ConditionListItem]...) -> Self {
        .init(content: .conditions(lists), display: nil, flipped: false)
    }
}
extension Tooltip: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString {
        case instructions
        case conditions
        case display
        case flipped
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        switch self.content {
        case .instructions(let content):
            js[.instructions] = content

        case .conditions(let content):
            js[.conditions] = content
        }

        js[.display] = self.display
        js[.flipped] = self.flipped
    }
}
