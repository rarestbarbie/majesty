extension InfrastructureReport {
    struct Sort {
        private var columns: [Never]

        init() {
            self.columns = []
        }
    }
}
extension InfrastructureReport.Sort {
    var first: Never? { self.columns.first }
}
extension InfrastructureReport.Sort {
    func ascending(_ a: BuildingTableEntry, _ b: BuildingTableEntry) -> Bool {
        a.id < b.id
    }
}
