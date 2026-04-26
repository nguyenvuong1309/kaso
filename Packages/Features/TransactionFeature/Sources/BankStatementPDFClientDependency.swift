import Foundation
import ComposableArchitecture

#if canImport(PDFKit)
import PDFKit
#endif

public struct BankStatementPDFClient: Sendable {
    public var extractText: @Sendable (Data) async throws -> String

    public init(
        extractText: @escaping @Sendable (Data) async throws -> String
    ) {
        self.extractText = extractText
    }
}

public extension BankStatementPDFClient {
    static let noop = BankStatementPDFClient(
        extractText: { _ in "" }
    )

    static let live = BankStatementPDFClient(
        extractText: { data in
            #if canImport(PDFKit)
            guard let document = PDFDocument(data: data) else {
                throw BankStatementPDFClientError.invalidPDF
            }

            let text = (0 ..< document.pageCount)
                .compactMap { document.page(at: $0)?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.isEmpty == false else {
                throw BankStatementPDFClientError.emptyText
            }

            return text
            #else
            _ = data
            throw BankStatementPDFClientError.emptyText
            #endif
        }
    )
}

private enum BankStatementPDFClientError: Error {
    case invalidPDF
    case emptyText
}

private enum BankStatementPDFClientKey: DependencyKey {
    static let liveValue = BankStatementPDFClient.live
    static let previewValue = BankStatementPDFClient(
        extractText: { _ in "26/04/2026 Highlands Coffee -120.000 VND" }
    )
    static let testValue = BankStatementPDFClient.noop
}

public extension DependencyValues {
    var bankStatementPDFClient: BankStatementPDFClient {
        get { self[BankStatementPDFClientKey.self] }
        set { self[BankStatementPDFClientKey.self] = newValue }
    }
}
