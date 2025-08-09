@frozen public struct Resource: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int16
    @inlinable public init(rawValue: Int16) { self.rawValue = rawValue }
}
// extension Resource {
//     @frozen public enum Good: Int16, Equatable, Hashable, Sendable {
//         // Food
//         case Beef = 0
//         case Poultry = 1
//         case Produce = 2
//         case Wheat = 3

//         // Raw Materials
//         case Bauxite = 100
//         case Graphite = 101
//         case Gold
//         case H2O
//         case Helium
//         case Hemp
//         case Hydrocarbons
//         case Iron
//         case Limestone
//         case Lithium
//         case Nitrogen
//         case Neon
//         case Pearls
//         case Phosphate
//         case Potash
//         case Sulfur
//         case Uranium = 116

//         // Industrial Goods
//         case Alloys = 200
//         case Ammonia
//         case Appliances
//         case Antibiotics
//         case Autocomplete
//         case Batteries
//         case Coolants
//         case Concrete
//         case Deuterium
//         case Drones
//         case Explosives
//         case Fertilizer
//         case Firearms
//         case Hormones
//         case MachineParts
//         case Missiles
//         case Polymers
//         case Renderings
//         case SemiconductorDevices
//         case Spacecraft
//         case Shells
//         case Storage
//         case Syringes

//         // Basic Goods
//         case HealthCare = 300
//         case Electricity
//         case Housing
//         case Water

//         // Drugs
//         case Adderall
//         case Liquor
//         case Cocaine
//         case Vapes

//         // Consumer Goods
//         case Bicycles
//         case Consoles
//         case Contacts
//         case Furniture
//         case Handbags
//         case Instruments
//         case Lingerie
//         case Organs
//         case Prosthetics
//         case Makeup
//         case Smartphones
//         case Sneakers
//         case Vehicles
//     }
// }
extension Resource: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        return a.rawValue < b.rawValue
    }
}
extension Resource: CustomStringConvertible {
    @inlinable public var description: String {
        "[\(self.rawValue)]"
    }
}
// extension Resource {
//     @inlinable public static func * (multiplier: Int64, self: Self) -> Quantity<Resource> {
//         .init(amount: multiplier, unit: self)
//     }
// }

// extension Resource {
//     var symbol: String {
//         switch self {
//         case .Beef:                 "🍖"
//         case .Poultry:              "🍗"
//         case .Produce:              "🥬"
//         case .Wheat:                "🌾"
//         case .Bauxite:              "🪨"
//         case .Graphite:             "✏️"
//         case .Gold:                 "💰"
//         case .Helium:               "🎈"
//         case .Hemp:                 "🌿"
//         case .Hydrocarbons:         "🛢️"
//         case .H2O:                  "🌊"
//         case .Iron:                 "⛏️"
//         case .Nitrogen:             "🌬️"
//         case .Limestone:            "🗻"
//         case .Lithium:              "🪙"
//         case .Neon:                 "🪩"
//         case .Pearls:               "🐚"
//         case .Phosphate:            "🧂"
//         case .Potash:               "🪨"
//         case .Sulfur:               "🧪"
//         case .Uranium:              "☢️"

//         case .Alloys:               "🔩"
//         case .Ammonia:              "💨"
//         case .Appliances:           "🖥️"
//         case .Antibiotics:          "⚗"
//         case .Autocomplete:         "🤖"
//         case .Batteries:            "🔋"
//         case .Coolants:             "🧊"
//         case .Concrete:             "🏗️"
//         case .Deuterium:            "⚛️"
//         case .Drones:               "🚁"
//         case .Explosives:           "💥"
//         case .Fertilizer:           "🌱"
//         case .Firearms:             "🔫"
//         case .Hormones:             "🧬"
//         case .MachineParts:         "⚙️"
//         case .Missiles:             "🚀"
//         case .Polymers:             "🧪"
//         case .Renderings:           "🎨"
//         case .SemiconductorDevices: "💿"
//         case .Spacecraft:           "🛰️"
//         case .Shells:               "💣"
//         case .Storage:              "💾"
//         case .Syringes:             "💉"

//         case .HealthCare:           "⚕️"
//         case .Electricity:          "💡"
//         case .Housing:              "🏠"
//         case .Water:                "💧"

//         case .Adderall:             "💊"
//         case .Liquor:               "🍺"
//         case .Cocaine:              "❄️"
//         case .Vapes:                "💨"

//         case .Bicycles:             "🚲"
//         case .Consoles:             "🎮"
//         case .Contacts:             "👓"
//         case .Furniture:            "🛋️"
//         case .Handbags:             "👜"
//         case .Instruments:          "🎸"
//         case .Lingerie:             "🎀"
//         case .Organs:               "🫀"
//         case .Prosthetics:          "🍒"
//         case .Makeup:               "💄"
//         case .Smartphones:          "📱"
//         case .Sneakers:             "👟"
//         case .Vehicles:             "🛻"
//         }
//     }
// }
