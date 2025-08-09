import GameRules

struct EffectsMatrix<Key> where Key: Hashable {
    var base: EffectsTable<Key, Int64>
    // var percentage: EffectsTable<Key, Int64>

    init() {
        self.base = [:]
        // self.percentage = [:]
    }
}
extension EffectsMatrix {
    subscript(_ key: Key) -> Int64 {
        (self.base[*] ?? 0) + (self.base[key] ?? 0)
    }
}
