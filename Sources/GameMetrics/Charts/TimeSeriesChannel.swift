import ColorReference

@frozen public struct TimeSeriesChannel {
    @usableFromInline let id: Int
    @usableFromInline var frames: [TimeSeriesFrame]
    @usableFromInline var label: ColorReference?

    @inlinable public init(id: Int, frames: [TimeSeriesFrame], label: ColorReference?) {
        self.id = id
        self.frames = frames
        self.label = label
    }
}
extension TimeSeriesChannel {
    func path(in range: (min: Double, max: Double)) -> Path {
        .init(id: self.id, frames: self.frames, label: self.label, range: range)
    }
}
