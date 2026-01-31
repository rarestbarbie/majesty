import Color
import ColorReference
import GameRules

extension GameMetadata {
    func name(_ industry: EconomicLedger.Industry) -> String {
        switch industry {
        case .building(let type): self.buildings[type]?.title ?? "Unknown"
        case .factory(let type): self.factories[type]?.title ?? "Unknown"
        case .artisan(let type): self.resources[type].title
        case .slavery(let type): self.pops.cultures[type]?.name ?? "Unknown"
        }
    }

    func color(_ industry: EconomicLedger.Industry) -> ColorReference {
        let color: Color
        switch industry {
        case .building(let type): color = self.buildings[type]?.color ?? 0xFFFFFF
        case .factory(let type): color = self.factories[type]?.color ?? 0xFFFFFF
        case .artisan(let type): color = self.resources[type].color
        case .slavery(let type): color = self.pops.cultures[type]?.color ?? 0xFFFFFF
        }
        return .color(color)
    }
}
