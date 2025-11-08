extension PopulationReport {
    struct Sort {
        private var columns: [ColumnControl]

        init() {
            self.columns = []
        }
    }
}
extension PopulationReport.Sort {
    var first: PopulationReport.ColumnControlType? { self.columns.first?.type }
}
extension PopulationReport.Sort {
    mutating func update(column: PopulationReport.ColumnControl) {
        if  let index: Int = self.columns.firstIndex(where: { $0.id == column.id }) {
            self.columns.remove(at: index)
        }
        self.columns.insert(column, at: 0)
    }

    func ascending(_ a: PopTableEntry, _ b: PopTableEntry) -> Bool {
        for column in self.columns {
            if  let comparison: Bool = column.ascending(a, b) {
                return comparison
            }
        }
        return false
    }
}
