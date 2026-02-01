import GameIDs
import GameEconomy
import OrderedCollections

extension GameMetadata {
    @frozen public struct Pops {
        @usableFromInline var metadata: [PopType: PopMetadata]
        @usableFromInline var factors: MetadataFactors
    }
}
extension GameMetadata.Pops {
    init(
        resources: OrderedDictionary<Resource, ResourceMetadata>,
        symbols: GameSaveSymbols,
        layers: [PopAttributesDescription]
    ) throws {
        var attributesDefault: PopAttributes? = nil
        var attributesSocial: [SocialSection: PopAttributes] = [:]
        var attributesByRace: [CultureType: PopAttributes] = [:]

        let matrix: [SocialSection] = SocialSection.matrix
        for layers: PopAttributesDescription in layers {
            let attributes: PopAttributes = try .init(
                metadata: resources,
                decoding: layers,
                symbols: symbols.resources
            )

            if  case .biology(in: let names) = layers.where?.clauses.first,
                case 1? = layers.where?.clauses.count {
                for name: Symbol in names {
                    attributesByRace[try symbols.biology[name], default: .empty] |= attributes
                }

                continue
            }

            guard let predicate: PopAttributesDescription.Predicate = layers.where else {
                if  case nil = attributesDefault {
                    attributesDefault = attributes
                    continue
                } else {
                    fatalError("Multiple default pop attributes layers defined")
                }
            }

            let clauses: [SocialPredicate] = try predicate.clauses.reduce(into: []) {
                if  let clause: SocialPredicate = try symbols[$1] {
                    $0.append(clause)
                } else {
                    fatalError(
                        "Biological predicate cannot be mixed with social predicates"
                    )
                }
            }

            for section: SocialSection in matrix where clauses.allSatisfy({ $0 ~= section }) {
                attributesSocial[section, default: .empty] |= attributes
            }
        }

        self.init(
            metadata: [:],
            factors: .init(
                attributesDefault: attributesDefault ?? .empty,
                attributesSocial: attributesSocial,
                attributesByRace: attributesByRace,
                cultures: [:],
            )
        )
    }
}
extension GameMetadata.Pops {
    public mutating func register(cultures: [Culture]) {
        for culture: Culture in cultures {
            self.factors.cultures[culture.id] = culture
        }
    }
    @inlinable public var cultures: [CultureID: Culture] {
        self.factors.cultures
    }
}
extension GameMetadata.Pops {
    @inlinable public subscript(type: PopType) -> PopMetadata? {
        mutating get {
            {
                if  let existing: PopMetadata = $0 {
                    return existing
                } else if
                    let created: PopMetadata = self.factors.instantiateMetadata(for: type) {
                    $0 = created
                    return created
                } else {
                    return nil
                }

            } (&self.metadata[type])
        }
    }
}
