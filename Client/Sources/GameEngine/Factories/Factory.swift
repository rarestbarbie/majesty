import JavaScriptKit
import JavaScriptInterop
import GameEconomy
import GameRules
import GameState
import OrderedCollections

struct Factory: CashAccountHolder, Identifiable {
    let id: FactoryID
    let on: Address
    var type: FactoryType
    var grow: Int64
    var size: Int64
    var subs: Bool
    var cash: CashAccount

    var nv: [ResourceInput]
    var ni: [ResourceInput]
    var out: [ResourceOutput]
    var yesterday: Dimensions
    var today: Dimensions

    init(
        id: FactoryID,
        on: Address,
        type: FactoryType,
        grow: Int64,
        size: Int64,
        subs: Bool,
        cash: CashAccount,
        nv: [ResourceInput],
        ni: [ResourceInput],
        out: [ResourceOutput],
        yesterday: Dimensions,
        today: Dimensions,
    ) {
        self.id = id
        self.on = on
        self.type = type
        self.grow = grow
        self.size = size
        self.subs = subs
        self.cash = cash
        self.nv = nv
        self.ni = ni
        self.out = out
        self.yesterday = yesterday
        self.today = today
    }
}
extension Factory: Turnable {
    mutating func turn() {
        self.cash.settle()
    }
}
extension Factory {
    enum ObjectKey: JSString, Sendable {
        case id
        case on
        case type
        case grow
        case size
        case subs
        case cash
        case nv
        case ni
        case out

        case yesterday_vi = "y_vi"
        case yesterday_vv = "y_vv"

        case yesterday_wa = "y_wa"
        case yesterday_wf = "y_wf"
        case yesterday_wn = "y_wn"

        case yesterday_ca = "y_ca"
        case yesterday_cf = "y_cf"
        case yesterday_cn = "y_cn"

        case yesterday_ei = "y_ei"
        case yesterday_eo = "y_eo"
        case yesterday_fi = "y_fi"

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
    }
}
extension Factory: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.on] = self.on
        js[.type] = self.type.rawValue
        js[.grow] = self.grow
        js[.size] = self.size
        js[.subs] = self.subs
        js[.cash] = self.cash

        js[.nv] = self.nv
        js[.ni] = self.ni
        js[.out] = self.out

        js[.yesterday_vi] = self.yesterday.vi
        js[.yesterday_vv] = self.yesterday.vv
        js[.yesterday_wa] = self.yesterday.wa
        js[.yesterday_wf] = self.yesterday.wf
        js[.yesterday_wn] = self.yesterday.wn
        js[.yesterday_ca] = self.yesterday.ca
        js[.yesterday_cf] = self.yesterday.cf
        js[.yesterday_cn] = self.yesterday.cn
        js[.yesterday_ei] = self.yesterday.ei
        js[.yesterday_eo] = self.yesterday.eo
        js[.yesterday_fi] = self.yesterday.fi

        js[.today_vi] = self.today.vi
        js[.today_vv] = self.today.vv
        js[.today_wa] = self.today.wa
        js[.today_wf] = self.today.wf
        js[.today_wn] = self.today.wn
        js[.today_ca] = self.today.ca
        js[.today_cf] = self.today.cf
        js[.today_cn] = self.today.cn
        js[.today_ei] = self.today.ei
        js[.today_eo] = self.today.eo
        js[.today_fi] = self.today.fi
    }
}
extension Factory: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = .init(
            vi: try js[.today_vi]?.decode() ?? 0,
            vv: try js[.today_vv]?.decode() ?? 0,
            wa: try js[.today_wa]?.decode() ?? 0,
            wf: try js[.today_wf]?.decode(),
            wn: try js[.today_wn]?.decode() ?? 1,
            ca: try js[.today_ca]?.decode() ?? 0,
            cf: try js[.today_cf]?.decode(),
            cn: try js[.today_cn]?.decode() ?? 1,
            ei: try js[.today_ei]?.decode() ?? 1,
            eo: try js[.today_eo]?.decode() ?? 1,
            fi: try js[.today_fi]?.decode() ?? 0,
        )
        self.init(
            id: try js[.id].decode(),
            on: try js[.on].decode(),
            type: try js[.type].decode(),
            grow: try js[.grow]?.decode() ?? 0,
            size: try js[.size]?.decode() ?? 1,
            subs: try js[.subs]?.decode() ?? false,
            cash: try js[.cash].decode(),
            nv: try js[.nv]?.decode() ?? [],
            ni: try js[.ni]?.decode() ?? [],
            out: try js[.out]?.decode() ?? [],
            yesterday: .init(
                vi: try js[.yesterday_vi]?.decode() ?? today.vi,
                vv: try js[.yesterday_vv]?.decode() ?? today.vv,
                wa: try js[.yesterday_wa]?.decode() ?? today.wa,
                wf: try js[.yesterday_wf]?.decode(),
                wn: try js[.yesterday_wn]?.decode() ?? today.wn,
                ca: try js[.yesterday_ca]?.decode() ?? today.ca,
                cf: try js[.yesterday_cf]?.decode(),
                cn: try js[.yesterday_cn]?.decode() ?? today.cn,
                ei: try js[.yesterday_ei]?.decode() ?? today.ei,
                eo: try js[.yesterday_eo]?.decode() ?? today.eo,
                fi: try js[.yesterday_fi]?.decode() ?? today.fi,
            ),
            today: today,
        )
    }
}

#if TESTABLE
extension Factory: Equatable, Hashable {}
#endif
