import GameEconomy
import JavaScriptInterop

extension ResourceInput {
    func width(base: Int64, efficiency: Double, reservedDays: Int64) -> Int64 {
        Int64.init(
            Double.init(self.units.total) / (
                Double.init(base * max(1, reservedDays)) * efficiency
            )
        )
    }
}
extension ResourceInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsDemanded = "d"
        case unitsReturned = "r"
        case unitsTotal = "a"
        case unitsAdded = "b"
        case unitsRemoved = "c"

        case valueTotal = "v"
        case valueAdded = "w"
        case valueRemoved = "x"

        case price = "p"
    }
}
extension ResourceInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id

        js[.unitsDemanded] = self.unitsDemanded
        js[.unitsReturned] = self.unitsReturned
        js[.unitsTotal] = self.units.total
        js[.unitsAdded] = self.units.added
        js[.unitsRemoved] = self.units.removed

        js[.valueTotal] = self.value.total
        js[.valueAdded] = self.value.added
        js[.valueRemoved] = self.value.removed

        js[.price] = self.price
    }
}
extension ResourceInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            unitsDemanded: try js[.unitsDemanded].decode(),
            unitsReturned: try js[.unitsReturned].decode(),
            units: .init(
                total: try js[.unitsTotal].decode(),
                added: try js[.unitsAdded].decode(),
                removed: try js[.unitsRemoved].decode()
            ),
            value: .init(
                total: try js[.valueTotal].decode(),
                added: try js[.valueAdded].decode(),
                removed: try js[.valueRemoved].decode()
            ),
            price: try js[.price]?.decode()
        )
    }
}
