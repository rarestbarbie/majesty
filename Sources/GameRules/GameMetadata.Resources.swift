import GameIDs
import OrderedCollections

extension GameMetadata {
    @frozen public struct Resources {
        @usableFromInline let fallback: ResourceMetadata
        public let local: [ResourceMetadata]
        @usableFromInline let table: OrderedDictionary<Resource, ResourceMetadata>
    }
}
extension GameMetadata.Resources {
    @inlinable public var all: [ResourceMetadata] { self.table.values.elements }
    @inlinable public subscript(id: Resource) -> ResourceMetadata {
        self.table[id] ?? self.fallback
    }
}
