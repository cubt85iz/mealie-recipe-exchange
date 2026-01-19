# Mealie Recipe Exchange

This project automates **exporting** and **importing** recipes between a Mealie instance and a local directory. It is designed for administrators who want reliable, unattended synchronization of Mealie recipes—useful for backups, Git‑based versioning, or multi‑node sharing.

The system uses:

- A shell script to **export** recipes from Mealie to JSON files  
- A shell script to **import/update** recipes into Mealie  
- systemd **path units** to detect new/modified recipe files  
- systemd **timer units** to run nightly exports  
- systemd **service units** to ensure serialized, queued processing  

This README explains how everything works and how to deploy it on a Linux system.

---

## 1. How the System Works

### Export Workflow (Nightly Backup)

1. A systemd **timer** triggers `mealie-recipe-export.service` nightly.
2. The service runs `mealie-export-recipes.sh`, which:
   - Connects to the Mealie API
   - Retrieves all recipes
   - Exports each recipe as a normalized JSON file
   - Writes only changed or new recipes to disk (based on checksums)
3. JSON files are stored in the directory defined by `MEALIE_EXPORT_DIR`.

### Import Workflow (Real‑Time Sync)

1. A systemd **path unit** watches one or more directories (e.g., `/var/recipes`) for:
   - New JSON files  
   - Modified JSON files  
2. When a change occurs, systemd triggers `mealie-recipe-import.service`.
3. The service runs `mealie-import-or-update-recipe.sh`, which:
   - Reads the recipe JSON
   - Extracts the recipe slug
   - Checks if the recipe already exists in Mealie
   - **Updates** the recipe if it exists  
   - **Creates** a new recipe if it does not  

Systemd ensures **queueing**, so even if many files change at once, they are processed sequentially and safely.

---

## 2. Requirements

- Linux system with systemd
- Bash
- `curl`
- `jq`
- A running Mealie instance
- A Mealie API token with recipe read/write permissions

---

## 3. Installation

### Step 1 — Clone the Repository

```bash
git clone https://github.com/cubt85iz/mealie-recipe-exchange
cd mealie-recipe-exchange
```

### Step 2 — Install Scripts

Copy the scripts into a system-wide location:

```bash
sudo cp mealie-export-recipes.sh /usr/local/bin/
sudo cp mealie-import-or-update-recipe.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/mealie-export-recipes.sh
sudo chmod +x /usr/local/bin/mealie-import-or-update-recipe.sh
```

---

## 4. Configure Systemd Units

Create a file to store the export variables for `mealie-recipe-export.service`:

```bash
sudo nano /etc/systemd/system/mealie-recipe-export.service.d/variables.conf
```

Add:

```ini
[Service]
Environment=MEALIE_URL="https://your-mealie-instance"
Environment=MEALIE_API_TOKEN="your-api-token"
Environment=MEALIE_EXPORT_DIR="your-recipes-directory"
```

Save and exit.

Create a file to store the import variables for `mealie-recipe-import.service`:

```bash
sudo nano /etc/systemd/system/mealie-recipe-import.service.d/variables.conf
```

Add:

```ini
[Service]
Environment=MEALIE_URL="https://your-mealie-instance"
Environment=MEALIE_API_TOKEN="your-api-token"
```

Save and exit.

Create a file to store the monitored paths for `mealie-recipe-import.path`:

```bash
sudo nano /etc/systemd/system/mealie-recipe-export.service.d/paths.conf
```

Add:

```ini
[Path]
PathModified="your-monitored-path/*.json"
PathModified="your-other-monitored-path/*.json"
```

Save and exit.

---

## 5. Directory Setup

Ensure the export/import directory exists:

```bash
sudo mkdir -p your-monitored-and-export-directories
```

---

## 6. Install systemd Units

Copy the provided unit files:

```bash
sudo cp mealie-recipe-export.service /etc/systemd/system/
sudo cp mealie-recipe-export.timer /etc/systemd/system/
sudo cp mealie-recipe-import.service /etc/systemd/system/
sudo cp mealie-recipe-import.path /etc/systemd/system/
```

Reload systemd:

```bash
sudo systemctl daemon-reload
```

---

## 7. Validate systemd Units

Execute the provide commands and validate the the values provided in the configuration files are present.

```bash
sudo systemctl cat mealie-recipe-export.service
sudo systemctl cat mealie-recipe-import.service
sudo systemctl cat mealie-recipe-import.path
```

---

## 8. Enable and Start the Import Watcher

```bash
sudo systemctl enable --now mealie-recipe-import.path
```

This begins monitoring your monitored directories for new or modified JSON files.

---

## 9. Enable and Start the Nightly Export Timer

```bash
sudo systemctl enable --now mealie-recipe-export.timer
```

You can check the timer:

```bash
systemctl status mealie-recipe-export.timer
```

Run an export manually:

```bash
sudo systemctl start mealie-recipe-export.service
```

---

## 10. Troubleshooting

### Check logs for import events

```bash
journalctl -u mealie-recipe-import.service -f
```

### Check logs for export events

```bash
journalctl -u mealie-recipe-export.service -f
```

### Verify path unit is watching

```bash
systemctl status mealie-recipe-import.path
```

---

## 11. Summary

This project provides:

- **Automated nightly exports** of all Mealie recipes  
- **Real‑time import/update** of recipes when JSON files change  
- **Checksum‑based change detection** to avoid unnecessary writes  
- **systemd queueing** to ensure safe, serialized processing  
- A simple, administrator‑friendly setup  

It is ideal for:

- Backups  
- GitOps workflows  
- Multi‑server synchronization  
- Recipe sharing between environments  
