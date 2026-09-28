import 'dart:typed_data';

/// Removes every metadata segment that can carry personal data (EXIF with
/// GPS, XMP, IPTC, maker notes, comments) from a JPEG, keeping what is
/// needed to decode it correctly (JFIF, ICC color profile, Adobe color
/// transform). Pure Dart, so the guarantee is unit tested; it runs on top of
/// the re-encode, which already drops EXIF.
///
/// Returns the input unchanged if it is not a JPEG.
Uint8List stripJpegMetadata(Uint8List jpeg) {
  if (jpeg.length < 4 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return jpeg;
  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  var i = 2;
  while (i + 4 <= jpeg.length) {
    if (jpeg[i] != 0xFF) break; // Corrupt stream: keep the rest as is.
    final marker = jpeg[i + 1];
    if (marker == 0xFF) {
      i++; // Fill byte.
      continue;
    }
    if (marker == 0xDA || marker == 0xD9) {
      // Start of scan (or end): the rest is image data.
      out.add(Uint8List.sublistView(jpeg, i));
      return out.takeBytes();
    }
    final length = (jpeg[i + 2] << 8) | jpeg[i + 3];
    final end = i + 2 + length;
    if (length < 2 || end > jpeg.length) break;
    if (!_isPrivateSegment(marker)) {
      out.add(Uint8List.sublistView(jpeg, i, end));
    }
    i = end;
  }
  out.add(Uint8List.sublistView(jpeg, i));
  return out.takeBytes();
}

/// APP1 (EXIF/XMP), APP3–APP13 (vendor data, IPTC), APP15 and comments.
/// APP0 (JFIF), APP2 (ICC profile) and APP14 (Adobe) are kept.
bool _isPrivateSegment(int marker) =>
    marker == 0xE1 ||
    (marker >= 0xE3 && marker <= 0xED) ||
    marker == 0xEF ||
    marker == 0xFE;
