<p align="center">
  <br>
  <img src="orchid.svg" alt="Lockpaw mascot" width="200" />
  <br>
</p>

<h1 align="center">Orchid</h1>

<p align="center">
  <strong>Screenshot then OCR, seamlessly</strong><br>
</p>



## Build

```sh
cd orchid
xcodebuild -project Orchid.xcodeproj -scheme Orchid -destination 'platform=macOS,arch=arm64' build
```


## Configure

Configure your python interpreter path and model checkpoint paths in `~/.orchid/config.toml`.


```toml
mlx-vlm-python = "/Users/daisy/develop/GLM-OCR/.venv-mlx/bin/python"
port = 14416

[model-path]
glm-ocr = "/Users/daisy/develop/GLM-OCR/models/GLM-OCR-bf16"
paddle-ocr = "/Users/daisy/develop/GLM-OCR/models/PaddleOCR-VL-1.5-bf16"
```