#!/usr/bin/env bash
#
# test-decrypt-pdf.sh — Tests for decrypt-pdf.sh
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly DECRYPT_SCRIPT="${SCRIPT_DIR}/decrypt-pdf.sh"
readonly TEST_PDF="${SCRIPT_DIR}/test-data/jyoti.pdf"

# Load .env if present (provides TEST_DECRYPT_PASSWORD)
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/.env"
fi

# Password for decryption tests — skip password-dependent tests if unset
TEST_PASSWORD="${TEST_DECRYPT_PASSWORD:-}"

PASS_COUNT=0
FAIL_COUNT=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo -e "\033[0;32m  PASS\033[0m $1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo -e "\033[0;31m  FAIL\033[0m $1"
}

assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" -eq "$expected" ]]; then
        pass "$description"
    else
        fail "$description (expected exit=$expected, got exit=$actual)"
    fi
}

cleanup_tmp_files() {
    rm -f /tmp/test_decrypt_*.pdf
    rm -f /tmp/test_unencrypted*.pdf
    rm -f /tmp/test_unencrypted*.pdf.bak
    rm -f "${TEST_PDF}.bak"
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
test_help_flag() {
    echo "--- Test: --help prints usage ---"
    local output
    output="$(bash "$DECRYPT_SCRIPT" --help 2>&1)"
    local rc=$?
    assert_exit_code "--help exits with 0" 0 "$rc"

    if echo "$output" | grep -q "Usage:"; then
        pass "--help output contains Usage:"
    else
        fail "--help output missing Usage:"
    fi

    if echo "$output" | grep -q "\-p PASSWORD"; then
        pass "--help output documents -p flag"
    else
        fail "--help output missing -p flag documentation"
    fi
}

test_missing_password() {
    echo "--- Test: missing password ---"
    local rc=0
    DECRYPT_PASSWORD= bash "$DECRYPT_SCRIPT" "$TEST_PDF" >/dev/null 2>&1 || rc=$?
    assert_exit_code "Missing -p flag exits with 1" 1 "$rc"
}

test_missing_input_file() {
    echo "--- Test: missing input file ---"
    local rc=0
    bash "$DECRYPT_SCRIPT" -p "test" >/dev/null 2>&1 || rc=$?
    assert_exit_code "Missing input file exits with 1" 1 "$rc"
}

test_nonexistent_file() {
    echo "--- Test: nonexistent input file ---"
    local rc=0
    bash "$DECRYPT_SCRIPT" -p "test" /tmp/nonexistent_file.pdf >/dev/null 2>&1 || rc=$?
    assert_exit_code "Nonexistent file exits with 1" 1 "$rc"
}

test_non_pdf_file() {
    echo "--- Test: non-PDF file ---"
    echo "this is not a pdf" > /tmp/test_decrypt_not_a.pdf
    local rc=0
    bash "$DECRYPT_SCRIPT" -p "test" /tmp/test_decrypt_not_a.pdf >/dev/null 2>&1 || rc=$?
    assert_exit_code "Non-PDF file exits with 1" 1 "$rc"
    rm -f /tmp/test_decrypt_not_a.pdf
}

test_already_unencrypted() {
    echo "--- Test: already unencrypted file ---"
    if ! command -v qpdf &>/dev/null; then
        echo "  SKIP (qpdf not installed)"
        return
    fi

    # Create an unencrypted PDF with a minimal valid structure
    # Using qpdf to create from the test pdf if we can decrypt it first,
    # or just use a simple approach
    local unenc="/tmp/test_unencrypted_input.pdf"
    # Create a minimal valid PDF
    cat > "$unenc" <<'MINPDF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R>>endobj
xref
0 4
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
trailer<</Size 4/Root 1 0 R>>
startxref
190
%%EOF
MINPDF

    local output rc=0
    output="$(bash "$DECRYPT_SCRIPT" -p "test" "$unenc" /tmp/test_unencrypted_out.pdf 2>&1)" || rc=$?
    assert_exit_code "Unencrypted file exits with 0" 0 "$rc"

    if echo "$output" | grep -q "not encrypted"; then
        pass "Reports file is not encrypted"
    else
        fail "Should report file is not encrypted"
    fi

    rm -f "$unenc" /tmp/test_unencrypted_out.pdf "${unenc}.bak"
}

test_successful_decryption() {
    echo "--- Test: successful decryption ---"
    if [[ -z "$TEST_PASSWORD" ]]; then
        echo "  SKIP (TEST_DECRYPT_PASSWORD not set)"
        return
    fi
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local output_file="/tmp/test_decrypt_output.pdf"
    local rc=0
    bash "$DECRYPT_SCRIPT" -p "$TEST_PASSWORD" "$TEST_PDF" "$output_file" 2>&1 || rc=$?
    assert_exit_code "Decryption exits with 0" 0 "$rc"

    if [[ -f "$output_file" ]]; then
        pass "Output file created"
    else
        fail "Output file not created"
        return
    fi

    # Verify the output is not encrypted
    if command -v qpdf &>/dev/null; then
        local enc_check
        enc_check="$(qpdf --show-encryption "$output_file" 2>&1)" || true
        if echo "$enc_check" | grep -q "File is not encrypted"; then
            pass "Output file is not encrypted"
        else
            fail "Output file still appears encrypted"
        fi
    fi

    rm -f "$output_file"
}

test_env_var_password() {
    echo "--- Test: DECRYPT_PASSWORD env var fallback ---"
    if [[ -z "$TEST_PASSWORD" ]]; then
        echo "  SKIP (TEST_DECRYPT_PASSWORD not set)"
        return
    fi
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local output_file="/tmp/test_decrypt_envvar.pdf"
    local rc=0
    DECRYPT_PASSWORD="$TEST_PASSWORD" bash "$DECRYPT_SCRIPT" "$TEST_PDF" "$output_file" >/dev/null 2>&1 || rc=$?
    assert_exit_code "Env var password exits with 0" 0 "$rc"

    if [[ -f "$output_file" ]]; then
        pass "Output file created via env var password"
    else
        fail "Output file not created via env var password"
    fi

    rm -f "$output_file"
}

test_quiet_mode() {
    echo "--- Test: quiet mode ---"
    if [[ -z "$TEST_PASSWORD" ]]; then
        echo "  SKIP (TEST_DECRYPT_PASSWORD not set)"
        return
    fi
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local output_file="/tmp/test_decrypt_quiet.pdf"
    local output rc=0
    output="$(bash "$DECRYPT_SCRIPT" -q -p "$TEST_PASSWORD" "$TEST_PDF" "$output_file" 2>&1)" || rc=$?

    if [[ -z "$output" ]]; then
        pass "Quiet mode produces no output"
    else
        fail "Quiet mode produced output: ${output}"
    fi

    assert_exit_code "Quiet mode exits with 0" 0 "$rc"
    rm -f "$output_file"
}

test_default_output_filename() {
    echo "--- Test: default output filename ---"
    if [[ -z "$TEST_PASSWORD" ]]; then
        echo "  SKIP (TEST_DECRYPT_PASSWORD not set)"
        return
    fi
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local expected_output="${SCRIPT_DIR}/test-data/jyoti_decrypted.pdf"
    local rc=0
    bash "$DECRYPT_SCRIPT" -q -p "$TEST_PASSWORD" "$TEST_PDF" 2>&1 || rc=$?
    assert_exit_code "Default output name exits with 0" 0 "$rc"

    if [[ -f "$expected_output" ]]; then
        pass "Default output file created at expected path"
        rm -f "$expected_output"
    else
        fail "Default output file not found at ${expected_output}"
    fi

    rm -f "${TEST_PDF}.bak"
}

test_verbose_mode() {
    echo "--- Test: verbose mode ---"
    if [[ -z "$TEST_PASSWORD" ]]; then
        echo "  SKIP (TEST_DECRYPT_PASSWORD not set)"
        return
    fi
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local output_file="/tmp/test_decrypt_verbose.pdf"
    local output rc=0
    output="$(bash "$DECRYPT_SCRIPT" --verbose -p "$TEST_PASSWORD" "$TEST_PDF" "$output_file" 2>&1)" || rc=$?
    assert_exit_code "Verbose mode exits with 0" 0 "$rc"

    if echo "$output" | grep -qE "\[DEBUG\]|Running:"; then
        pass "Verbose mode produces debug output"
    else
        fail "Verbose mode missing debug output"
    fi

    rm -f "$output_file"
}

test_unknown_flag() {
    echo "--- Test: unknown flag ---"
    local rc=0
    bash "$DECRYPT_SCRIPT" --invalid -p "test" /tmp/nonexistent.pdf >/dev/null 2>&1 || rc=$?
    assert_exit_code "Unknown flag exits with 1" 1 "$rc"
}

test_wrong_password() {
    echo "--- Test: wrong password ---"
    if [[ ! -f "$TEST_PDF" ]]; then
        echo "  SKIP (test file ${TEST_PDF} not found)"
        return
    fi

    local output_file="/tmp/test_decrypt_wrongpw.pdf"
    local rc=0
    bash "$DECRYPT_SCRIPT" -p "definitely_wrong_password_12345" "$TEST_PDF" "$output_file" >/dev/null 2>&1 || rc=$?
    assert_exit_code "Wrong password exits with 1" 1 "$rc"

    rm -f "$output_file"
}

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------
main() {
    echo "========================================="
    echo " decrypt-pdf.sh — Test Suite"
    echo "========================================="
    echo ""

    cleanup_tmp_files

    test_help_flag
    test_missing_password
    test_missing_input_file
    test_nonexistent_file
    test_non_pdf_file
    test_already_unencrypted
    test_successful_decryption
    test_env_var_password
    test_quiet_mode
    test_default_output_filename
    test_verbose_mode
    test_unknown_flag
    test_wrong_password

    cleanup_tmp_files

    echo ""
    echo "========================================="
    echo " Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
    echo "========================================="

    if [[ "$FAIL_COUNT" -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
