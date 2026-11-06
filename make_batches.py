import os

base_dir = r"d:\VIBE CODE\combat\src"
out_dir = r"d:\VIBE CODE\combat"

batches = [
    {
        "file": os.path.join(out_dir, "batch1.luau"),
        "scripts": [
            {"name": "CombatConfig", "type": "ModuleScript", "parent": "game:GetService('ReplicatedStorage')", "file": os.path.join(base_dir, "shared", "CombatConfig.luau")},
            {"name": "CombatServerMaster", "type": "Script", "parent": "game:GetService('ServerScriptService')", "file": os.path.join(base_dir, "server", "CombatServerMaster.luau")},
            {"name": "TrainingDummySpawner", "type": "Script", "parent": "game:GetService('ServerScriptService')", "file": os.path.join(base_dir, "server", "TrainingDummySpawner.luau")},
            {"name": "StormWeaponServer", "type": "Script", "parent": "game:GetService('ServerScriptService')", "file": os.path.join(base_dir, "server", "StormWeaponServer.luau")},
        ]
    },
    {
        "file": os.path.join(out_dir, "batch2.luau"),
        "scripts": [
            {"name": "StormCharacterMorphServer", "type": "ModuleScript", "parent": "game:GetService('ServerScriptService')", "file": os.path.join(base_dir, "server", "StormCharacterMorphServer.luau")},
            {"name": "LobbyManagerServer", "type": "Script", "parent": "game:GetService('ServerScriptService')", "file": os.path.join(base_dir, "server", "LobbyManagerServer.luau")},
        ]
    },
    {
        "file": os.path.join(out_dir, "batch3.luau"),
        "scripts": [
            {"name": "StormCameraController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormCameraController.luau")},
            {"name": "StormMovementController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormMovementController.luau")},
            {"name": "TekkenDefenseController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "TekkenDefenseController.luau")},
            {"name": "CombatComboController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "CombatComboController.luau")},
            {"name": "StormRangedController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormRangedController.luau")},
        ]
    },
    {
        "file": os.path.join(out_dir, "batch4.luau"),
        "scripts": [
            {"name": "StormUltimateController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormUltimateController.luau")},
            {"name": "StormAssistController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormAssistController.luau")},
            {"name": "StormAnimationController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormAnimationController.luau")},
        ]
    },
    {
        "file": os.path.join(out_dir, "batch5.luau"),
        "scripts": [
            {"name": "StormMatchHUD", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormMatchHUD.luau")},
            {"name": "MobileCombatHUD", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "MobileCombatHUD.luau")},
            {"name": "PerformanceSettingsManager", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "PerformanceSettingsManager.luau")},
            {"name": "StormCharacterSelectHUD", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormCharacterSelectHUD.luau")},
            {"name": "StormSubstitutionController", "type": "LocalScript", "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", "file": os.path.join(base_dir, "client", "StormSubstitutionController.luau")},
        ]
    }
]

for idx, b in enumerate(batches):
    lines = []
    lines.append("local function install(name, sType, parent, src)")
    lines.append("    local ex = parent:FindFirstChild(name)")
    lines.append("    if ex then ex:Destroy() end")
    lines.append("    local s = Instance.new(sType)")
    lines.append("    s.Name = name")
    lines.append("    s.Source = src")
    lines.append("    s.Parent = parent")
    lines.append("    print('[Installed] ' .. sType .. ': ' .. name)")
    lines.append("end\n")

    for s in b["scripts"]:
        with open(s["file"], "r", encoding="utf-8") as f:
            src = f.read()
        lines.append("do")
        lines.append(f"    local src = [=====[{src}]=====]")
        lines.append(f"    install('{s['name']}', '{s['type']}', {s['parent']}, src)")
        lines.append("end\n")

    count = len(b["scripts"])
    lines.append(f"return 'Batch {idx+1} OK ({count} scripts)'")

    with open(b["file"], "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Wrote {b['file']}: {os.path.getsize(b['file'])} bytes")

