import os

base_dir = r"d:\VIBE CODE\combat\src"
out_dir = r"d:\VIBE CODE\combat\installers"
os.makedirs(out_dir, exist_ok=True)

all_scripts = [
    ("CombatConfig", "ModuleScript", "game:GetService('ReplicatedStorage')", os.path.join(base_dir, "shared", "CombatConfig.luau")),
    ("CombatServerMaster", "Script", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "CombatServerMaster.luau")),
    ("TrainingDummySpawner", "Script", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "TrainingDummySpawner.luau")),
    ("StormWeaponServer", "Script", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "StormWeaponServer.luau")),
    ("StormCharacterMorphServer", "ModuleScript", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "StormCharacterMorphServer.luau")),
    ("LobbyManagerServer", "Script", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "LobbyManagerServer.luau")),
    ("StormCameraController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormCameraController.luau")),
    ("StormMovementController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormMovementController.luau")),
    ("TekkenDefenseController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "TekkenDefenseController.luau")),
    ("CombatComboController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "CombatComboController.luau")),
    ("StormRangedController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormRangedController.luau")),
    ("StormAssistController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormAssistController.luau")),
    ("StormAnimationController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormAnimationController.luau")),
    ("StormMatchHUD", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormMatchHUD.luau")),
    ("StormUltimateController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormUltimateController.luau")),
    ("MobileCombatHUD", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "MobileCombatHUD.luau")),
    ("PerformanceSettingsManager", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "PerformanceSettingsManager.luau")),
    ("StormCharacterSelectHUD", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormCharacterSelectHUD.luau")),
    ("StormSubstitutionController", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormSubstitutionController.luau")),
    ("GachaConfig", "ModuleScript", "game:GetService('ReplicatedStorage')", os.path.join(base_dir, "shared", "GachaConfig.luau")),
    ("GachaServerManager", "Script", "game:GetService('ServerScriptService')", os.path.join(base_dir, "server", "GachaServerManager.luau")),
    ("StormGachaHUD", "LocalScript", "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')", os.path.join(base_dir, "client", "StormGachaHUD.luau")),
]

for name, sType, parent, fpath in all_scripts:
    with open(fpath, "r", encoding="utf-8") as f:
        src = f.read()
    code = f"""local ex = {parent}:FindFirstChild('{name}')
if ex then ex:Destroy() end
local s = Instance.new('{sType}')
s.Name = '{name}'
s.Source = [=====[{src}]=====]
s.Parent = {parent}
return 'Installed {sType}: {name}'
"""
    out_file = os.path.join(out_dir, f"{name}.luau")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"Wrote {out_file}: {os.path.getsize(out_file)} bytes")

