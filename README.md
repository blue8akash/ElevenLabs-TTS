# ElevenLabs Audio Generator

Generate MP3 audio files from text scripts using [ElevenLabs](https://elevenlabs.io) Text-to-Speech API.

## Quick Start

1. **Get ElevenLabs API Key**
   - Sign up at [elevenlabs.io](https://elevenlabs.io)
   - Go to Settings → API Keys
   - Copy your API key

2. **Configure Settings**
   - Edit `config.env` with your:
     - `API_KEY` - Your ElevenLabs API key
     - `VOICE_ID` - Voice to use (find in Voice Library)
     - `LANGUAGE_CODE` - Language (e.g., `en`, `hi`)

3. **Create Script Files**
   - Create `.txt` files with your text/scripts
   - Optionally add [v3 emotion tags](#v3-emotion-tags)
   - Example: `greeting.txt` containing `[soft, warm] Hello and welcome`

4. **Generate Audio**
   ```powershell
   # Generate all .txt files in current folder
   .\generate_audio.ps1
   
   # Generate specific file
   .\generate_audio.ps1 -SingleFile "greeting.txt"
   
   # Test mode (V001.txt only)
   .\generate_audio.ps1 -TestMode
   ```

## V3 Emotion Tags

ElevenLabs v3 model supports emotion/style tags in square brackets:

| Tag | Effect |
|-----|--------|
| `[slowly]` | Slower delivery |
| `[soft]` | Softer voice |
| `[gentle]` | Gentle tone |
| `[calm]` | Calm delivery |
| `[excited]` | Energetic |
| `[whispers]` | Whispered |

**Combine tags:** `[slowly] [soft, peaceful] Your text here`

## Configuration Options

Edit `config.env`:

| Setting | Description | Example |
|---------|-------------|---------|
| `API_KEY` | ElevenLabs API key | `sk_xxxx...` |
| `VOICE_ID` | Voice identifier | `2zRM7PkgwBPiau2jvVXc` |
| `MODEL_ID` | TTS Model | `eleven_v3` |
| `LANGUAGE_CODE` | ISO 639-1 code | `en`, `hi`, `es` |
| `OUTPUT_FORMAT` | Audio quality | `mp3_44100_128` |

## Supported Models

| Model | Best For |
|-------|----------|
| `eleven_v3` | Emotional, expressive (recommended) |
| `eleven_multilingual_v2` | Consistent quality |
| `eleven_flash_v2_5` | Fast generation |
| `eleven_turbo_v2_5` | Low latency |

## Supported Languages

70+ languages including: English, Hindi, Spanish, French, German, Japanese, Chinese, and more.

See full list: [ElevenLabs Models](https://elevenlabs.io/docs/overview/models)

## File Structure

```
project/
├── config.env           # Your settings (edit this!)
├── generate_audio.ps1   # Main generation script
├── README.md            # This file
├── script1.txt          # Your text scripts
├── script2.txt
└── *.mp3                # Generated audio files
```

## Demo Files

- `demo_hello.txt` - Simple greeting example
- `demo_meditation.txt` - Meditation with emotion tags
