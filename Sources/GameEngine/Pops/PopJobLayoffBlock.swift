struct PopJobLayoffBlock {
    var size: Int64

    init?(size: Int64) {
        guard size > 0 else {
            return nil
        }
        self.size = size
    }
}
