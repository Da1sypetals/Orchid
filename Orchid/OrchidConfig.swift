import Foundation
import TOMLKit

struct OrchidConfig {
    var pythonPath: String
    var preferredPort: Int
    var models: [(key: String, path: String)]

    var defaultModel: String { models.first?.key ?? "glm-ocr" }

    static func load() -> OrchidConfig {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".orchid")
        let file = dir.appendingPathComponent("config.toml")

        if !FileManager.default.fileExists(atPath: file.path) {
            try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            writeDefaults(to: file)
        }

        let contents = try! String(contentsOf: file, encoding: .utf8)
        let table = try! TOMLTable(string: contents)

        let pythonPath = table["mlx-vlm-python"]?.string
            ?? "/Users/daisy/develop/GLM-OCR/.venv-mlx/bin/python"
        let preferredPort = table["port"]?.int ?? 14416

        var models: [(key: String, path: String)] = []
        if let modelTable = table["model-path"]?.table {
            for (key, value) in modelTable {
                if let path = value.string {
                    models.append((key: key, path: path))
                }
            }
        }

        if models.isEmpty {
            models = [
                (key: "glm-ocr", path: "/Users/daisy/develop/GLM-OCR/models/GLM-OCR-bf16"),
                (key: "paddle-ocr", path: "/Users/daisy/develop/GLM-OCR/models/PaddleOCR-VL-1.5-bf16"),
            ]
        }

        return OrchidConfig(pythonPath: pythonPath, preferredPort: preferredPort, models: models)
    }

    static func writeDefaults(to url: URL) {
        let template = """
            mlx-vlm-python = "/Users/daisy/develop/GLM-OCR/.venv-mlx/bin/python"
            port = 14416

            [model-path]
            glm-ocr = "/Users/daisy/develop/GLM-OCR/models/GLM-OCR-bf16"
            paddle-ocr = "/Users/daisy/develop/GLM-OCR/models/PaddleOCR-VL-1.5-bf16"
            """
        try! template.write(to: url, atomically: true, encoding: .utf8)
    }

    func modelPath(for key: String) -> String? {
        models.first(where: { $0.key == key })?.path
    }

    func displayName(for key: String) -> String {
        switch key {
        case "glm-ocr": return "GLM-OCR"
        case "paddle-ocr": return "PaddleOCR"
        default: return key
        }
    }
}
