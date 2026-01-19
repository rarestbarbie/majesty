import JavaScriptInterop

@frozen public struct ContextMenuActionEncoder: ~Copyable {
    @usableFromInline var call: ContextMenuAction.Call?

    @inlinable init() {
        self.call = nil
    }
}
extension ContextMenuActionEncoder {
    @inlinable public subscript(_ action: ContextMenuAction) -> () {
        mutating get {
            self.call = .init(id: action, arguments: nil)
        }
    }

    @inlinable public subscript<each Argument>(
        _ action: ContextMenuAction
    ) -> (repeat each Argument)? where repeat each Argument: ConvertibleToJSValue {
        get { nil }
        set(argument) {
            guard let argument: (repeat each Argument) else {
                return
            }

            self.call = .init(id: action, arguments: .new(array: repeat each argument))
        }
    }

    @inlinable var registration: ContextMenuAction.Call? {
        consuming get { self.call }
    }
}
