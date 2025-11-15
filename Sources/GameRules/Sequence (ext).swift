import OrderedCollections

extension Sequence {
    func map<T>(
        to _: [T.ID: T].Type = [T.ID: T].self,
        with transform: (Element) throws -> T
    ) rethrows -> [T.ID: T] where T: Identifiable {
        var output: [T.ID: T] = .init(
            minimumCapacity: self.underestimatedCount
        )
        for element: Element in self {
            let item: T = try transform(element)
            output.updateValue(item, forKey: item.id)
        }
        return output
    }
    func map<T>(
        to _: OrderedDictionary<T.ID, T>.Type = OrderedDictionary<T.ID, T>.self,
        with transform: (Element) throws -> T
    ) rethrows -> OrderedDictionary<T.ID, T> where T: Identifiable {
        var output: OrderedDictionary<T.ID, T> = .init(
            minimumCapacity: self.underestimatedCount
        )
        for element: Element in self {
            let item: T = try transform(element)
            output.updateValue(item, forKey: item.id)
        }
        return output
    }
}
