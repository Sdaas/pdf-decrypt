# PDF Decryption

<!-- vscode-markdown-toc -->
<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

To create a command-line tool (and a Automator script) that can reliably open a 
password-protected PDF file. This is not a password cracker - it assumes that the 
user knows the password

## Context
The most common command-line tools are

- `qpdf`
- `mupdf-tools`
- `ghostscript`
- `pdftk-java`

### QPDF

This works for **most** PDF files and should be the first thing to try

`qpdf input.pdf --password='mypassword' output.pdf` 


Sometimes the decryption fails becuase the PDF password are not simple strings. In 
that case, use a hex-encoded version. First run

`echo -n 'yourpassword' | xxd -p` 

This will return a hex-encoded string that is given to qpdf

`qpdf input.pdf --password=HEXENCODED --password-is-hex-key out2.pdf`

In some cases, there may be a problem in the PDF file itself unrelated to encryption
( e.g., Corrupt compressed streams, broken or inconsistent page tree, etc.). Browsers like Chrome are more forgiving and can reconstruct enough of the structure to display the document, but qpdf is stricter and fails to build a valid page tree. 

In this case we can try

```bash
qpdf input.pdf --password='mypassword' \
     --decrypt \
     --object-streams=disable \
     --linearize \
    output.pdf
```

`--decrypt` makes it explicitly decrypt,
`--object-streams=disable` can sometimes work around stream‑level issues by forcing object streams to be written as plain objects,
`--linearize` rewrites the file, sometimes fixing certain layout issues.

Other useful commands/flags

- `--verbose` 
- `--progress` : reports progress of the process
- `--version` : returns the version number
- `--show-encryption` : What kind of encryption is being used 

For example
- `qpdf input.pdf --password='mypassword' --verbose --progress output.pdf` 
- `qpdf --version`
- `qpdf --show-encryption input.pdf`

Exit codes
- 0 : no errors or warnings were found
- 1 : not used
- 2 : errors were found; the file was not processed
- 3 : warnings were found without errors

Use the following command to determine if a PDF file is encrypted

```bash 
qpdf --show-encryption xxx.pdf
File is not encrypted
```

Also see https://qpdf.readthedocs.io/en/stable/

### MU PDF

The basic command is

`mutool clean -p 'password' input.pdf output.pdf`

### GhostSscript

bash
gs -sDEVICE=pdfwrite \
   -sOutputFile=output.pdf \
   -sPDFPassword='mypassword' \
   -dCompatibilityLevel=1.4 \
   -dNOPAUSE -dBATCH -dQUIET \
   

Breakdown of the flags

- `-sDEVICE=pdfwrite` : the output is a PDF. Otherwise `gs` will return to screen or image.
- `-sOutputFile=output.pdf` : output file name
- `-sPDFPassword=mypassword` : the password
- `-dNOPAUSE` : don't pause between pages. **IMPORTANT** `gs` pauses between pages by default
- `-dBATCH` : exit after processing. By default `gs` stays in interactive mode
- `-dQUIET` or `-q`: supress logs and output. run quietly
- `-dCompatibilityLevel=1.4` : PDF compatibilty level. Lower versions are more compatible
and have simpler structure. higher versions support modern features like transparency, layers, etc.
    - `1.3` : Acrobat 4. Very old. avoid
    - `1.4` : Acrobat 5. Widely compatible
    - `1.5` : supports object streams
    - `1.7` : modern PDF

BTW, when we run `-sDEVICE=pdfwrite` Ghostscript is not actually "decrypting" the file - it is actually rendering the input PDF and creating a new one. So it while the encryption is removed, and structure is rebuilt, some metadata may be lost. Think of it as “print to PDF via CLI”

## High-Level Workflow

- Check if all dependencies are installed
- Check if the file is actually encrypted
- Create a backup copy of the file
- First try the simple `qpdf` command 
- Check the decryption succeeded
- If not use `mutool`
- If that still does not work use `gs` without specifying `CompatibilityLevel`
- If that still does not work, use `gs` with `CompatiblityLevel` 1.4 (Acrobat 5) 

Notes
- do not rely on the exit code to determine if the decryption succeeded
- always use the `qpdf --show-encryption xxx.pdf` command for this. If the file is not
  password protected, this will return `File is not encrypted` 

General Behavior

- provide a `--help` option so that the command line usage is clear
- provide a `--verbose` mode. In this, all commmands should be invoked with a "verbose" option so that user can see exactly what is happening.
- provide a `--quiet` and `-q` option - where there is no output message. If the process
succeeds a new decryptd file is created and program exits with code 0. A non 0 exit code
signals some kind of error
- if user does not specify eitehr quiet or verbose mode, then print some informational 
  messages
    - file is not encrypted
    - trying qpdf basic
    - trying qpdf advanced
    - trying mutool
    - trying ghostscript
    - decryption succeeded ( zero exit code)
    - decruption failed ( non zero exit code)