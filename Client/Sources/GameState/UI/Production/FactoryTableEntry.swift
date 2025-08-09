import GameEconomy
import GameEngine
import JavaScriptKit
import JavaScriptInterop

struct FactoryTableEntry {
    let id: GameID<Factory>
    let location: String
    let type: String
    let grow: Int64
    let size: Int64
    let cash: CashAccount

    let yesterday: Factory.Dimensions
    let today: Factory.Dimensions
    let workers: FactoryWorkers
    let clerks: FactoryWorkers
}
extension FactoryTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case type
        case grow
        case size
        case cash

        case yesterday_vi = "y_vi"
        case yesterday_vv = "y_vv"
        case yesterday_wn = "y_wn"
        case yesterday_wu = "y_wu"
        case yesterday_cn = "y_cn"
        case yesterday_cu = "y_cu"
        case yesterday_ei = "y_ei"
        case yesterday_eo = "y_eo"
        case yesterday_fi = "y_fi"

        case today_vi = "t_vi"
        case today_vv = "t_vv"
        case today_wn = "t_wn"
        case today_wu = "t_wu"
        case today_cn = "t_cn"
        case today_cu = "t_cu"
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
        js[.cash] = self.cash

        js[.yesterday_vi] = self.yesterday.vi
        js[.yesterday_vv] = self.yesterday.vv
        js[.yesterday_wn] = self.yesterday.wn
        js[.yesterday_wu] = self.yesterday.wu
        js[.yesterday_cn] = self.yesterday.cn
        js[.yesterday_cu] = self.yesterday.cu
        js[.yesterday_ei] = self.yesterday.ei
        js[.yesterday_eo] = self.yesterday.eo
        js[.yesterday_fi] = self.yesterday.fi

        js[.today_vi] = self.today.vi
        js[.today_vv] = self.today.vv
        js[.today_wn] = self.today.wn
        js[.today_wu] = self.today.wu
        js[.today_cn] = self.today.cn
        js[.today_cu] = self.today.cu
        js[.today_ei] = self.today.ei
        js[.today_eo] = self.today.eo
        js[.today_fi] = self.today.fi

        js[.workers] = self.workers
        js[.clerks] = self.clerks
    }
}
