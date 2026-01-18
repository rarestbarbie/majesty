import GameEconomy
import JavaScriptInterop

extension ResourceOutput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsTotal = "q"
        case unitsAdded = "r"
        case unitsRemoved = "b"
        case unitsSold = "s"
        case valueSold = "v"
        case valueProduced = "u"
        case valueEstimate = "w"
        case price = "p"
    }
}
extension ResourceOutput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.unitsTotal] = self.units.total
        js[.unitsAdded] = self.units.added
        js[.unitsRemoved] = self.units.removed
        js[.unitsSold] = self.unitsSold
        js[.valueSold] = self.valueSold
        js[.valueProduced] = self.valueProduced
        js[.valueEstimate] = self.valueEstimate == 0 ? nil : self.valueEstimate
        js[.price] = self.price
    }
}
extension ResourceOutput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            units: .init(
                total: try js[.unitsTotal].decode(),
                added: try js[.unitsAdded].decode(),
                removed: try js[.unitsRemoved].decode()
            ),
            unitsSold: try js[.unitsSold].decode(),
            valueSold: try js[.valueSold].decode(),
            valueProduced: try js[.valueProduced].decode(),
            valueEstimate: try js[.valueEstimate]?.decode() ?? 0,
            price: try js[.price]?.decode()
        )
    }
}
