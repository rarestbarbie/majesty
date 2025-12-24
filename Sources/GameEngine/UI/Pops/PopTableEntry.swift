import Color
import GameEconomy
import GameRules
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct PopTableEntry: Identifiable {
    let id: PopID
    let type: PopType
    let color: Color
    let nat: String
    let une: Double
    let yesterday: Pop.Dimensions
    let today: Pop.Dimensions
}
extension PopTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case occupation = "occ"
        case gender
        case cis

        case color
        case nat
        case une

        case yesterday_size = "y_size"
        case yesterday_mil = "y_mil"
        case yesterday_con = "y_con"
        case yesterday_fl = "y_fl"
        case yesterday_fe = "y_fe"
        case yesterday_fx = "y_fx"
        case yesterday_px = "y_px"

        case today_size = "t_size"
        case today_mil = "t_mil"
        case today_con = "t_con"
        case today_fl = "t_fl"
        case today_fe = "t_fe"
        case today_fx = "t_fx"
        case today_px = "t_px"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.occupation] = self.type.occupation
        js[.gender] = self.type.gender.glyphs
        js[.cis] = self.type.gender.transgender ? nil : true

        js[.color] = self.color
        js[.nat] = self.nat
        js[.une] = self.une

        js[.yesterday_size] = self.yesterday.total
        js[.yesterday_mil] = self.yesterday.mil
        js[.yesterday_con] = self.yesterday.con
        js[.yesterday_fl] = self.yesterday.fl
        js[.yesterday_fe] = self.yesterday.fe
        js[.yesterday_fx] = self.yesterday.fx
        js[.yesterday_px] = self.yesterday.px

        js[.today_size] = self.today.total
        js[.today_mil] = self.today.mil
        js[.today_con] = self.today.con
        js[.today_fl] = self.today.fl
        js[.today_fe] = self.today.fe
        js[.today_fx] = self.today.fx
        js[.today_px] = self.today.px
    }
}
