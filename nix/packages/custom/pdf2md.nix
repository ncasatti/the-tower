{ writers, python3Packages }:

writers.writePython3Bin "pdf2md"
{
  libraries = [ python3Packages.pymupdf4llm ];
  flakeIgnore = [ "E501" "E305" ];
}
  ''
  import argparse
  import pathlib
  import pymupdf4llm

  p = argparse.ArgumentParser(description="Convert PDF(s) to Markdown")
  p.add_argument("pdfs", nargs="+", type=pathlib.Path)
  p.add_argument("-o", "--output-dir", type=pathlib.Path, default=None)
  args = p.parse_args()

  for pdf in args.pdfs:
      md = pymupdf4llm.to_markdown(str(pdf))
      out = (args.output_dir or pdf.parent) / (pdf.stem + ".md")
      out.write_text(md, encoding="utf-8")
      print(f"{pdf} → {out}")
  ''
