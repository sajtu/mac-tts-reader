#!/bin/bash

# -----------------------------------------------------------------------------
# mac-tts-reader / reader.bash
# -----------------------------------------------------------------------------
# Converts a Microsoft Word document (.doc/.docx) into narrated audio using:
#   1) text extraction via macOS textutil
#   2) pronunciation mapping via pronunc.tsv
#   3) TTS via macOS say
#   4) audio conversion to AAC .m4a via ffmpeg
#
# -----------------------------------------------------------------------------

SELECT_SAY_VOICE='Zoe (Premium)'
REQUIRE_FFMPEG=1

###############################################################################
## Do not edit below unless you are a developer and want to make improvements.
###############################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PRONUNC_FILE="${SCRIPT_DIR}/pronunc.tsv"

die() {
	echo ""
	echo " ERROR: $*" >&2
	echo ""
	exit 1
}

ask_yes_no() {
	local prompt="$1"
	local answer

	while true; do
		printf " %s [y/N]: " "$prompt"
		read -r answer

		case "$answer" in
			y|Y|yes|YES) return 0 ;;
			n|N|no|NO|"") return 1 ;;
			*) echo " Please answer y or n." ;;
		esac
	done
}

require_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		die "This script only supports macOS because it requires 'say', 'textutil', and 'afconvert'."
	fi
}

