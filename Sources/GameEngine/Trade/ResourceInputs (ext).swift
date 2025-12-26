import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension ResourceInputs {
    func snapshot<ID>(into table: inout [ID: InventorySnapshot.Consumed.Value], as id: (Resource) -> ID) {
        for (resource, input): (Resource, ResourceInput) in self.segmented {
            table[id(resource)] = .init(
                input: input,
                tradeable: false,
                tradeableDaysReserve: self.tradeableDaysReserve
            )
        }
        for (resource, input): (Resource, ResourceInput) in self.tradeable {
            table[id(resource)] = .init(
                input: input,
                tradeable: true,
                tradeableDaysReserve: self.tradeableDaysReserve
            )
        }
    }
}
extension ResourceInputs {
    var valueConsumed: Int64 {
        self.segmented.values.reduce(0) { $0 + $1.valueConsumed } +
        self.tradeable.values.reduce(0) { $0 + $1.valueConsumed }
    }

    var valueAcquired: Int64 {
        self.segmented.values.reduce(0) { $0 + $1.value.total } +
        self.tradeable.values.reduce(0) { $0 + $1.value.total }
    }

    func width(limit: Int64, tier: ResourceTier, efficiency: Double) -> Int64 {
        min(
            zip(self.segmented.values, tier.segmented).reduce(limit) {
                let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
                return min(
                    $0,
                    resource.width(
                        base: amount,
                        efficiency: efficiency,
                        reservedDays: 1
                    )
                )
            },
            zip(self.tradeable.values, tier.tradeable).reduce(limit) {
                let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
                return min(
                    $0,
                    resource.width(
                        base: amount,
                        efficiency: efficiency,
                        reservedDays: self.tradeableDaysReserve
                    )
                )
            }
        )
    }
}
extension ResourceInputs {
    @frozen public enum ObjectKey: JSString, Sendable {
        case segmented = "s"
        case tradeable = "t"
        case tradeableDaysReserve = "d"
    }
}
extension ResourceInputs: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.segmented] = self.segmented
        js[.tradeable] = self.tradeable
        js[.tradeableDaysReserve] = self.tradeableDaysReserve
    }
}
extension ResourceInputs: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            segmented: try js[.segmented].decode(),
            tradeable: try js[.tradeable].decode(),
            tradeableDaysReserve: try js[.tradeableDaysReserve].decode()
        )
    }
}
