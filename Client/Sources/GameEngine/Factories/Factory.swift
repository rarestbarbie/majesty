import JavaScriptKit
import JavaScriptInterop
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import OrderedCollections
import Random

struct Factory: LegalEntityState, Identifiable {
    let id: FactoryID
    let tile: Address
    var type: FactoryType
    var size: Size

    var liquidation: FactoryLiquidation?

    var inventory: Inventory
    var yesterday: Dimensions
    var today: Dimensions

    var equity: Equity<LEI>
}
extension Factory: Sectionable {
    init(id: FactoryID, section: Section) {
        self.init(
            id: id,
            tile: section.tile,
            type: section.type,
            size: .init(level: 0),
            liquidation: nil,
            inventory: .init(),
            yesterday: .init(),
            today: .init(),
            equity: [:],
        )
    }

    var section: Section {
        .init(type: self.type, tile: self.tile)
    }
}
extension Factory: Deletable {
    var dead: Bool {
        if  case _? = self.liquidation,
            self.inventory.account.balance == 0,
            self.equity.shares.values.allSatisfy({ $0.shares <= 0 }) {
            true
        } else {
            false
        }
    }
}
extension Factory {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
    }
}
extension Factory: Turnable {
    mutating func turn() {
        self.inventory.account.settle()
        self.equity.turn()
    }
}
extension Factory {
    enum ObjectKey: JSString, Sendable {
        case id
        case tile = "on"
        case type
        case size_l
        case size_p
        case liquidation

        case inventory_account = "cash"
        case inventory_out = "out"
        case inventory_l = "nl"
        case inventory_e = "ne"
        case inventory_x = "nx"

        case yesterday_vi = "y_vi"
        case yesterday_vv = "y_vv"

        case yesterday_wf = "y_wf"
        case yesterday_wn = "y_wn"

        case yesterday_cf = "y_cf"
        case yesterday_cn = "y_cn"

        case yesterday_ei = "y_ei"
        case yesterday_eo = "y_eo"
        case yesterday_fi = "y_fi"

        case yesterday_px = "y_px"
        case yesterday_pa = "y_pa"

        case today_vi = "t_vi"
        case today_vv = "t_vv"

        case today_wa = "t_wa"
        case today_wf = "t_wf"
        case today_wn = "t_wn"

        case today_ca = "t_ca"
        case today_cf = "t_cf"
        case today_cn = "t_cn"

        case today_ei = "t_ei"
        case today_eo = "t_eo"
        case today_fi = "t_fi"

        case today_px = "t_px"
        case today_pa = "t_pa"

        case equity
    }
}
extension Factory: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type.rawValue
        js[.size_l] = self.size.level
        js[.size_p] = self.size.growthProgress
        js[.liquidation] = self.liquidation

        js[.inventory_account] = self.inventory.account
        js[.inventory_l] = self.inventory.l
        js[.inventory_e] = self.inventory.e
        js[.inventory_x] = self.inventory.x
        js[.inventory_out] = self.inventory.out

        js[.yesterday_vi] = self.yesterday.vi
        js[.yesterday_vv] = self.yesterday.vx
        js[.yesterday_wf] = self.yesterday.wf
        js[.yesterday_wn] = self.yesterday.wn
        js[.yesterday_cf] = self.yesterday.cf
        js[.yesterday_cn] = self.yesterday.cn
        js[.yesterday_ei] = self.yesterday.ei
        js[.yesterday_eo] = self.yesterday.eo
        js[.yesterday_fi] = self.yesterday.fi
        js[.yesterday_px] = self.yesterday.px
        js[.yesterday_pa] = self.yesterday.pa

        js[.today_vi] = self.today.vi
        js[.today_vv] = self.today.vx
        js[.today_wf] = self.today.wf
        js[.today_wn] = self.today.wn
        js[.today_cf] = self.today.cf
        js[.today_cn] = self.today.cn
        js[.today_ei] = self.today.ei
        js[.today_eo] = self.today.eo
        js[.today_fi] = self.today.fi
        js[.today_px] = self.today.px
        js[.today_pa] = self.today.pa

        js[.equity] = self.equity
    }
}
extension Factory: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = .init(
            vi: try js[.today_vi]?.decode() ?? 0,
            vx: try js[.today_vv]?.decode() ?? 0,
            wf: try js[.today_wf]?.decode(),
            wn: try js[.today_wn]?.decode() ?? 1,
            cf: try js[.today_cf]?.decode(),
            cn: try js[.today_cn]?.decode() ?? 1,
            ei: try js[.today_ei]?.decode() ?? 1,
            eo: try js[.today_eo]?.decode() ?? 1,
            fi: try js[.today_fi]?.decode() ?? 0,
            px: try js[.today_px]?.decode() ?? 0,
            pa: try js[.today_pa]?.decode() ?? 1,
        )
        self.init(
            id: try js[.id].decode(),
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            size: .init(
                level: try js[.size_l]?.decode() ?? 1,
                growthProgress: try js[.size_p]?.decode() ?? 0
            ),
            liquidation: try js[.liquidation]?.decode(),
            inventory: .init(
                account: try js[.inventory_account]?.decode() ?? .init(),
                out: try js[.inventory_out]?.decode() ?? .init(),
                l: try js[.inventory_l]?.decode() ?? .init(),
                e: try js[.inventory_e]?.decode() ?? .init(),
                x: try js[.inventory_x]?.decode() ?? .init()
            ),
            yesterday: .init(
                vi: try js[.yesterday_vi]?.decode() ?? today.vi,
                vx: try js[.yesterday_vv]?.decode() ?? today.vx,
                wf: try js[.yesterday_wf]?.decode(),
                wn: try js[.yesterday_wn]?.decode() ?? today.wn,
                cf: try js[.yesterday_cf]?.decode(),
                cn: try js[.yesterday_cn]?.decode() ?? today.cn,
                ei: try js[.yesterday_ei]?.decode() ?? today.ei,
                eo: try js[.yesterday_eo]?.decode() ?? today.eo,
                fi: try js[.yesterday_fi]?.decode() ?? today.fi,
                px: try js[.yesterday_px]?.decode() ?? today.px,
                pa: try js[.yesterday_pa]?.decode() ?? today.pa
            ),
            today: today,
            equity: try js[.equity]?.decode() ?? [:]
        )
    }
}

#if TESTABLE
extension Factory: Equatable, Hashable {}
#endif
