# sync_studio.py
# Prepares Luau payload chunks for syncing src/ to Roblox Studio

import json
import os

studio_id = "606a55e2-7d88-4d6f-80e6-dd6903a47a2d"

files_to_sync = [
    # 1. ReplicatedStorage
    {"name": "GachaConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/GachaConfig.luau"},
    {"name": "CosmeticsConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/CosmeticsConfig.luau"},
    {"name": "RagdollHelper", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/RagdollHelper.luau"},
    {"name": "QuestConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/QuestConfig.luau"},
    {"name": "SoundConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/SoundConfig.luau"},
    {"name": "DuelConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/DuelConfig.luau"},
    {"name": "CombatConfig", "type": "ModuleScript", "parent": "ReplicatedStorage", "path": "src/shared/CombatConfig.luau"},

    # 2. ServerScriptService
    {"name": "GachaServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/GachaServerManager.luau"},
    {"name": "TrainingDummySpawner", "type": "Script", "parent": "ServerScriptService", "path": "src/server/TrainingDummySpawner.luau"},
    {"name": "QuestServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/QuestServerManager.luau"},
    {"name": "RagdollServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/RagdollServerManager.luau"},
    {"name": "LeaderboardServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/LeaderboardServerManager.luau"},
    {"name": "WaveSurvivalServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/WaveSurvivalServerManager.luau"},
    {"name": "CosmeticsServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/CosmeticsServerManager.luau"},
    {"name": "CombatServerMaster", "type": "Script", "parent": "ServerScriptService", "path": "src/server/CombatServerMaster.luau"},
    {"name": "DuelServerManager", "type": "Script", "parent": "ServerScriptService", "path": "src/server/DuelServerManager.luau"},

    # 3. StarterPlayerScripts
    {"name": "StormDailyQuestHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormDailyQuestHUD.luau"},
    {"name": "StormTopbarHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormTopbarHUD.luau"},
    {"name": "StormFinisherController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormFinisherController.luau"},
    {"name": "StormBossHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormBossHUD.luau"},
    {"name": "StormCosmeticsHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormCosmeticsHUD.luau"},
    {"name": "StormGachaHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormGachaHUD.luau"},
    {"name": "StormCharacterSelectHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormCharacterSelectHUD.luau"},
    {"name": "CombatComboController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/CombatComboController.luau"},
    {"name": "StormAudioController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormAudioController.luau"},
    {"name": "StormDuelHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormDuelHUD.luau"},
    {"name": "StormCameraController", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/StormCameraController.luau"},
    {"name": "MobileCombatHUD", "type": "LocalScript", "parent": "StarterPlayerScripts", "path": "src/client/MobileCombatHUD.luau"},
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
inst.Source = {json.dumps(src, ensure_ascii=False)}
return 'OK: {item["name"]} synced ({len(src)} bytes)'
"""
    out_file = f"build_payloads/{item['name']}.lua"
    with open(out_file, "w", encoding="utf-8") as out:
        out.write(luau_code.strip())

print(f"Generated {len(files_to_sync)} payload chunks in build_payloads/")
