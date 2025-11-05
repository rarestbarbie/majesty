import JavaScriptKit
import JavaScriptInterop

@frozen @usableFromInline struct ContextMenuItem {
    @usableFromInline let label: String
    @usableFromInline let enabled: ContextMenuAction.Call?
    @usableFromInline let submenu: [Self]

    @inlinable init(
        label: String,
        enabled: ContextMenuAction.Call?,
        submenu: [Self]
    ) {
        self.label = label
        self.enabled = enabled
        self.submenu = submenu
    }
}
extension ContextMenuItem: JavaScriptEncodable {
    @frozen @usableFromInline enum ObjectKey: JSString {
        case label
        case action
        case arguments
        case submenu
    }

    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.label] = self.label
        js[.action] = self.enabled?.id
        js[.arguments] = self.enabled?.arguments
        js[.submenu] = self.submenu.isEmpty ? nil : self.submenu
    }
}
