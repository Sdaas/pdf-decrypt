# Packaging a Shell Script as a Homebrew Package

This guide explains how to package and publish a shell script as a
Homebrew package so users can install it using `brew install`.

<!-- vscode-markdown-toc -->
* [Overview](#Overview)
* [Step 3 --- Create a release](#Step3---Createarelease)
* [Step 4 --- Generate SHA256](#Step4---GenerateSHA256)
* [Step 5 --- Create a Homebrew tap](#Step5---CreateaHomebrewtap)
* [Step 6 --- Write the formula](#Step6---Writetheformula)
* [Step 7 --- Test locally](#Step7---Testlocally)
* [Step 8 --- Publish](#Step8---Publish)
* [Step 9 --- Updating versions](#Step9---Updatingversions)
* [Optional Improvements](#OptionalImprovements)
	* [Add help](#Addhelp)
	* [Output file support](#Outputfilesupport)
	* [Validate dependencies](#Validatedependencies)
* [Key Concepts](#KeyConcepts)
* [Example Usage](#ExampleUsage)

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


## Prepare the script

- make sure it is production ready
- make it executable `chmod +x` 

## <a name='Step3---Createarelease'></a> Create a release

Tag your release:

``` bash
git tag v1.0.0
git push origin v1.0.0
```

Create a GitHub Release.

## <a name='Step4---GenerateSHA256'></a>Generate SHA256

``` bash
curl -L -o decrypt-pdf.tar.gz https://github.com/yourname/decrypt-pdf/archive/refs/tags/v1.0.0.tar.gz
shasum -a 256 decrypt-pdf.tar.gz
```

## <a name='Step5---CreateaHomebrewtap'></a>Create a Homebrew tap

Create a repo:

    homebrew-tap/
    └── Formula/

## <a name='Step6---Writetheformula'></a>Write the formula

File: `Formula/decrypt-pdf.rb`

``` ruby
class DecryptPdf < Formula
  desc "Decrypt password-protected PDFs using qpdf and ghostscript"
  homepage "https://github.com/sdaas/decrypt-pdf"
  url "https://github.com/sdaas/decrypt-pdf/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PUT_YOUR_SHA256_HERE"
  license "MIT"

  depends_on "qpdf"
  depends_on "mupdf-tools"
  depends_on "ghostscript"

  def install
    bin.install "decrypt-pdf"
  end

  test do
    system "#{bin}/decrypt-pdf", "--help"
  end
end
```

## <a name='Step7---Testlocally'></a>Test locally

``` bash
brew install --build-from-source ./Formula/decrypt-pdf.rb
```

Or:

``` bash
brew tap yourname/tap
brew install decrypt-pdf
```

## <a name='Step8---Publish'></a>Publish

``` bash
git add .
git commit -m "Add decrypt-pdf formula"
git push origin main
```

Install:

``` bash
brew tap yourname/tap
brew install decrypt-pdf
```

## <a name='Step9---Updatingversions'></a>Updating versions

``` bash
git tag v1.1.0
git push origin v1.1.0
```

Update formula URL and SHA256.

## <a name='OptionalImprovements'></a>Optional Improvements

### <a name='Addhelp'></a>Add help

``` bash
if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: decrypt-pdf <input.pdf> <password>"
  exit 0
fi
```

### <a name='Outputfilesupport'></a>Output file support

``` bash
OUTPUT="${3:-output.pdf}"
```

### <a name='Validatedependencies'></a>Validate dependencies

``` bash
command -v qpdf >/dev/null || { echo "qpdf not installed"; exit 1; }
command -v gs >/dev/null || { echo "ghostscript not installed"; exit 1; }
```

## <a name='KeyConcepts'></a>Key Concepts

-   **Tap**: Custom Homebrew repository
-   **SHA256**: Ensures integrity
-   **Tags**: Required for versioned installs

## <a name='ExampleUsage'></a>Example Usage

``` bash
brew tap yourname/tap
brew install decrypt-pdf

decrypt-pdf file.pdf password
```