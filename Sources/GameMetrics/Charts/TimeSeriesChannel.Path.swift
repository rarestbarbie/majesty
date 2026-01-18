import ColorReference
import JavaScriptInterop

extension TimeSeriesChannel {
    struct Path {
        let id: Int
        let frames: [TimeSeriesFrame]
        let label: ColorReference?
        let range: (min: Double, max: Double)
    }
}
extension TimeSeriesChannel.Path {
    var d: String? {
        if  self.frames.count < 2 {
            return nil
        }

        let height: Double = self.range.max - self.range.min
        let scale: Double = 1 / height
        var x: Int = 0
        var d: String = "M"
        for frame: TimeSeriesFrame in self.frames {
            let y: Double = scale * (self.range.max - frame.value)
            d += x == 0 ? " 0,\(y)" : " L \(x),\(y)"
            x -= 1
        }
        return d
    }
}
extension TimeSeriesChannel.Path: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case d
        case frames
        case label
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.frames] = self.id == 1 ? self.frames : nil
        js[.label] = self.label
        js[.d] = self.d
    }
}
