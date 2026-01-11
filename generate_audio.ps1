# ElevenLabs Audio Generator
# Generates MP3 audio from text files using ElevenLabs TTS API
# See README.md for usage instructions

param(
    [switch]$TestMode,      # Only process demo_hello.txt
    [string]$SingleFile,    # Process a specific file
    [string]$Pattern = "*.txt"  # File pattern to process
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_FILE = Join-Path $SCRIPT_DIR "config.env"

# Load configuration from config.env
function Load-Config {
    if (-not (Test-Path $CONFIG_FILE)) {
        Write-Host "[ERROR] config.env not found! Please create it from the template." -ForegroundColor Red
        Write-Host "Required settings: API_KEY, VOICE_ID" -ForegroundColor Yellow
        exit 1
    }
    
    $config = @{}
    Get-Content $CONFIG_FILE | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.+)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $config[$key] = $value
        }
    }
    
    # Validate required settings
    if (-not $config["API_KEY"] -or $config["API_KEY"] -eq "YOUR_API_KEY_HERE") {
        Write-Host "[ERROR] API_KEY not set in config.env!" -ForegroundColor Red
        exit 1
    }
    if (-not $config["VOICE_ID"] -or $config["VOICE_ID"] -eq "YOUR_VOICE_ID_HERE") {
        Write-Host "[ERROR] VOICE_ID not set in config.env!" -ForegroundColor Red
        exit 1
    }
    
    # Set defaults
    if (-not $config["MODEL_ID"]) { $config["MODEL_ID"] = "eleven_v3" }
    if (-not $config["LANGUAGE_CODE"]) { $config["LANGUAGE_CODE"] = "en" }
    if (-not $config["OUTPUT_FORMAT"]) { $config["OUTPUT_FORMAT"] = "mp3_44100_128" }
    
    return $config
}

# Generate audio for a single file
function Generate-Audio {
    param(
        [string]$TxtFilePath,
        [hashtable]$Config
    )
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($TxtFilePath)
    $outputPath = Join-Path $SCRIPT_DIR "$fileName.mp3"
    
    # Read transcript
    $transcript = Get-Content -Path $TxtFilePath -Raw
    $transcript = $transcript.Trim()
    
    if ([string]::IsNullOrWhiteSpace($transcript)) {
        Write-Host "  [SKIP] Empty file: $fileName" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  Processing: $fileName" -ForegroundColor Cyan
    Write-Host "    Text: $transcript"
    
    # Create temporary JSON file
    $jsonPath = Join-Path $SCRIPT_DIR "_temp_request.json"
    $jsonBody = @{
        text           = $transcript
        model_id       = $Config["MODEL_ID"]
        language_code  = $Config["LANGUAGE_CODE"]
        voice_settings = @{
            stability         = 0.5
            similarity_boost  = 0.75
            style             = 0.5
            use_speaker_boost = $true
        }
    } | ConvertTo-Json -Depth 3 -Compress
    
    Set-Content -Path $jsonPath -Value $jsonBody -NoNewline
    
    # API URL
    $API_URL = "https://api.elevenlabs.io/v1/text-to-speech/$($Config['VOICE_ID'])"
    
    try {
        $curlArgs = @(
            "-s",
            "-X", "POST",
            "$API_URL`?output_format=$($Config['OUTPUT_FORMAT'])",
            "-H", "xi-api-key: $($Config['API_KEY'])",
            "-H", "Content-Type: application/json",
            "-d", "@$jsonPath",
            "-o", $outputPath
        )
        
        & curl.exe @curlArgs 2>&1 | Out-Null
        
        if (Test-Path $outputPath) {
            $fileSize = (Get-Item $outputPath).Length
            if ($fileSize -gt 1000) {
                Write-Host "    [SUCCESS] Created: $fileName.mp3 ($fileSize bytes)" -ForegroundColor Green
                Remove-Item -Path $jsonPath -Force -ErrorAction SilentlyContinue
                return $true
            }
            else {
                $content = Get-Content -Path $outputPath -Raw -ErrorAction SilentlyContinue
                if ($content -match "error|detail") {
                    Write-Host "    [ERROR] API Error: $content" -ForegroundColor Red
                    Remove-Item -Path $outputPath -Force -ErrorAction SilentlyContinue
                }
                return $false
            }
        }
        else {
            Write-Host "    [ERROR] File not created" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "    [ERROR] Failed: $_" -ForegroundColor Red
        return $false
    }
    finally {
        Remove-Item -Path $jsonPath -Force -ErrorAction SilentlyContinue
    }
}

# Main execution
$config = Load-Config

Write-Host "`n=== ElevenLabs Audio Generator ===" -ForegroundColor Magenta
Write-Host "Model:    $($config['MODEL_ID'])"
Write-Host "Voice:    $($config['VOICE_ID'])"
Write-Host "Language: $($config['LANGUAGE_CODE'])"
Write-Host "Format:   $($config['OUTPUT_FORMAT'])"
Write-Host ""

$successCount = 0
$failCount = 0

if ($TestMode) {
    Write-Host "TEST MODE: Processing demo_hello.txt`n" -ForegroundColor Yellow
    $testFile = Join-Path $SCRIPT_DIR "demo_hello.txt"
    if (Test-Path $testFile) {
        if (Generate-Audio -TxtFilePath $testFile -Config $config) { $successCount++ } else { $failCount++ }
    }
    else {
        Write-Host "Demo file not found: $testFile" -ForegroundColor Red
    }
}
elseif ($SingleFile) {
    Write-Host "SINGLE FILE: Processing $SingleFile`n" -ForegroundColor Yellow
    $filePath = Join-Path $SCRIPT_DIR $SingleFile
    if (Test-Path $filePath) {
        if (Generate-Audio -TxtFilePath $filePath -Config $config) { $successCount++ } else { $failCount++ }
    }
    else {
        Write-Host "File not found: $filePath" -ForegroundColor Red
    }
}
else {
    Write-Host "BATCH MODE: Processing all $Pattern files`n" -ForegroundColor Yellow
    $txtFiles = Get-ChildItem -Path $SCRIPT_DIR -Filter $Pattern | 
                Where-Object { $_.Name -notmatch "^(README|config)" } |
                Sort-Object Name
    $total = $txtFiles.Count
    $current = 0
    
    foreach ($file in $txtFiles) {
        $current++
        Write-Host "[$current/$total]" -NoNewline
        if (Generate-Audio -TxtFilePath $file.FullName -Config $config) { $successCount++ } else { $failCount++ }
        Start-Sleep -Milliseconds 800
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Magenta
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Failed:  $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
