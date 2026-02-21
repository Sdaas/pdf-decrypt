class DecryptPdf < Formula
  desc "Decrypt password-protected PDFs using a cascading strategy (qpdf, mutool, ghostscript)"
  homepage "https://github.com/Sdaas/pdf-decrypt"
  url "https://github.com/Sdaas/pdf-decrypt/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "82b87ee177b17e785c2e6933caec0895fe9cae4b2b58ed7c99a591d7745c3edd"
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
