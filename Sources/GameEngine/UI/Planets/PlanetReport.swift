import GameIDs
import GameState
import JavaScriptKit
import JavaScriptInterop

public struct PlanetReport {
    private var planet: PlanetDetails?

    init() {
        self.planet = nil
    }
}
extension PlanetReport: PersistentReport {
    mutating func select(request: PlanetReportRequest) {
        if  let subject: PlanetID = request.subject {
            self.planet = .init(id: subject, open: .Grid)
        }
        if  let details: PlanetDetailsTab = request.details {
            self.planet?.open = details
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.planet?.update(in: snapshot.context)
    }
}
extension PlanetReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case planet
    }
}
extension PlanetReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Planet
        js[.planet] = self.planet
    }
}
