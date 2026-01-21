import JavaScriptInterop

extension ContextMenuAction {
    @frozen @usableFromInline struct Call {
        @usableFromInline let id: ContextMenuAction
        @usableFromInline let arguments: JSObject?

        @inlinable init(id: ContextMenuAction, arguments: JSObject?) {
            self.id = id
            self.arguments = arguments
        }
    }
}
