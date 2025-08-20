import GameEngine
import JavaScriptInterop

extension GameSession {
    mutating func handle(_ event: PlayerEvent) throws -> GameUI? {
        switch event {
        case .faster:
            self.faster()
        case .slower:
            self.slower()
        case .pause:
            self.pause()
        case .tick:
            return try self.tick()
        }

        return nil
    }

    func tooltip(
        type: TooltipType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Tooltip? {
        switch type {
        case .FactoryAccount:
            self.tooltipFactoryAccount(
                try arguments[0].decode(),
            )
        case .FactorySize:
            self.tooltipFactorySize(
                try arguments[0].decode(),
            )
        case .FactoryDemand:
            self.tooltipFactoryDemand(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .FactoryStockpile:
            self.tooltipFactoryStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .FactoryWorkers:
            self.tooltipFactoryWorkers(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryOwnershipCountry:
            self.tooltipFactoryOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .FactoryOwnershipCulture:
            self.tooltipFactoryOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .PlanetCell:
            self.tooltipPlanetCell(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopAccount:
            self.tooltipPopAccount(
                try arguments[0].decode(),
            )
        case .PopJobs:
            self.tooltipPopJobs(
                try arguments[0].decode(),
            )
        case .PopDemand:
            self.tooltipPopDemand(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .PopStockpile:
            self.tooltipPopStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .PopNeeds:
            self.tooltipPopNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopType:
            self.tooltipPopType(
                try arguments[0].decode(),
            )
        case .TileCulture:
            self.tooltipTileCulture(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .TilePopType:
            self.tooltipTilePopType(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        }
    }
}

/*
Steadfast, Fickle
Impressionistic, Analytical
Thrifty, Generous

Confrontational, Consensual
Wary, Welcoming
Unyielding, Forgiving
Cruel, Impartial, Gentle
*/
