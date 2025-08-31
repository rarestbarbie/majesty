import GameEconomy

public final class FactoryMetadata: Identifiable, Sendable {
    public let name: String
    public let costs: ResourceTier
    public let inputs: ResourceTier
    public let output: ResourceTier
    public let workers: Quantity<PopType>
    public let clerks: Quantity<PopType>?

    init(
        name: String,
        costs: ResourceTier,
        inputs: ResourceTier,
        output: ResourceTier,
        workers divisions: [Quantity<PopType>],
    ) throws {
        self.name = name
        self.costs = costs
        self.inputs = inputs
        self.output = output

        let workers: [Quantity<PopType>] = divisions.filter { $0.unit.stratum <= .Worker }
        let clerks: [Quantity<PopType>] = divisions.filter { $0.unit.stratum > .Worker }

        guard workers.count == 1 else {
            throw FactoryMetadataError.workers(workers.map { $0.unit })
        }
        guard clerks.count <= 1 else {
            throw FactoryMetadataError.clerks(clerks.map { $0.unit })
        }

        self.workers = workers[0]
        self.clerks = clerks.first
    }
}
extension FactoryMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.costs.hash(into: &hasher)
        self.inputs.hash(into: &hasher)
        self.output.hash(into: &hasher)

        self.workers.hash(into: &hasher)
        self.clerks.hash(into: &hasher)

        return hasher.finalize()
    }
}
