import Foundation

// MARK: - SSE Chunk models
private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            var content: String?
        }
        var delta: Delta
    }
    var choices: [Choice]
}

// MARK: - OCR Client
enum OCRClient {
    static var endpoint: URL {
        URL(string: "http://127.0.0.1:\(ServerManager.shared.activePort)/chat/completions")!
    }
    static var modelName: String {
        ServerManager.shared.activeModelPath
    }
    static let prompt = """
        Recognize the text in the image and output in Markdown format. \
        Preserve the original layout (headings/paragraphs/tables/formulas). \
        Do not fabricate content that does not exist in the image.
        """

    /// Streams OCR results for the given image file URL.
    /// - Parameters:
    ///   - imageURL: Local file URL to the PNG that was captured.
    ///   - onChunk: Called on the main actor with each incremental text chunk.
    ///   - onComplete: Called on the main actor when streaming finishes (with optional error).
    static func recognize(
        imageURL: URL,
        onChunk: @escaping @MainActor (String) -> Void,
        onComplete: @escaping @MainActor (Error?) -> Void
    ) {
        Task {
            do {
                try await streamOCR(imageURL: imageURL, onChunk: onChunk)
                await MainActor.run { onComplete(nil) }
            } catch {
                await MainActor.run { onComplete(error) }
            }
        }
    }

    private static func streamOCR(
        imageURL: URL,
        onChunk: @escaping @MainActor (String) -> Void
    ) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": modelName,
            "stream": true,
            "max_tokens": 4096,
            "temperature": 0.01,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": ["url": imageURL.path]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (stream, response) = try await URLSession.shared.bytes(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw OCRError.httpError(httpResponse.statusCode)
        }

        for try await line in stream.lines {
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))
            if payload.trimmingCharacters(in: .whitespaces) == "[DONE]" { break }

            guard let data = payload.data(using: .utf8),
                  let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                  let text = chunk.choices.first?.delta.content,
                  !text.isEmpty
            else { continue }

            await MainActor.run { onChunk(text) }
        }
    }
}

// MARK: - Errors
enum OCRError: LocalizedError {
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "OCR server returned HTTP \(code)"
        }
    }
}
