import GameIDs
import JavaScriptInterop

@frozen public enum NavigatorRequest {
    case planetTile(Address)
    case planet(PlanetID)
    case layer(PlanetMapLayer)
}
extension NavigatorRequest: QueryParameterDecodable {
    @frozen public enum QueryKey: JSString, Sendable {
        case planetTile
        case planet
        case layer
    }

    public init(from js: borrowing QueryParameterDecoder<QueryKey>) throws {
        if  let id: Address = try js[.planetTile]?.decode() {
            self = .planetTile(id)
        } else if
            let id: PlanetID = try js[.planet]?.decode() {
            self = .planet(id)
        } else {
            self = .layer(try js[.layer].decode())
        }
    }
}
