# ML workflow (Google Colab → .tflite)

Training never happens on the laptop. Colab does the heavy work; the repo only stores the exported model and small metadata.

## Folder layout

```
ml/
  README.md            this file
  notebooks/           Colab notebooks (.ipynb), committed without outputs
assets/models/
  prescription_ocr.tflite   exported model (committed)
  model_card.md             version, dataset, metrics, export settings
```

Raw data, checkpoints and `.pt` / `.safetensors` files are git-ignored and stay in Google Drive.

## Steps

1. **Open the notebook in Colab.** On GitHub, open `ml/notebooks/<name>.ipynb` → "Open in Colab", or upload it. Use a T4 GPU runtime.
2. **Mount Google Drive** for datasets and checkpoints:
   ```python
   from google.colab import drive
   drive.mount('/content/drive')
   ```
3. **Data.** Line crops from public handwriting datasets (IAM and similar) plus synthetic prescription lines: real Indian medicine names rendered in handwriting-style fonts with noise, blur and skew.
4. **Fine-tune** `microsoft/trocr-small-handwritten` (Hugging Face `VisionEncoderDecoderModel`). Track CER on a held-out set.
5. **Constrain to real medicines.** Build `medicines.json` (brand, salt, strength, form). After decoding the N best candidates, fuzzy-match against it (normalized Levenshtein + phonetic key). Report **medicine-level accuracy** after matching.
6. **Export to TFLite.** Convert encoder and decoder-step separately (PyTorch → ONNX → TF → TFLite, or `ai-edge-torch`), with dynamic-range quantization. Check that TFLite output matches PyTorch output on 20 samples.
   If decoder conversion fails, fall back to a CRNN + CTC recognizer (see docs/architecture.md §6).
7. **Ship.** Download the `.tflite`, copy it to `assets/models/`, update `assets/models/model_card.md`, commit and push. CI builds the APK with the new model.

## Rules

- Keep notebooks output-free before committing (Colab: Edit → Clear all outputs).
- Model files over ~50 MB: quantize further, or use Git LFS / download on first launch.
- TFLite does not run on Flutter web: Chrome preview uses the placeholder `OcrService`.
