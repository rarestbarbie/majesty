extension ProductionReport {
    struct Sort {
        private var columns: [Never]

        init() {
            self.columns = []
        }
    }
}
extension ProductionReport.Sort {
    var first: Never? { self.columns.first }
}
extension ProductionReport.Sort {
    func ascending(_ a: FactoryTableEntry, _ b: FactoryTableEntry) -> Bool {
        a.id < b.id
    }
}
