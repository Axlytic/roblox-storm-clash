# sync_studio.py
# Prepares Luau payload chunks for syncing src/ to Roblox Studio

import json
import os

studio_id = "29bff57e-28ab-47c2-a9ae-4a925a43d0e2"

files_to_sync = [
    # 1. ReplicatedStorage
    {"name": "GachaConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/GachaConfig.luau"},
    {"name": "CosmeticsConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/CosmeticsConfig.luau"},
    {"name": "RagdollHelper", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/RagdollHelper.luau"},
    {"name": "QuestConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/QuestConfig.luau"},

    # 2. ServerScriptService
    {"name": "GachaServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/GachaServerManager.luau"},
    {"name": "TrainingDummySpawner", "type": "Script", "parent": "ServerScriptService", "path": "src/server/TrainingDummySpawner.luau"},
    {"name": "QuestServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/QuestServerManager.luau"},
    {"name": "RagdollServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/RagdollServerManager.luau"},
    {"name": "LeaderboardServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/LeaderboardServerManager.luau"},
    {"name": "WaveSurvivalServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/WaveSurvivalServerManager.luau"},
    {"name": "CosmeticsServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/CosmeticsServerManager.luau"},
    {"name": "CombatServerMaster", "type": "Script", "parent": "ServerScriptService", "path": "src/server/CombatServerMaster.luau"},

    # 3. StarterPlayerScripts
    {"name": "StormDailyQuestHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormDailyQuestHUD.luau"},
    {"name": "StormTopbarHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormTopbarHUD.luau"},
    {"name": "StormFinisherController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormFinisherController.luau"},
    {"name": "StormBossHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormBossHUD.luau"},
    {"name": "StormCosmeticsHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormCosmeticsHUD.luau"},
    {"name": "StormGachaHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormGachaHUD.luau"},
    {"name": "StormCharacterSelectHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormCharacterSelectHUD.luau"},
    {"name": "CombatComboController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/CombatComboController.luau"},
]

os.makedirs("build_payloads", exist_ok=True)

for item in files_to_sync:
    with open(item["path"], "r", encoding="utf-8") as f:
        src = f.read()

    parent_expr = "game:GetService('ReplicatedStorage')" if item["parent"] == "ReplicatedStorage" else \
                  "game:GetService('ServerScriptService')" if item["parent"] == "ServerScriptService" else \
                  "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')"

    luau_code = f"""
local parent = {parent_expr}
local inst = parent:FindFirstChild('{item["name"]}')
if not inst then
    inst = Instance.new('{item["type"]}')
    inst.Name = '{item["name"]}'
    inst.Parent = parent
end
inst.Source = {json.dumps(src)}
return 'OK: {item["name"]} synced ({len(src)} bytes)'
"""
    out_file = f"build_payloads/{item['name']}.lua"
    with open(out_file, "w", encoding="utf-8") as out:
        out.write(luau_code.strip())

print(f"Generated {len(files_to_sync)} payload files in build_payloads/")
