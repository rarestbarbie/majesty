enum AddressSpaceError<T>: Error where T: Sendable {
    case collision(T, String, String)
    case reserved(Int16)
    case overflow
}
