struct Portfolio<Asset> {
    var assets: [(id: Asset, value: Int64)]

    init() {
        self.assets = []
    }
}
