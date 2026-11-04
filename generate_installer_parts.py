import os

base_dir = r"d:\VIBE CODE\combat\src"
out_dir = r"d:\VIBE CODE\combat"

parts = [
    {
        "file": os.path.join(out_dir, "installer_part1.luau"),
        "scripts": [
            {
                "name": "CombatConfig",
                "type": "ModuleScript",
                "parent": "game:GetService('ReplicatedStorage')",
                "file": os.path.join(base_dir, "shared", "CombatConfig.luau")
            },
            {
                "name": "CombatServerMaster",
                "type": "Script",
                "parent": "game:GetService('ServerScriptService')",
                "file": os.path.join(base_dir, "server", "CombatServerMaster.luau")
            },
            {
                "name": "TrainingDummySpawner",
                "type": "Script",
                "parent": "game:GetService('ServerScriptService')",
                "file": os.path.join(base_dir, "server", "TrainingDummySpawner.luau")
            },
            {
                "name": "StormWeaponServer",
                "type": "Script",
                "parent": "game:GetService('ServerScriptService')",
                "file": os.path.join(base_dir, "server", "StormWeaponServer.luau")
            },
            {
                "name": "LobbyManagerServer",
                "type": "Script",
                "parent": "game:GetService('ServerScriptService')",
                "file": os.path.join(base_dir, "server", "LobbyManagerServer.luau")
            },
        ]
    },
    {
        "file": os.path.join(out_dir, "installer_part2.luau"),
        "scripts": [
            {
                "name": "StormCameraController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormCameraController.luau")
            },
            {
                "name": "StormMovementController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormMovementController.luau")
            },
            {
                "name": "TekkenDefenseController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "TekkenDefenseController.luau")
            },
            {
                "name": "CombatComboController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "CombatComboController.luau")
            },
            {
                "name": "StormAssistController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormAssistController.luau")
            },
        ]
    },
    {
        "file": os.path.join(out_dir, "installer_part3.luau"),
        "scripts": [
            {
                "name": "StormAnimationController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormAnimationController.luau")
            },
            {
                "name": "StormMatchHUD",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormMatchHUD.luau")
            },
            {
                "name": "StormUltimateController",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormUltimateController.luau")
            },
            {
                "name": "MobileCombatHUD",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "MobileCombatHUD.luau")
            },
            {
                "name": "PerformanceSettingsManager",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "PerformanceSettingsManager.luau")
            },
            {
                "name": "StormCharacterSelectHUD",
                "type": "LocalScript",
                "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
                "file": os.path.join(base_dir, "client", "StormCharacterSelectHUD.luau")
            },
        ]
    }
]

for idx, p in enumerate(parts):
    out = []
    out.append("local function installScript(name: string, scriptType: string, parent: Instance, sourceCode: string)")
    out.append("    local existing = parent:FindFirstChild(name)")
    out.append("    if existing then existing:Destroy() end")
    out.append("    local s = Instance.new(scriptType)")
    out.append("    s.Name = name")
    out.append("    s.Source = sourceCode")
    out.append("    s.Parent = parent")
    out.append("    print('[Installer] Installed ' .. scriptType .. ': ' .. name)")
    out.append("end\n")

    for s in p["scripts"]:
        with open(s["file"], "r", encoding="utf-8") as f:
            src = f.read()
        out.append(f"do")
        out.append(f"    local src = [=====[{src}]=====]")
        out.append(f"    installScript('{s['name']}', '{s['type']}', {s['parent']}, src)")
        out.append(f"end\n")
    
    out.append(f"return 'Part {idx+1} Installed Successfully ({len(p['scripts'])} scripts)'")

    with open(p["file"], "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(f"Generated {p['file']} size: {os.path.getsize(p['file'])}")

