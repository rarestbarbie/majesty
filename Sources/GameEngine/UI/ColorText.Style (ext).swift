import ColorText

extension ColorText.Style {
    static func spread(_ spread: Double) -> Self {
        // Totally arbitrary thresholds for UI purposes only
        if spread <= 0.001 {
            return .pos
        } else if spread < 0.005 {
            return .em
        } else {
            return .neg
        }
    }
}
