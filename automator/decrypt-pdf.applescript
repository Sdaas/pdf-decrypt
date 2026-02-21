-- decrypt-pdf.applescript
-- Automator Quick Action: Decrypt PDF File
--
-- This AppleScript is meant to be used inside an Automator "Quick Action"
-- workflow so that users can right-click a PDF in Finder and decrypt it.
--
-- Setup:
--   1. Copy decrypt-pdf.sh into the workflow bundle:
--        mkdir -p ~/Library/Services/"Decrypt PDF File.workflow"/Contents/
--        cp decrypt-pdf.sh ~/Library/Services/"Decrypt PDF File.workflow"/Contents/
--   2. Open Automator, create a new "Quick Action"
--   3. Set "Workflow receives current PDF files in Finder"
--   4. Add a "Run AppleScript" action and paste this script
--   5. Save as "Decrypt PDF File"
--
-- Usage:
--   Right-click a PDF in Finder > Quick Actions > Decrypt PDF File

on run {input, parameters}
	-- Locate decrypt-pdf.sh bundled inside the workflow
	set scriptPath to (path to home folder as text) & "Library:Services:Decrypt PDF File.workflow:Contents:decrypt-pdf.sh"
	set posixScriptPath to POSIX path of scriptPath

	-- Verify the script exists
	tell application "System Events"
		if not (exists file scriptPath) then
			display alert "decrypt-pdf.sh not found" message "Expected at:" & return & posixScriptPath buttons {"OK"} default button "OK" as critical
			return input
		end if
	end tell

	-- Prompt for the PDF password
	set userPassword to text returned of (display dialog "Enter the PDF password:" default answer "" with hidden answer with title "Decrypt PDF")

	if userPassword is "" then
		display alert "No password entered" message "Decryption cancelled." buttons {"OK"} default button "OK" as warning
		return input
	end if

	-- Process each selected PDF file
	repeat with aFile in input
		set posixPath to POSIX path of (aFile as text)

		-- Build the shell command
		-- Use -q (quiet) so we rely on exit code, and -p to pass the password
		set shellCmd to "'" & posixScriptPath & "' -q -p " & quoted form of userPassword & " " & quoted form of posixPath & " 2>&1"

		try
			set cmdOutput to do shell script shellCmd
			-- Build the expected output filename for the success message
			set baseName to do shell script "basename " & quoted form of posixPath & " .pdf"
			set dirName to do shell script "dirname " & quoted form of posixPath
			set outputPath to dirName & "/" & baseName & "_decrypted.pdf"

			display alert "Decryption Succeeded" message "Output:" & return & outputPath buttons {"OK"} default button "OK"
			-- display notification "Decrypted: " & baseName & "_decrypted.pdf" with title "Decrypt PDF"
		on error errMsg
			display alert "Decryption Failed" message posixPath & return & return & errMsg buttons {"OK"} default button "OK" as critical
			-- display notification "Failed: " & posixPath with title "Decrypt PDF"
		end try
	end repeat

	return input
end run
