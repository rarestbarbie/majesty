import GameIDs
import JavaScriptInterop

@frozen public struct GameSaveSymbols: Sendable {
    /// Pop types are not moddable.
    public let occupations: SymbolTable<PopOccupation>
    public let stratum: SymbolTable<PopStratum>
    public let genders: SymbolTable<Gender>

    public internal(set) var mines: SymbolTable<MineType>
    public internal(set) var buildings: SymbolTable<BuildingType>
    public internal(set) var factories: SymbolTable<FactoryType>
    public internal(set) var resources: SymbolTable<Resource>
    public internal(set) var technologies: SymbolTable<Technology>

    @usableFromInline var biology: SymbolTable<CultureType>
    @usableFromInline var ecology: SymbolTable<EcologicalType>
    @usableFromInline var geology: SymbolTable<GeologicalType>
}
extension GameSaveSymbols {
    @inlinable public subscript(biology symbol: Symbol) -> CultureType {
        get throws { try self.biology[symbol] }
    }
    @inlinable public subscript(ecology symbol: Symbol) -> EcologicalType {
        get throws { try self.ecology[symbol] }
    }
    @inlinable public subscript(geology symbol: Symbol) -> GeologicalType {
        get throws { try self.geology[symbol] }
    }
}
extension GameSaveSymbols {
    subscript(
        clause: PopAttributesDescription.Predicate.Clause
    ) -> GameMetadata.Pops.SocialPredicate? {
        get throws {
            switch clause {
            case .occupation(in: let names):
                return .occupation(
                    in: try names.reduce(into: []) { $0.insert(try self.occupations[$1]) }
                )
            case .stratum(in: let names):
                return .stratum(
                    in: try names.reduce(into: []) { $0.insert(try self.stratum[$1]) }
                )
            case .biology:
                return nil
            case .sex(in: let sexes):
                return .sex(in: Set<Sex>.init(sexes))
            case .heterosexual(let value):
                return .heterosexual(value)
            case .transgender(let value):
                return .transgender(value)
            }
        }
    }
}
extension GameSaveSymbols: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<GameMetadata.Namespace>) {
        js[.mines] = self.mines
        js[.buildings] = self.buildings
        js[.factories] = self.factories
        js[.resources] = self.resources
        js[.technologies] = self.technologies
        js[.biology] = self.biology
        js[.ecology] = self.ecology
        js[.geology] = self.geology
    }
}
extension GameSaveSymbols: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameMetadata.Namespace>) throws {
        self.init(
            occupations: .cases(by: \.singular),
            stratum: .cases(by: \.description),
            genders: .cases(by: \.code),
            mines: try js[.mines]?.decode() ?? [:],
            buildings: try js[.buildings]?.decode() ?? [:],
            factories: try js[.factories]?.decode() ?? [:],
            resources: try js[.resources]?.decode() ?? [:],
            technologies: try js[.technologies]?.decode() ?? [:],
            biology: try js[.biology]?.decode() ?? [:],
            ecology: try js[.ecology]?.decode() ?? [:],
            geology: try js[.geology]?.decode() ?? [:],
        )
    }
}
