import GameIDs
import GameEconomy
import OrderedCollections

extension GameMetadata {
    @frozen public struct Pops {
        @usableFromInline let occupations: [PopOccupation: PopAttributes]
        @usableFromInline let biology: [CultureType: PopAttributes]
        @usableFromInline let `default`: PopAttributes?

        @usableFromInline var _cultures: [CultureID: Culture]

        @usableFromInline var metadata: [PopType: PopMetadata]
    }
}
extension GameMetadata.Pops {
    init(
        resources: OrderedDictionary<Resource, ResourceMetadata>,
        symbols: GameSaveSymbols,
        layers: [PopAttributesDescription]
    ) throws {
        let attributes: (
            occupations: [PopOccupation: PopAttributes],
            biology: [CultureType: PopAttributes],
            default: PopAttributes?
        ) = try layers.reduce(
            into: ([:], [:], nil)
        ) {
            let attributes: PopAttributes = .init(
                l: try $1.l.map {
                    ResourceTier.init(
                        metadata: resources,
                        quantity: try $0.quantities(keys: symbols.resources)
                    )
                },
                e: try $1.e.map {
                    .init(
                        metadata: resources,
                        quantity: try $0.quantities(keys: symbols.resources)
                    )
                },
                x: try $1.x.map {
                    .init(
                        metadata: resources,
                        quantity: try $0.quantities(keys: symbols.resources)
                    )
                },
                output: try $1.output.map {
                    .init(
                        metadata: resources,
                        quantity: try $0.quantities(keys: symbols.resources)
                    )
                }
            )

            switch $1.where {
            case .occupation(let name)?:
                $0.occupations[try symbols.occupations[name]] = attributes
            case .biology(let type)?:
                $0.biology[try symbols.biology[type]] = attributes
            case nil:
                guard case nil = $0.default else {
                    fatalError("Multiple default pop attributes layers defined")
                }

                $0.default = attributes
            }
        }

        self.init(
            occupations: attributes.occupations,
            biology: attributes.biology,
            default: attributes.default,
            _cultures: [:],
            metadata: [:]
        )
    }
}
extension GameMetadata.Pops {
    public mutating func register(cultures: [Culture]) {
        for culture: Culture in cultures {
            self._cultures[culture.id] = culture
        }
    }
    @inlinable public var cultures: [CultureID: Culture] {
        self._cultures
    }
}
extension GameMetadata.Pops {
    @inlinable public subscript(type: PopType) -> PopMetadata? {
        mutating get {
            {
                if let existing: PopMetadata = $0 {
                    return existing
                }
                guard
                let race: Culture = self._cultures[type.race] else {
                    return nil
                }

                var attributes: PopAttributes = self.default ?? .empty
                if  let layer: PopAttributes = self.biology[race.type] {
                    attributes |= layer
                }
                if  let layer: PopAttributes = self.occupations[type.occupation] {
                    attributes |= layer
                }

                let new: PopMetadata = .init(
                    occupation: type.occupation,
                    gender: type.gender,
                    race: race,
                    l: attributes.l ?? .empty,
                    e: attributes.e ?? .empty,
                    x: attributes.x ?? .empty,
                    output: attributes.output ?? .empty
                )

                $0 = new
                return new

            } (&self.metadata[type])
        }
    }
}