install_homebrew() {
	if command -v brew >/dev/null 2>&1; then
		return 0
	fi

	echo ""
	echo " Homebrew is not installed."
	echo " Homebrew is required to install missing dependencies such as python3 and ffmpeg."
	echo ""

	if ! ask_yes_no "Install Homebrew now?"; then
		die "Missing dependency: Homebrew. Cannot install required packages."
	fi

	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	if [[ -x "/opt/homebrew/bin/brew" ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi

	if [[ -x "/usr/local/bin/brew" ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi

	if ! command -v brew >/dev/null 2>&1; then
		die "Homebrew installation finished, but 'brew' is still not available in PATH. Restart Terminal or add brew to PATH."
	fi
}

install_brew_package() {
	local pkg="$1"
	local cmd="$2"

	if command -v "$cmd" >/dev/null 2>&1; then
		return 0
	fi

	install_homebrew

	echo ""
	echo " Missing dependency: ${cmd}"
	echo " Package to install: ${pkg}"
	echo ""

	if ! ask_yes_no "Install ${pkg} using Homebrew?"; then
		die "Missing required dependency: ${cmd}"
	fi

	brew install "$pkg"
}

check_required_command() {
	local cmd="$1"
	local install_note="$2"

	if ! command -v "$cmd" >/dev/null 2>&1; then
		die "Missing required macOS command: ${cmd}. ${install_note}"
	fi
}

check_voice() {
	local voice_prefix

	voice_prefix="$(echo "${SELECT_SAY_VOICE}" | awk '{print $1}')"

	if ! say -v '?' | awk '{print $1}' | grep -qx "${voice_prefix}"; then
		echo ""
		echo " WARNING: The selected voice may not be installed:"
		echo " ${SELECT_SAY_VOICE}"
		echo ""
		echo " Available voices can be listed with:"
		echo " say -v '?'"
		echo ""
		echo " Continuing anyway; 'say' will fail later if the voice is unavailable."
		echo ""
	fi
}

check_dependencies() {
	require_macos

	check_required_command "say" "This should exist on macOS."
	check_required_command "textutil" "This should exist on macOS."
	check_required_command "afconvert" "This should exist on macOS."
	check_required_command "file" "This should exist on macOS."
	check_required_command "awk" "This should exist on macOS."
	check_required_command "sed" "This should exist on macOS."
	check_required_command "column" "This should exist on macOS."

	install_brew_package "python" "python3"

	if [[ "${REQUIRE_FFMPEG}" -eq 1 ]]; then
		install_brew_package "ffmpeg" "ffmpeg"
	fi

	echo ""
	echo " Re-checking dependencies..."
	echo ""

	local missing=0

	for cmd in say textutil afconvert file awk sed column python3; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo " Missing: $cmd" >&2
			missing=1
		fi
	done

	if [[ "${REQUIRE_FFMPEG}" -eq 1 ]] && ! command -v ffmpeg >/dev/null 2>&1; then
		echo " Missing: ffmpeg" >&2
		missing=1
	fi

	if [[ "$missing" -ne 0 ]]; then
		die "One or more required dependencies are still missing."
	fi

	check_voice

	echo " Dependency check passed."
	echo ""
}

usage() {
	echo ""
	echo " Usage: $0 <file.doc|file.docx>"
	echo "        $0 --edit"
	echo "        $0 --test"
	echo ""
}

check_dependencies

if [[ ! -f "${PRONUNC_FILE}" ]]; then
	echo ""
	echo " ERROR: Cannot find pronunciation map:"
	echo " ${PRONUNC_FILE}" >&2
	echo ""
	exit 1
fi

if [[ "${1:-}" == "--edit" ]]; then
	sudo nano "${PRONUNC_FILE}"
	exit $?
fi

if [[ "${1:-}" == "--test" ]]; then
	testlist=$(
	(
		awk -F'\t' '{ printf "[%d] '\''%s'\'':'\''%s'\''\n", NR, $1, $2 }' "${PRONUNC_FILE}" | while read -r line
		do
			cLine=$(echo "$line" | sed 's/\ /\%SS/g')
			echo " [Testing] $cLine" | sed 's/:/\ /g'
		done
	) | column -t )

	if [[ -n "${testlist}" ]]; then
		echo ""
		echo ""
		echo " Test starting."
		say -v "${SELECT_SAY_VOICE}" -r 150 "Test Starting. [[slnc 500]]"

		countTest=$(echo "${testlist}" | wc -l | awk '{print $1}')

		echo ""
		echo " There are ${countTest} words to test."
		say -v "${SELECT_SAY_VOICE}" -r 150 "There are ${countTest} words to test. [[slnc 500]]"

		echo ""

		i=0
		while IFS= read -r line; do
			((i++))
			sLine=$(echo "$line" | sed 's/%SS/\ /g')
			echo " $sLine"
			sayword=$(echo "$line" | awk '{print $NF}')
			say -v "${SELECT_SAY_VOICE}" -r 150 "Word number ${i}. [[slnc 320]] ${sayword} [[slnc 500]]"
		done <<< "${testlist}"

		echo ""
		echo ""
		echo "Testing Completed."
		echo ""
		echo ""
		say -v "${SELECT_SAY_VOICE}" -r 150 "Testing Completed. [[slnc 500]]"
	else
		say -v "${SELECT_SAY_VOICE}" -r 150 "Testing Cancelled. List Empty. [[slnc 500]]"
		say -v "${SELECT_SAY_VOICE}" -r 150 "Exiting with error code 1. [[slnc 500]]"
		exit 1
	fi

	exit 0
fi

f="${1:-}"

if [[ -z "$f" || ! -f "$f" ]]; then
	usage
	exit 1
fi

input_path="$(cd -- "$(dirname -- "$f")" && pwd -P)/$(basename -- "$f")"
input_dir="$(dirname -- "$input_path")"
input_base="$(basename -- "$input_path")"

mime=$(file --mime-type -b "$input_path")

apply_pronunc() {
	local input_txt="$1"
	local output_txt="$2"
	local map_file="$3"

	python3 - "$input_txt" "$output_txt" "$map_file" <<'PY'
import re
import sys
from pathlib import Path

INPUT = Path(sys.argv[1])
OUTPUT = Path(sys.argv[2])
MAP = Path(sys.argv[3])

SENTENCE_PAUSE_MS = 350
PARAGRAPH_EXTRA_PAUSE_MS = 640
ELLIPSIS_PAUSE_MS = 1000
DIALOG_END_PAUSE_MS = 350
EXCLAMATION_PAUSE_MS = 800
COMMA_EXTRA_PAUSE_MS = 200
LEAD_IN_PAUSE_MS = 1000
INTRO_TITLE_PAUSE_MS = 2000
SCENE_BREAK_PAUSE_MS = 2000

text = INPUT.read_text(encoding="utf-8")
text = text.replace("\r\n", "\n").replace("\r", "\n")
text = text.strip()

pairs = []

for lineno, line in enumerate(MAP.read_text(encoding="utf-8").splitlines(), start=1):
	if not line.strip() or line.startswith("#"):
		continue

	if "\t" not in line:
		raise ValueError(f"{MAP}:{lineno}: missing TAB separator")

	original, spoken = line.split("\t", 1)
	original = original.strip()
	spoken = spoken.strip()

	if original:
		pairs.append((original, spoken))

pairs.sort(key=lambda x: (-len(x[0]), x[0].lower()))

def preserve_case_replace(match, replacement):
	original_text = match.group(0)

	if original_text.isupper():
		return replacement.upper()

	if original_text[0].isupper():
		return replacement.capitalize()

	return replacement

for original, spoken in pairs:
	pattern = re.compile(
		rf"(?<![A-Za-z0-9_]){re.escape(original)}(?![A-Za-z0-9_])",
		re.IGNORECASE
	)

	text = pattern.sub(
		lambda m: preserve_case_replace(m, spoken),
		text
	)

text = f"[[slnc {LEAD_IN_PAUSE_MS}]]\n{text}"

intro_pattern = re.compile(
	r'^(\[\[slnc \d+\]\]\n)'
	r'([ \t]*Chapter\s+\d+(?::[^\n]+)?(?:\n[ \t]*[^\n]+)?)'
	r'\n\s*\n+',
	re.IGNORECASE
)

text = intro_pattern.sub(
	rf'\1\2\n[[slnc {INTRO_TITLE_PAUSE_MS}]]\n',
	text,
	count=1
)

ellipsis_pattern = re.compile(
	r'(\.\.\.)((?:["\']|\))?)(?=\s|$)'
)
text = ellipsis_pattern.sub(rf'\1\2 [[slnc {ELLIPSIS_PAUSE_MS}]]', text)

dialog_end_pattern = re.compile(
	r'((?:[.!?,]+|\.{3})["\'])(?=\s+\S)'
)
text = dialog_end_pattern.sub(rf'\1 [[slnc {DIALOG_END_PAUSE_MS}]]', text)

comma_pattern = re.compile(
	r'(,)(?!["\']|\))(?=\s(?!\[\[slnc)|$)'
)
text = comma_pattern.sub(rf'\1 [[slnc {COMMA_EXTRA_PAUSE_MS}]]', text)

exclaim_pattern = re.compile(
	r'(!+)((?:["\']|\))?)(?=\s(?!\[\[slnc)|$)'
)
text = exclaim_pattern.sub(rf'\1\2 [[slnc {EXCLAMATION_PAUSE_MS}]]', text)

sentence_pattern = re.compile(
	r'(?<!\.)(\.|\?+)((?:["\']|\))?)(?!\.)(?=\s(?!\[\[slnc)|$)'
)
text = sentence_pattern.sub(rf'\1\2 [[slnc {SENTENCE_PAUSE_MS}]]', text)

scene_break_re = r'(?m)^([ \t]*###[ \t]*)$'
text = re.sub(
	scene_break_re,
	rf'\1\n[[slnc {SCENE_BREAK_PAUSE_MS}]]',
	text
)

paragraph_blank_re = r'(?<=\S)[ \t]*\n[ \t]*\n(?:[ \t]*\n)*(?=\S)'
text = re.sub(
	paragraph_blank_re,
	f'\n[[slnc {PARAGRAPH_EXTRA_PAUSE_MS}]]\n',
	text
)

sentence_pause_values = (
	SENTENCE_PAUSE_MS,
	DIALOG_END_PAUSE_MS,
	EXCLAMATION_PAUSE_MS,
	ELLIPSIS_PAUSE_MS,
)

single_newline_paragraph_re = (
	r'(\[\[slnc (?:' +
	"|".join(str(v) for v in sorted(set(sentence_pause_values))) +
	r')\]\])[ \t]*\n(?=(?!\[\[slnc)(?![ \t]*###)\S)'
)

text = re.sub(
	single_newline_paragraph_re,
	rf'\1\n[[slnc {PARAGRAPH_EXTRA_PAUSE_MS}]]\n',
	text
)

text = text.rstrip() + f'\n[[slnc 3000]]\n'
OUTPUT.write_text(text, encoding="utf-8")
print(f"Wrote {OUTPUT}")
PY
}

main() {
	local in="$1"
	local in_dir
	local in_base
	local out
	local tts_out
	local aiff_out
	local m4a_out
	local tmp_caf
	local txtconvrc
	local sayRC
	local convRC
	local rc1

	in_dir="$(dirname -- "$in")"
	in_base="$(basename -- "$in")"
	out="${in_dir}/${in_base%.*}.txt"

	echo ""
	echo " Converting '${in}' to plain text file,"
	echo " '${out}'..."

	textutil -convert txt "${in}" -output "${out}"
	txtconvrc=$?

	if [[ ${txtconvrc} -ne 0 ]]; then
		die "Conversion failed."
	fi

	if [[ ! -f "${out}" ]]; then
		die "Cannot find '${out}'."
	fi

	echo " File converted successfully to '${out}'."
	echo ""

	echo " Normalizing punctuation..."

	python3 - "${out}" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8")

replacements = {
	"\u2026": "...",
	"\u2014": "--",
	"\u2013": "-",
	"\u201c": '"',
	"\u201d": '"',
	"\u2018": "'",
	"\u2019": "'",
	"\u00a0": " ",
}

for src, dst in replacements.items():
	text = text.replace(src, dst)

p.write_text(text, encoding="utf-8")
PY

	echo " Normalization complete."
	echo ""

	tts_out="${out%.*}_TTS.txt"

	echo " Applying pronunciation map..."

	apply_pronunc "${out}" "${tts_out}" "${PRONUNC_FILE}" | while read -r stdout
	do
		echo " ${stdout}"
	done

	if [[ ! -f "${tts_out}" ]]; then
		die "Cannot find '${tts_out}'."
	fi

	echo " TTS file created: '${tts_out}'"
	echo ""

	echo " Generating narration for ${in}..."

	aiff_out="${out%.*}.aiff"

	say -v "${SELECT_SAY_VOICE}" -r 150 -o "${aiff_out}" -f "${tts_out}"
	sayRC=$?

	if [[ ${sayRC} -ne 0 ]]; then
		die "Generate narration failed."
	fi

	if [[ ! -f "${aiff_out}" ]]; then
		die "Cannot find '${aiff_out}'."
	fi

	echo " Successfully generated narration:"
	echo " ${aiff_out}"
	echo ""

	echo " Converting to m4a AAC..."

	m4a_out="${aiff_out%.aiff}.m4a"

	if command -v ffmpeg >/dev/null 2>&1; then
		echo " Using ffmpeg..."

		ffmpeg -y -i "${aiff_out}" -ac 1 -ar 22050 -c:a aac -b:a 32k "${m4a_out}"
		convRC=$?
	else
		echo " ffmpeg not found, using afconvert fallback..."

		tmp_caf="${aiff_out%.aiff}.caf"

		afconvert "${aiff_out}" "${tmp_caf}" -f caff -d LEI16 -c 1 -r 22050
		rc1=$?

		if [[ ${rc1} -eq 0 ]]; then
			afconvert "${tmp_caf}" "${m4a_out}" -f m4af -d aac -b 32000
			convRC=$?
		else
			convRC=1
		fi

		rm -f "${tmp_caf}"
	fi

	if [[ ${convRC} -ne 0 ]]; then
		die "Conversion to m4a failed."
	fi

	if [[ ! -f "${m4a_out}" ]]; then
		die "Cannot find '${m4a_out}'."
	fi

	echo " Created:"
	echo " ${m4a_out}"
	echo ""
}

case "$mime" in
	application/msword|application/vnd.openxmlformats-officedocument.wordprocessingml.document)
		echo ""
		echo " OK: Microsoft Word document"
		main "${input_path}"
		;;
	*)
		die "Not a Microsoft Word document. Detected MIME type: ${mime}"
		;;
esac