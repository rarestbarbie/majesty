import GameIDs

enum FactoryMetadataError: Error {
    case workers([PopOccupation])
    case clerks([PopOccupation])
}
extension FactoryMetadataError: CustomStringConvertible {
    var description: String {
        switch self {
        case .workers(let types):
            "Factory must have exactly one worker division, found \(types.count): \(types)"
        case .clerks(let types):
            "Factory must have exactly one clerk division, found \(types.count): \(types)"
        }
    }
}
