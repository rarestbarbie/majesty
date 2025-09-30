import JavaScriptKit
import JavaScriptInterop

@frozen @usableFromInline struct ContextMenuItem {
    let label: String
    let enabled: ContextMenuAction.Call?
    let submenu: [Self]
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
