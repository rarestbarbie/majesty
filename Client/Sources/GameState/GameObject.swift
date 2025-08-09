import GameEngine
import JavaScriptInterop

protocol GameObject: Identifiable<GameID<Self>>, JavaScriptEncodable {
}
