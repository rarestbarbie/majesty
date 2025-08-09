import GameEconomy
import GameRules

extension GameRules {
    subscript(id: Resource) -> ResourceLabel {
        if  let metadata: ResourceMetadata = self.resources[id] {
            return .init(id: id, name: metadata.name, icon: metadata.emoji)
        } else {
            return .init(id: id, name: "\(id)", icon: "?")
        }
    }
}
