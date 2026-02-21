class DecryptPdf < Formula
  desc "Decrypt password-protected PDFs using a cascading strategy (qpdf, mutool, ghostscript)"
  homepage "https://github.com/sdaas/pdf-experiments"
  url "https://github.com/sdaas/pdf-experiments/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER — replace after creating the GitHub release"
  license "MIT"

  depends_on "qpdf"
  depends_on "mupdf-tools"
  depends_on "ghostscript"

  def install
    bin.install "decrypt-pdf"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/decrypt-pdf --help")
  end
end
