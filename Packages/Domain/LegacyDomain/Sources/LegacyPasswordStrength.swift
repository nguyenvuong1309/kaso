public enum LegacyPasswordStrength: String, Codable, Equatable, Sendable {
    case weak
    case fair
    case strong

    public static func evaluate(_ password: String) -> LegacyPasswordStrength {
        let hasUppercase = password.contains { $0.isUppercase }
        let hasLowercase = password.contains { $0.isLowercase }
        let hasNumber = password.contains { $0.isNumber }
        let hasSymbol = password.contains { $0.isLetter == false && $0.isNumber == false }

        if password.count >= 9, hasUppercase, hasLowercase, hasNumber, hasSymbol {
            return .strong
        }

        if password.count >= 8, hasNumber, hasLowercase || hasUppercase {
            return .fair
        }

        return .weak
    }
}
