import 'dart:convert';
import 'dart:typed_data';

/// Builds a one-page A4 PDF from lines of text, using the two standard
/// Helvetica fonts so nothing has to be embedded. The first line is set as a
/// heading. Lines that would run off the page are dropped.
Uint8List buildTextPdf(List<String> lines) {
  final content = StringBuffer();
  var y = 780;
  for (var i = 0; i < lines.length && y > 40; i++) {
    final heading = i == 0;
    content.write('BT /${heading ? 'F2' : 'F1'} ${heading ? 16 : 11} Tf 56 $y Td (${_pdfText(lines[i])}) Tj ET\n');
    y -= heading ? 28 : 16;
  }

  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R '
        '/Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>',
    '<< /Length ${content.length} >>\nstream\n${content}endstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
  ];

  // Everything written is ASCII, so string offsets are byte offsets.
  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    out.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = out.length;
  out.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    out.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return Uint8List.fromList(ascii.encode(out.toString()));
}

/// Makes [text] safe for a PDF literal string: plain ASCII with the
/// delimiters escaped.
String _pdfText(String text) {
  final plain = text
      .replaceAll('·', '-')
      .replaceAll('→', 'to')
      .replaceAll('•', '*')
      .replaceAll('–', '-')
      .replaceAll('’', "'");
  final out = StringBuffer();
  for (final unit in plain.codeUnits) {
    if (unit == 0x5C || unit == 0x28 || unit == 0x29) {
      out
        ..writeCharCode(0x5C)
        ..writeCharCode(unit);
    } else if (unit >= 0x20 && unit <= 0x7E) {
      out.writeCharCode(unit);
    } else {
      out.write('?');
    }
  }
  return out.toString();
}
