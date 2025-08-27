import GameEconomy
import GameState
import JavaScriptKit
import JavaScriptInterop

struct FactoryTableEntry {
    let id: FactoryID
    let location: String
    let type: String
    let grow: Int64
    let size: Int64
    let valuation: Int64
    let yesterday: Factory.Dimensions
    let today: Factory.Dimensions
    let workers: FactoryWorkers
    let clerks: FactoryWorkers?
}
extension FactoryTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case type
        case grow
        case size
        case valuation

        case yesterday_wn = "y_wn"
        case yesterday_cn = "y_cn"
        case yesterday_ei = "y_ei"
        case yesterday_eo = "y_eo"
        case yesterday_fi = "y_fi"

        case today_wn = "t_wn"
        case today_cn = "t_cn"
        case today_ei = "t_ei"
        case today_eo = "t_eo"
        case today_fi = "t_fi"

        case workers
        case clerks
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.location] = self.location
        js[.type] = self.type
        js[.grow] = self.grow
        js[.size] = self.size
        js[.valuation] = self.valuation

        js[.yesterday_wn] = self.yesterday.wn
        js[.yesterday_cn] = self.yesterday.cn
        js[.yesterday_ei] = self.yesterday.ei
        js[.yesterday_eo] = self.yesterday.eo
        js[.yesterday_fi] = self.yesterday.fi

        js[.today_wn] = self.today.wn
        js[.today_cn] = self.today.cn
        js[.today_ei] = self.today.ei
        js[.today_eo] = self.today.eo
        js[.today_fi] = self.today.fi

        js[.workers] = self.workers
        js[.clerks] = self.clerks
    }
}
