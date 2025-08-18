/*
import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public enum FactoryType: String, LoadableFromJSString, ConvertibleToJSString {
    case NuclearPowerPlant

    case UraniumEnrichmentFacility

    // case AlloyFoundry
    // case ConcretePlant
    // case BatteryPlant
    // case MachineFactory
    // case PolypropylenePlant
    // case SemiconductorFoundry

    // case AmmoniaPlant
    // case ChemicalSynthesisPlant
    // case ExplosivesFactory
    // case FermentationPlant
    // case FertilizerPlant

    // case VapeFactory

    // case DataCenter
}
extension FactoryType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .UraniumEnrichmentFacility:    "Uranium Enrichment Facility"
        case .NuclearPowerPlant:            "Nuclear Power Plant"
        }
    }
}
extension FactoryType: LosslessStringConvertible {
    public init?(_ string: String) {
        switch string {
        case "Nuclear Power Plant":         self = .NuclearPowerPlant
        case "Uranium Enrichment Facility": self = .UraniumEnrichmentFacility
        default:                            return nil
        }
    }
}
extension FactoryType {
    var output: Resource {
        switch self {
        case .UraniumEnrichmentFacility:    .Uranium
        case .NuclearPowerPlant:            .Electricity
        // case .AlloyFoundry:             .Alloys
        // case .ConcretePlant:            .Concrete
        // case .BatteryPlant:             .Batteries
        // case .MachineFactory:           .MachineParts
        // case .PolypropylenePlant:       .Polymers
        // case .SemiconductorFoundry:     .SemiconductorDevices

        // case .AmmoniaPlant:             .Ammonia
        // case .ChemicalSynthesisPlant:   .Hormones
        // case .ExplosivesFactory:        .Explosives
        // case .FermentationPlant:        .Antibiotics
        // case .FertilizerPlant:          .Fertilizer

        // case .VapeFactory:              .Vapes

        // case .DataCenter:               .Storage
        }
    }

    var inputs: [Quantity<Resource>] {
        switch self {
        case .UraniumEnrichmentFacility: [
                1 * .Electricity,
            ]

        case .NuclearPowerPlant: [
                1 * .Uranium,
                // 2 * .H2O,
            ]
        // case .AlloyFoundry: [
        //         2 * .Graphite,
        //         2 * .Bauxite,
        //         2 * .Iron,
        //         2 * .Sulfur,
        //     ]

        // case .ConcretePlant: [
        //         4 * .Limestone,
        //         4 * .H2O,
        //     ]

        // case .BatteryPlant: [
        //         3 * .Lithium,
        //         1 * .H2O,
        //         1 * .Polymers,
        //         3 * .Graphite,
        //     ]

        // case .MachineFactory: [
        //         1 * .Hydrocarbons,
        //         5 * .Alloys,
        //         1 * .Sulfur,
        //         1 * .H2O,
        //     ]

        // case .PolypropylenePlant: [
        //         4 * .Hydrocarbons,
        //         4 * .H2O,
        //     ]

        // case .SemiconductorFoundry: [
        //         1 * .Batteries,
        //         1 * .Graphite,
        //         1 * .Gold,
        //         1 * .Neon,
        //         1 * .Helium,
        //         1 * .Coolants,
        //         1 * .Water,
        //     ]

        // case .AmmoniaPlant: [
        //         4 * .Hydrocarbons,
        //         4 * .Nitrogen,
        //     ]

        // case .ChemicalSynthesisPlant: [
        //         2 * .Hydrocarbons,
        //         1 * .Graphite,
        //         1 * .Ammonia,
        //         2 * .Water,
        //     ]

        // case .ExplosivesFactory: [
        //         4 * .Ammonia,
        //         3 * .Polymers,
        //         1 * .SemiconductorDevices,
        //     ]

        // case .FertilizerPlant: [
        //         2 * .Ammonia,
        //         2 * .Potash,
        //         2 * .Phosphate,
        //         2 * .Sulfur,
        //     ]

        // case .FermentationPlant: [
        //         2 * .Water,
        //         2 * .Hydrocarbons,
        //         1 * .Hormones,
        //         3 * .Fertilizer,
        //     ]


        // case .VapeFactory: [
        //         4 * .Batteries,
        //         1 * .SemiconductorDevices,
        //         1 * .Ammonia,
        //         1 * .Hydrocarbons,
        //         1 * .Potash,
        //     ]

        // case .DataCenter: [
        //         2 * .Appliances,
        //         2 * .Storage,
        //         4 * .Electricity,
        //     ]
        }
    }
}
extension FactoryType  {
    // var factoryName: String {
    //     switch self {
    //     case .appliances: "Appliance Factory"
    //     case .autocomplete: "Data Center"
    //     case .batteries: "Battery Factory"
    //     case .coolants: "Coolant Factory"
    //     case .concrete: "Concrete Refinery"
    //     case .explosives: "Explosives Factory"
    //     case .deuterium: "Deuterium Refinery"
    //     case .drones: "Drone Factory"
    //     case .fertilizer: "Fertilizer Plant"
    //     case .firearms: "Gun Factory"
    //     case .hormones: "Hormone Factory"
    //     case .machineParts: "Machine Parts Factory"
    //     case .microchips: "Microchip Factory"
    //     case .missiles: "Missile Factory"
    //     case .spacecraft: "Spacecraft Factory"
    //     case .shells: "Munitions Plant"
    //     case .storage: "Cloud"
    //     case .syringes: "Syringe Factory"

    //     case .care: "Clinic"
    //     case .electricity: "Power Plant"
    //     case .housing: "Condominium"
    //     case .water: "Desalination Plant"

    //     case .adderall: "Adderall Factory"
    //     case .beer: "Brewery"
    //     case .coke: "Cocaine Refinery"
    //     case .vapes: "Vape Factory"

    //     case .bikes: "Bike Factory"
    //     case .consoles: "Console Factory"
    //     case .contacts: "Contact Lens Factory"
    //     case .furniture: "Furniture Factory"
    //     case .handbags: "Handbag Factory"
    //     case .instruments: "Instrument Factory"
    //     case .lingerie: "Lingerie Factory"
    //     case .prosthetics: "Prosthetics Factory"
    //     case .makeup: "Makeup Factory"
    //     case .phones: "Phone Factory"
    //     case .sneakers: "Sneaker Factory"
    //     case .trucks: "Truck Factory"
    //     }
    // }
}
*/
