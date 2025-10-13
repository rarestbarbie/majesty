public struct ContextMenuItemEncoder: ~Copyable {
    private var items: [ContextMenuItem]

    init() {
        self.items = []
    }
}
extension ContextMenuItemEncoder {
    subscript(label: String, action: (inout ContextMenuActionEncoder) -> ()) -> () {
        mutating get {
            var encoder: ContextMenuActionEncoder = .init()
            action(&encoder)
            let item: ContextMenuItem = .init(
                label: label,
                enabled: encoder.registration,
                submenu: []
            )
            self.items.append(item)
        }
    }
    subscript(submenu label: String, action: (inout Self) -> ()) -> () {
        mutating get {
            var encoder: Self = .init()
            action(&encoder)
            let item: ContextMenuItem = .init(
                label: label,
                enabled: nil,
                submenu: encoder.items
            )
            self.items.append(item)
        }
    }

    var menu: [ContextMenuItem] {
        consuming get { self.items }
    }
}
