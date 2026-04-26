import Foundation

public enum TransactionAmountParser {
    public static func parse(_ input: String) -> Decimal? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.isEmpty == false else {
            return nil
        }

        let numericScalars = trimmedInput.unicodeScalars.filter { scalar in
            CharacterSet.decimalDigits.contains(scalar)
                || scalar == "."
                || scalar == ","
        }
        let numericInput = String(String.UnicodeScalarView(numericScalars))
        guard numericInput.contains(where: { $0.isNumber }) else {
            return nil
        }

        let normalizedInput = normalize(numericInput)
        guard normalizedInput.isEmpty == false else {
            return nil
        }

        return Decimal(
            string: normalizedInput,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private static func normalize(_ input: String) -> String {
        if input.contains(".") && input.contains(",") {
            guard
                let dotIndex = input.lastIndex(of: "."),
                let commaIndex = input.lastIndex(of: ",")
            else {
                return input
            }

            if commaIndex > dotIndex {
                return input
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                return input.replacingOccurrences(of: ",", with: "")
            }
        }

        if input.contains(",") {
            return normalizeSingleSeparator(input, separator: ",")
        }

        if input.contains(".") {
            return normalizeSingleSeparator(input, separator: ".")
        }

        return input
    }

    private static func normalizeSingleSeparator(
        _ input: String,
        separator: Character
    ) -> String {
        let parts = input.split(
            separator: separator,
            omittingEmptySubsequences: false
        )
        guard parts.count == 2 else {
            return parts.joined()
        }

        let wholePart = String(parts[0])
        let fractionPart = String(parts[1])
        if (1 ... 2).contains(fractionPart.count) {
            return "\(wholePart).\(fractionPart)"
        }

        return "\(wholePart)\(fractionPart)"
    }
}
