# Orchid

This repo is a macOS OCR tool called Orchid that uses local MLX vision-language models.


## Build

```sh
cd orchid
xcodebuild -project Orchid.xcodeproj -scheme Orchid -destination 'platform=macOS,arch=arm64' build
```


## Config file

~/.orchid/config.toml is auto-created on first launch:

```toml
mlx-vlm-python = "/Users/daisy/develop/GLM-OCR/.venv-mlx/bin/python"
port = 14416

[model-path]
glm-ocr = "/Users/daisy/develop/GLM-OCR/models/GLM-OCR-bf16"
paddle-ocr = "/Users/daisy/develop/GLM-OCR/models/PaddleOCR-VL-1.5-bf16"
```