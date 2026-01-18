enum ColorParsingError: Error {
    case hex(String)
    case unknown(String)
}
