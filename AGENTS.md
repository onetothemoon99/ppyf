# Project instructions for AI assistants

- After every change to this project (including Roblox Studio scripts or scene content), append a concise entry to `CHANGELOG.md` on the same turn.
- Include the date, what changed, and the relevant script or Studio location when known.
- State whether the change is only in Studio or has been published. Do not claim a publish unless it was confirmed.
- Keep inspection-only work out of the change log.
- At the start of a session on a new machine, read `PROJECT_MEMORY.md` first. It holds the notes about this game (systems, gotchas, status), so the code does not need to be re-explored.

## Backups (since 2026-11-11)

- Do not put backups in `ServerStorage` (or anywhere in the place). Every live server loads them, which costs RAM. On 2026-11-11, 123k backup instances were moved out.
- Before editing a script, save its full current `Source` to `backups/<ScriptName>_before_<change>_<YYYYMMDD>.lua`. Start the file with a comment that gives the Studio path and how to restore it.
  - Example: `backups/LevelSystem_before_curve2000_20261111.lua`.
- Before changing models or scene content, ask the user to right-click → Save to File into `backups/<Name>_before_<change>_<YYYYMMDD>.rbxm`. Studio MCP / Luau cannot write files.
  - If the user can't do it now, park a copy in `ServerStorage` only while you work. After it is saved to a file, delete it from the place in the same session.
- Write the backup path in the `CHANGELOG.md` entry.
- Old notes and script comments that point to `ServerStorage._Backup_*`, `_IslandKit_*`, `_IslandV5_Parked` and similar now mean `backups/ServerStorage_ARCHIVE_20261111.rbxm`.
  - To restore one: in Studio, right-click ServerStorage → Insert from File.
