# mac-tts-reader

A simple command-line audiobook and narration generator for macOS.

`mac-tts-reader` converts Microsoft Word documents (`.doc` and `.docx`) into narrated audio using Apple's built-in Text-to-Speech engine (`say`), with customizable pronunciation mappings and automatic pause handling for more natural narration.

The project was originally written to generate audiobook drafts and proof-listening copies of novels and manuscripts directly from Word documents without requiring cloud services or paid narration software.

---

## Features

- Converts `.doc` and `.docx` files directly to plain text.
- Generates narrated audio using macOS system voices.
- Supports Apple's high-quality Premium voices.
- Produces compressed `.m4a` audiobook files.
- Custom pronunciation dictionary (`pronunc.tsv`).
- Automatically inserts pauses for:
  - Sentences
  - Paragraphs
  - Dialog
  - Ellipses
  - Exclamations
  - Scene breaks
- Case-preserving pronunciation replacements.
- Dependency checking and optional automatic installation of:
  - Homebrew
  - Python 3
  - FFmpeg
- Fully local processing. No internet or cloud services required.

---

## Requirements

### Supported Platform

- macOS only

This project relies on macOS-specific tools:

- `say`
- `textutil`
- `afconvert`

Linux and Windows are not supported.

### Additional Dependencies

The script can automatically install the following if they are missing:

- Homebrew
- Python 3
- FFmpeg

---

## Installation

Clone the repository:

```bash
git clone https://github.com/sajtu/mac-tts-reader.git
cd mac-tts-reader
```

Make the script executable:

```bash
chmod +x reader.bash
```

Optional: install into a global tools directory:

```bash
sudo mkdir -p /opt/tools
sudo cp reader.bash /opt/tools/
sudo cp pronunc.tsv /opt/tools/
sudo chmod +x /opt/tools/reader.bash
```

Add to your PATH:

```bash
echo 'export PATH="/opt/tools:$PATH"' >> ~/.zprofile
source ~/.zprofile
```

---

## Usage

Generate narration:

```bash
reader.bash myfile.docx
```

Or:

```bash
reader.bash /path/to/myfile.docx
```

---

## Output Files

The generated files are placed in the same directory as the source document.

Example:

```text
Novel.docx
Novel.txt
Novel_TTS.txt
Novel.aiff
Novel.m4a
```

| File | Description |
|------|-------------|
| `.txt` | Plain text extracted from the Word document |
| `_TTS.txt` | Processed text after pronunciation replacements and pause insertion |
| `.aiff` | Raw narration output from macOS TTS |
| `.m4a` | Final compressed audiobook |

---

## Pronunciation Dictionary

Pronunciation mappings are stored in:

```text
pronunc.tsv
```

Format:

```text
original<TAB>replacement
```

Example:

```text
AI      A I
GPU     G P U
SQL     sequel
Rong    Wrong
```

Notes:

- Use a real TAB character.
- Matching is case-insensitive.
- Longer matches are applied first.
- Replacement preserves capitalization.

Examples:

```text
gone    gaaawn
Gone    Gaaawn
GONE    GAAAWN
```

---

## Editing Pronunciations

```bash
reader.bash --edit
```

This opens the pronunciation file in `nano`.

---

## Testing Pronunciations

```bash
reader.bash --test
```

This reads every pronunciation entry aloud to quickly verify mappings.

---

## Voice Selection

The narrator voice is configured at the top of `reader.bash`:

```bash
SELECT_SAY_VOICE='Zoe (Premium)'
```

List installed voices:

```bash
say -v '?'
```

Install additional voices from:

```text
System Settings
→ Accessibility
→ Spoken Content
→ System Voice
```

Premium voices generally provide the best narration quality.

---

## Intended Use Cases

- Audiobook drafting
- Proof-listening manuscripts
- Listening to novels while commuting
- Accessibility and screen reading
- Generating narration from personal documents
- Testing dialog flow and pacing during editing

---

## Example run against document, example.docx

./reader.bash example.docx 

 Re-checking dependencies...

 Dependency check passed.


 OK: Microsoft Word document

 Converting '/Volumes/Desktop Sync/Projects/mac-tts-reader/example.docx' to plain text file,
 '/Volumes/Desktop Sync/Projects/mac-tts-reader/example.txt'...
 File converted successfully to '/Volumes/Desktop Sync/Projects/mac-tts-reader/example.txt'.

 Normalizing punctuation...
 Normalization complete.

 Applying pronunciation map...
 Wrote /Volumes/Desktop Sync/Projects/mac-tts-reader/example_TTS.txt
 TTS file created: '/Volumes/Desktop Sync/Projects/mac-tts-reader/example_TTS.txt'

 Generating narration for /Volumes/Desktop Sync/Projects/mac-tts-reader/example.docx...
 Successfully generated narration:
 /Volumes/Desktop Sync/Projects/mac-tts-reader/example.aiff

 Converting to m4a AAC...
 Using ffmpeg...
ffmpeg version 8.1 Copyright (c) 2000-2026 the FFmpeg developers
  built with Apple clang version 17.0.0 (clang-1700.6.4.2)
  configuration: --prefix=/opt/homebrew/Cellar/ffmpeg/8.1_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --host-cflags= --host-ldflags= --enable-ffplay --enable-gpl --enable-libsvtav1 --enable-libopus --enable-libx264 --enable-libmp3lame --enable-libdav1d --enable-libvmaf --enable-libvpx --enable-libx265 --enable-openssl --enable-videotoolbox --enable-audiotoolbox --enable-neon
  libavutil      60. 26.100 / 60. 26.100
  libavcodec     62. 28.100 / 62. 28.100
  libavformat    62. 12.100 / 62. 12.100
  libavdevice    62.  3.100 / 62.  3.100
  libavfilter    11. 14.100 / 11. 14.100
  libswscale      9.  5.100 /  9.  5.100
  libswresample   6.  3.100 /  6.  3.100
[aist#0:0/pcm_s16be @ 0x156204c40] Guessed Channel Layout: mono
Input #0, aiff, from '/Volumes/Desktop Sync/Projects/mac-tts-reader/example.aiff':
  Duration: 00:23:34.21, start: 0.000000, bitrate: 352 kb/s
  Stream #0:0: Audio: pcm_s16be (twos / 0x736F7774), 22050 Hz, mono, s16, 352 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (pcm_s16be (native) -> aac (native))
Press [q] to stop, [?] for help
Output #0, ipod, to '/Volumes/Desktop Sync/Projects/mac-tts-reader/example.m4a':
  Metadata:
    encoder         : Lavf62.12.100
  Stream #0:0: Audio: aac (LC) (mp4a / 0x6134706D), 22050 Hz, mono, fltp, 32 kb/s
    Metadata:
      encoder         : Lavc62.28.100 aac
[out#0/ipod @ 0x600000c4c000] video:0KiB audio:5185KiB subtitle:0KiB other streams:0KiB global headers:0KiB muxing overhead: 2.310972%
size=    5305KiB time=00:23:34.21 bitrate=  30.7kbits/s speed= 156x elapsed=0:00:09.06    
[aac @ 0x156104ed0] Qavg: 16953.834

---

## Limitations

- macOS only.
- Microsoft Word documents only.
- Not intended for commercial audiobook production.
- Narration quality depends on the installed macOS voice.

---

## License

MIT License.

See `LICENSE` for details.