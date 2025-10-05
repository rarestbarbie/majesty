import DollupConfig
import SystemPackage

/// These are the settings Dollup uses to format itself.
@main enum Main: DollupConfiguration {
    public static func configure(file: FilePath?, settings: inout DollupSettings) {
        settings.whitespace {
            $0.width = 96
        }
    }
    public static func report(file: FilePath) {
        print("> reformatted '\(file)'")
    }
}
