<#
.SYNOPSIS
  Sets up Ollama and a model for EngineerDESK Venture Studio (Venture AI).

.DESCRIPTION
  1. Installs Ollama if it is missing (winget, or a direct download as a fallback).
  2. Allows the Venture Studio page to talk to Ollama (OLLAMA_ORIGINS).
  3. Starts the Ollama server.
  4. Downloads the model.
  5. Opens the Venture Studio page.

.PARAMETER Model
  The model to download. Default: llama3.2

.PARAMETER Origins
  Value for OLLAMA_ORIGINS. Default: * (any page on this computer).
  Example of a stricter value: "http://localhost:8000"

.PARAMETER StartOnly
  Skip installing and downloading. Just start Ollama and open the page.

.PARAMETER NoOpen
  Do not open the page in your browser when finished.
#>
[CmdletBinding()]
param(
  [string]$Model = "llama3.2",
  [string]$Origins = "*",
  [switch]$StartOnly,
  [switch]$NoOpen
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Page = Join-Path $PSScriptRoot "engineerdesk-venture-studio.html"

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    $m" -ForegroundColor Green }
function Warn($m) { Write-Host "    $m" -ForegroundColor Yellow }

function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
}

function Find-Ollama {
  $cmd = Get-Command ollama -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $local = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
  if (Test-Path $local) { return $local }
  return $null
}

function Test-Server {
  try {
    Invoke-RestMethod "http://localhost:11434/api/tags" -TimeoutSec 2 | Out-Null
    return $true
  } catch {
    return $false
  }
}

try {
  Write-Host ""
  Write-Host "EngineerDESK Venture Studio - Venture AI setup" -ForegroundColor White

  # 1. Ollama
  Step "Checking for Ollama"
  $ollama = Find-Ollama

  if ($ollama) {
    Ok "Found Ollama at $ollama"
  } elseif ($StartOnly) {
    throw "Ollama is not installed yet. Run install.bat first."
  } else {
    Step "Installing Ollama"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $installed = $false

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
      Warn "Using winget. Accept any prompts that appear."
      winget install -e --id Ollama.Ollama --accept-package-agreements --accept-source-agreements
      if ($LASTEXITCODE -eq 0) { $installed = $true } else { Warn "winget did not finish. Trying a direct download instead." }
    }

    if (-not $installed) {
      $setup = Join-Path $env:TEMP "OllamaSetup.exe"
      Warn "Downloading the Ollama installer. This can take a few minutes."
      Invoke-WebRequest "https://ollama.com/download/OllamaSetup.exe" -OutFile $setup
      Start-Process -FilePath $setup -ArgumentList "/SILENT" -Wait
    }

    Refresh-Path
    $ollama = Find-Ollama
    if (-not $ollama) {
      throw "Ollama was installed but could not be found. Close this window, open a new one and run install.bat again."
    }
    Ok "Ollama installed."
  }

  # 2. Allow the page to connect
  Step "Allowing the Venture Studio page to connect to Ollama"
  [Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", $Origins, "User")
  $env:OLLAMA_ORIGINS = $Origins
  Ok "OLLAMA_ORIGINS = $Origins"

  # 3. Start the server (restart so the setting applies)
  Step "Starting Ollama"
  Get-Process | Where-Object { $_.ProcessName -like "ollama*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  Start-Process -FilePath $ollama -ArgumentList "serve" -WindowStyle Hidden

  $ready = $false
  for ($i = 0; $i -lt 30; $i++) {
    if (Test-Server) { $ready = $true; break }
    Start-Sleep -Seconds 1
  }
  if (-not $ready) { throw "Ollama did not start within 30 seconds." }
  Ok "Ollama is running at http://localhost:11434"

  # 4. Model
  if (-not $StartOnly) {
    Step "Downloading the model '$Model' (this can take several minutes)"
    & $ollama pull $Model
    if ($LASTEXITCODE -ne 0) {
      throw "Could not download '$Model'. Check your internet connection and the model name, then run install.bat again."
    }
    Ok "Model ready: $Model"
  }

  # 5. Open the page
  if (-not $NoOpen) {
    Step "Opening Venture Studio"
    if (Test-Path $Page) {
      Start-Process $Page
    } else {
      Warn "Could not find engineerdesk-venture-studio.html next to this script. Put them in the same folder."
    }
  }

  Write-Host ""
  Write-Host "All set." -ForegroundColor Green
  Write-Host "In Venture Studio: open Venture AI, then Ollama connection, then Test connection."
  Write-Host "Model name to use: $Model"
  Write-Host "Next time, double-click start.bat to launch everything."
}
catch {
  Write-Host ""
  Write-Host "Setup stopped: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
