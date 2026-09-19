# Zync QR Transport V2

V1 still uses the same semantic payload schema (`v:1`) and remains serverless/local-only.

## Compatibility
- Small profiles continue to encode as the legacy raw compact JSON.
- New builds must continue to decode that legacy raw JSON.
- Larger profiles may use a transport wrapper: `Z2:` + URL-safe base64(zlib(JSON)).
- The compressed wrapper changes only the QR transport, not the payload schema.

## Why
A profile with many canonical and custom interests can make a raw JSON QR unnecessarily dense. Compression keeps the QR easier to scan while preserving all selected interests and custom readable metadata, without adding a pairing server or user database.

## Guardrails
- Compression is adaptive and used only when the raw payload is large enough and the compressed form is actually smaller.
- Decoding validates the existing payload version after decompression.
- Malformed compressed payloads are rejected as invalid Zync QR data.
