import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct FactoryTableEntry {
    let id: FactoryID
    let location: String
    let type: String
    let size: Factory.Size
    let liquidationProgress: Double?
    let yesterday: Factory.Dimensions
    let today: Factory.Dimensions
    let workers: FactoryWorkers?
    let clerks: FactoryWorkers?
}
extension FactoryTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case type
        case size_l
        case size_p
        case liqf

        case yesterday_wn = "y_wn"
        case yesterday_cn = "y_cn"
        case yesterday_fi = "y_fi"
        case yesterday_px = "y_px"

        case today_wn = "t_wn"
        case today_cn = "t_cn"
        case today_fi = "t_fi"
        case today_px = "t_px"

        case workers
        case clerks
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.location] = self.location
        js[.type] = self.type
        js[.size_l] = self.size.level
        js[.size_p] = self.size.growthProgress
        js[.liqf] = self.liquidationProgress

        js[.yesterday_wn] = self.yesterday.wn
        js[.yesterday_cn] = self.yesterday.cn
        js[.yesterday_fi] = self.yesterday.fl
        js[.yesterday_px] = self.yesterday.px

        js[.today_wn] = self.today.wn
        js[.today_cn] = self.today.cn
        js[.today_fi] = self.today.fl
        js[.today_px] = self.today.px

        js[.workers] = self.workers
        js[.clerks] = self.clerks
    }
}
