<!-- vscode-markdown-toc -->
* [Quick Start](#QuickStart)
* [Dependencies](#Dependencies)
* [Usage](#Usage)
	* [Options](#Options)
	* [Exit Codes](#ExitCodes)
* [Specifying the Password](#SpecifyingthePassword)
* [Running Tests](#RunningTests)
* [Design](#Design)
* [TODO](#TODO)

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc --># decrypt-pdf

A command-line tool that decrypts password-protected PDF files using a cascading
strategy of tools: **qpdf**, **mutool**, and **ghostscript**. It tries each tool
in sequence until one succeeds — so you don't have to remember which tool works
for which PDF.

This is **not** a password cracker. It assumes you already know the password.


## <a name='QuickStart'></a>Quick Start

```bash
# Using the -p flag
./decrypt-pdf.sh -p 's3cret' document.pdf

# Using an environment variable
export DECRYPT_PASSWORD='s3cret'
./decrypt-pdf.sh document.pdf
```

The decrypted file is written to `document_decrypted.pdf` by default, or you can
specify an output path:

```bash
./decrypt-pdf.sh -p 's3cret' document.pdf /tmp/unlocked.pdf
```

## <a name='Dependencies'></a>Dependencies

Install at least one (all three recommended):

```bash
brew install qpdf
brew install mupdf-tools
brew install ghostscript
```

## <a name='Usage'></a>Usage

```
decrypt-pdf.sh [OPTIONS] [-p PASSWORD] INPUT_FILE [OUTPUT_FILE]
```

### <a name='Options'></a>Options

| Flag | Description |
|------|-------------|
| `-p PASSWORD` | Password for the encrypted PDF |
| `--verbose` | Show detailed output from each decryption tool |
| `--quiet`, `-q` | Suppress all output; rely on exit code and output file |
| `-h`, `--help` | Show help message |

### <a name='ExitCodes'></a>Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (or file is already unencrypted) |
| 1 | Failure |

## <a name='SpecifyingthePassword'></a>Specifying the Password

The password can be provided in two ways:

1. **`-p` flag** (highest priority) — passed directly on the command line.
   Simple but visible in `ps` output and shell history.

   ```bash
   ./decrypt-pdf.sh -p 's3cret' document.pdf
   ```

2. **`DECRYPT_PASSWORD` environment variable** — used as a fallback when `-p`
   is not provided. Avoids exposing the password on the command line.

   ```bash
   export DECRYPT_PASSWORD='s3cret'
   ./decrypt-pdf.sh document.pdf
   ```

   Or inline for a single invocation:

   ```bash
   DECRYPT_PASSWORD='s3cret' ./decrypt-pdf.sh document.pdf
   ```

**Precedence:** `-p` flag > `DECRYPT_PASSWORD` env var > error.

## <a name='RunningTests'></a>Running Tests

```bash
# 1. Create a .env file with the test password (see .env.example)
cp .env.example .env
# Edit .env and set TEST_DECRYPT_PASSWORD=<your-password>

# 2. Run the test suite
./test-decrypt-pdf.sh
```

Tests that require the password will be skipped if `TEST_DECRYPT_PASSWORD` is
not set. The `.env` file is gitignored and should never be committed.

## <a name='Design'></a>Design

See [design.md](design.md) for details on the decryption strategy, tool-specific
notes (qpdf, mutool, ghostscript), and the cascading workflow.

## <a name='TODO'></a>TODO

- Automator integration for macOS 
- Create and Publish Homebrew package
