import JavaScriptInterop

@frozen public struct ContextMenu {
    @usableFromInline let items: [ContextMenuItem]

    @inlinable init(items: [ContextMenuItem]) {
        self.items = items
    }
}
extension ContextMenu {
    @inlinable public static func items(
        build: (inout ContextMenuItemEncoder) -> ()
    ) -> Self {
        var encoder: ContextMenuItemEncoder = .init()
        build(&encoder)
        return .init(items: encoder.menu)
    }
}
extension ContextMenu: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString {
        case items
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.items] = self.items
    }
}
