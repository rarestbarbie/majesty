import JavaScriptKit
import JavaScriptInterop

extension ContextMenuAction {
    @frozen @usableFromInline struct Call {
        let id: ContextMenuAction
        let arguments: JSObject?
    }
}
