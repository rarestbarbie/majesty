@frozen public struct ResourceStockpileCollection<Element> {
    @usableFromInline let elements: [Element]
    @usableFromInline let elementsPartition: Int

    @inlinable init(elements: [Element], elementsPartition: Int) {
        self.elements = elements
        self.elementsPartition = elementsPartition
    }
}
extension ResourceStockpileCollection: RandomAccessCollection {
    @inlinable public var startIndex: Int { self.elements.startIndex }
    @inlinable public var endIndex: Int { self.elements.endIndex }
    @inlinable public subscript(i: Int) -> (tradeable: Bool, output: Element) {
        (i >= self.elementsPartition, self.elements[i])
    }
}
