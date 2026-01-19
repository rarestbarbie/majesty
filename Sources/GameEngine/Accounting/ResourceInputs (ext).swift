import GameEconomy
import GameIDs
import JavaScriptInterop
import OrderedCollections

extension ResourceInputs {
    func snapshot<ID>(into table: inout [ID: InventorySnapshot.Consumed.Value], as id: (Resource) -> ID) {
        for input: ResourceInput in self.segmented {
            table[id(input.id)] = .init(
                input: input,
                tradeable: false,
                tradeableDaysReserve: self.tradeableDaysReserve
            )
        }
        for input: ResourceInput in self.tradeable {
            table[id(input.id)] = .init(
                input: input,
                tradeable: true,
                tradeableDaysReserve: self.tradeableDaysReserve
            )
        }
    }
}
extension ResourceInputs {
    var valueConsumed: Int64 {
        self.all.reduce(0) { $0 + $1.valueConsumed }
    }

    var valueAcquired: Int64 {
        self.all.reduce(0) { $0 + $1.value.total }
    }

    func width(limit: Int64, tier: ResourceTier, efficiency: Double) -> Int64 {
        min(
            zip(self.segmented, tier.segmented.x).reduce(limit) {
                let (input, resource): (ResourceInput, Quantity<Resource>) = $1
                return min(
                    $0,
                    input.width(
                        base: resource.amount,
                        efficiency: efficiency,
                        reservedDays: 1
                    )
                )
            },
            zip(self.tradeable, tier.tradeable.x).reduce(limit) {
                let (input, resource): (ResourceInput, Quantity<Resource>) = $1
                return min(
                    $0,
                    input.width(
                        base: resource.amount,
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
        // this is slower to decode than the combined form, but we don’t have to validate the
        // partition index this way, and also we only serialize on game start and save anyway
        self.init(
            segmented: try js[.segmented].decode(),
            tradeable: try js[.tradeable].decode(),
            tradeableDaysReserve: try js[.tradeableDaysReserve].decode()
        )
    }
}
