import Color
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop

struct PopTableEntry {
    let id: PopID
    let location: String
    let type: PopType
    let color: Color
    let nat: String
    let une: Double
    let yesterday: Pop.Dimensions
    let today: Pop.Dimensions
    let jobs: [PopJobDescription]
    let cash: CashAccount
}
extension PopTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case type
        case color
        case nat
        case une

        case yesterday_size = "y_size"
        case yesterday_mil = "y_mil"
        case yesterday_con = "y_con"
        case yesterday_fl = "y_fl"
        case yesterday_fe = "y_fe"
        case yesterday_fx = "y_fx"

        case today_size = "t_size"
        case today_mil = "t_mil"
        case today_con = "t_con"
        case today_fl = "t_fl"
        case today_fe = "t_fe"
        case today_fx = "t_fx"

        case jobs
        case cash
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.location] = self.location
        js[.type] = self.type
        js[.color] = self.color
        js[.nat] = self.nat
        js[.une] = self.une

        js[.yesterday_size] = self.yesterday.size
        js[.yesterday_mil] = self.yesterday.mil
        js[.yesterday_con] = self.yesterday.con
        js[.yesterday_fl] = self.yesterday.fl
        js[.yesterday_fe] = self.yesterday.fe
        js[.yesterday_fx] = self.yesterday.fx

        js[.today_size] = self.today.size
        js[.today_mil] = self.today.mil
        js[.today_con] = self.today.con
        js[.today_fl] = self.today.fl
        js[.today_fe] = self.today.fe
        js[.today_fx] = self.today.fx

        js[.jobs] = self.jobs
        js[.cash] = self.cash
    }
}
