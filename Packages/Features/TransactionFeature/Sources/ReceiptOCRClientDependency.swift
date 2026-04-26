import Foundation
import ComposableArchitecture
import TransactionDomain

#if canImport(ImageIO)
import ImageIO
#endif

#if canImport(Vision)
import Vision
#endif

public struct ReceiptOCRClient: Sendable {
    public var recognize: @Sendable (Data) async throws -> ReceiptOCRResult

    public init(
        recognize: @escaping @Sendable (Data) async throws -> ReceiptOCRResult
    ) {
        self.recognize = recognize
    }
}

public extension ReceiptOCRClient {
    static let noop = ReceiptOCRClient(
        recognize: { _ in ReceiptOCRResult() }
    )

    static let live = ReceiptOCRClient(
        recognize: { data in
            #if canImport(ImageIO) && canImport(Vision)
            guard
                let source = CGImageSourceCreateWithData(data as CFData, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw ReceiptOCRClientError.invalidImage
            }

            let lines = try await recognizedTextLines(in: image)
            return ReceiptOCRParser.parse(lines: lines)
            #else
            _ = data
            return ReceiptOCRResult()
            #endif
        }
    )
}

private enum ReceiptOCRClientError: Error {
    case invalidImage
}

#if canImport(Vision)
private func recognizedTextLines(in image: CGImage) async throws -> [String] {
    try await withCheckedThrowingContinuation { continuation in
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }

            let lines = (request.results as? [VNRecognizedTextObservation])?
                .compactMap { observation in
                    observation.topCandidates(1).first?.string
                } ?? []

            continuation.resume(returning: lines)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["vi-VN", "en-US"]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
#endif

private enum ReceiptOCRClientKey: DependencyKey {
    static let liveValue = ReceiptOCRClient.live
    static let previewValue = ReceiptOCRClient(
        recognize: { _ in
            ReceiptOCRResult(
                merchantName: "Kaso Coffee",
                amount: 120_000,
                occurredAt: Date(),
                rawText: "Kaso Coffee\nTổng cộng: 120.000 đ"
            )
        }
    )
    static let testValue = ReceiptOCRClient.noop
}

public extension DependencyValues {
    var receiptOCRClient: ReceiptOCRClient {
        get { self[ReceiptOCRClientKey.self] }
        set { self[ReceiptOCRClientKey.self] = newValue }
    }
}
