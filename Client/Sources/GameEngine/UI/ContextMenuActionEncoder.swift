import JavaScriptKit
import JavaScriptInterop

struct ContextMenuActionEncoder: ~Copyable {
    private var call: ContextMenuAction.Call?

    init() {
        self.call = nil
    }
}
extension ContextMenuActionEncoder {
    subscript(_ action: ContextMenuAction) -> () {
        mutating get {
            self.call = .init(id: action, arguments: nil)
        }
    }

    subscript<each Argument>(
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

    var registration: ContextMenuAction.Call? {
        consuming get { self.call }
    }
}
