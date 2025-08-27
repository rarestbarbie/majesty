import GameEconomy

public final class FactoryMetadata: Identifiable, Sendable {
    public let name: String
    public let costs: [Quantity<Resource>]
    public let inputs: [Quantity<Resource>]
    public let output: [Quantity<Resource>]
    public let workers: Quantity<PopType>
    public let clerks: Quantity<PopType>?

    init(
        name: String,
        costs: [Quantity<Resource>],
        inputs: [Quantity<Resource>],
        output: [Quantity<Resource>],
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
