# EngineerDESK Venture Studio

A venture-management workspace that runs entirely in your browser, with **Venture AI**, an assistant powered by [Ollama](https://ollama.com) running on your own computer. Nothing is sent to a cloud service.

## What's in this folder

| File | Purpose |
| --- | --- |
| `engineerdesk-venture-studio.html` | The app. Open it in any modern browser. |
| `install.bat` | One-click setup for Windows: installs Ollama, downloads the model, opens the app. |
| `install.ps1` | The PowerShell script that `install.bat` runs. |
| `start.bat` | Daily launcher: starts Ollama and opens the app. |
| `README.md` | This guide. |

Keep all the files in the same folder.

## Quick start (Windows)

1. Double-click **`install.bat`**.
2. Wait while it installs Ollama and downloads the model. The download is about 2 GB and can take several minutes.
3. The app opens in your browser. Select **Venture AI**, open **Ollama connection**, then select **Test connection**. You should see a status like "1 model found".
4. Type an idea into Venture AI to get a proposal. Approving it creates a draft venture with tasks and risks.

If Windows SmartScreen warns about the script, choose **More info**, then **Run anyway**. The script is plain text, so you can read it first.

**Next time:** double-click **`start.bat`**. It starts Ollama and opens the app, and doesn't download anything.

## What the installer does

1. Looks for Ollama. If missing, installs it with `winget`, or downloads the official installer from ollama.com if `winget` isn't available.
2. Sets the `OLLAMA_ORIGINS` environment variable so the app is allowed to talk to Ollama.
3. Restarts Ollama so the setting takes effect. This stops any Ollama that was already running.
4. Downloads the model (`ollama pull`).
5. Opens the app.

It doesn't need administrator rights and doesn't change anything outside your user account.

## Choosing a different model

Pass `-Model` when running the script from PowerShell:

```powershell
.\install.ps1 -Model qwen2.5:7b
```

| Model | Download | Memory (roughly) | Notes |
| --- | --- | --- | --- |
| `llama3.2:1b` | about 1.3 GB | 4 GB | Fastest, simplest proposals |
| `llama3.2` (default) | about 2 GB | 6 GB | Good balance for most computers |
| `qwen2.5:7b` | about 4.7 GB | 8 GB or more | Follows the proposal structure more reliably |
| `llama3.1:8b` | about 4.9 GB | 8 GB or more | Higher quality, slower without a GPU |

Sizes and memory needs are approximate. After installing a different model, type its exact name into **Venture AI, Ollama connection, Model** in the app.

## Manual setup

If you'd rather not use the script, run these in PowerShell:

```powershell
winget install -e --id Ollama.Ollama
$env:OLLAMA_ORIGINS = "*"
ollama serve
```

In a second PowerShell window:

```powershell
ollama pull llama3.2
```

Then open `engineerdesk-venture-studio.html`.

### macOS and Linux

The installer is Windows-only. Do it manually:

```bash
# macOS (Homebrew)               # Linux
brew install ollama               curl -fsSL https://ollama.com/install.sh | sh

OLLAMA_ORIGINS="*" ollama serve
ollama pull llama3.2
```

On macOS, if you use the Ollama menu bar app instead, run `launchctl setenv OLLAMA_ORIGINS "*"` and restart it.

## Your data

All ventures, ideas, tasks and other records are stored **in your browser** on this computer. Use **Settings, Your data** to back them up or move them to another browser. Clearing your browser's site data deletes them, so keep a backup.

## Security note

`OLLAMA_ORIGINS="*"` lets any web page you open in your browser send requests to Ollama on your computer. This is convenient and low risk on a personal machine, but you can tighten it by serving the app from a fixed address and allowing only that:

```powershell
cd path\to\this\folder
python -m http.server 8000
.\install.ps1 -Origins "http://localhost:8000" -NoOpen
```

Then browse to `http://localhost:8000/engineerdesk-venture-studio.html`.

## Troubleshooting

| Problem | What to try |
| --- | --- |
| **Test connection** says "Can't connect" | Run `start.bat`. Check that `http://localhost:11434` opens in your browser and says "Ollama is running". |
| It works in PowerShell but not in the app | The origin isn't allowed. Run `install.bat` again, which restarts Ollama with the setting. |
| The app is open from a claude.ai or other website link | A hosted page can't reach your computer. Open the downloaded `.html` file instead. |
| "The model isn't installed" | Run `ollama pull llama3.2`, or type a model you do have into the Model box and select **Test connection**. |
| Proposals are slow | A first request loads the model into memory, which can take a minute. Smaller models are faster. |
| Proposals are short or badly structured | Use a larger model such as `qwen2.5:7b`. |
| Port 11434 already in use | Another Ollama is running. Quit it from the system tray, then run `start.bat`. |
| `winget` isn't recognised | The script falls back to a direct download. You can also install Ollama from ollama.com/download. |
| Safari on Mac blocks the connection | Use Chrome, Edge or Firefox. |

## Uninstalling

1. Remove the setting: `[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", $null, "User")`
2. Remove models you no longer want: `ollama rm llama3.2`
3. Uninstall Ollama from **Settings, Apps** in Windows.
4. Delete this folder.
