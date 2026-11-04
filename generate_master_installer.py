import os

base_dir = r"d:\VIBE CODE\combat\src"
installer_out = r"d:\VIBE CODE\combat\MasterCombatInstaller.luau"

scripts = [
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

out = []
out.append("--!strict")
out.append("-- ============================================================")
out.append("-- ★ HYBRID ANIME COMBAT ENGINE: MASTER INSTALLER ★")
out.append("-- Pillars: Naruto Storm 4 (Camera/Movement/Assist) + Tekken (Defense/Parry) + MUGEN 14")
out.append("-- Jalankan script ini SEKALI di Command Bar Roblox Studio:")
out.append("-- Paste seluruh isi script ini ke Command Bar dan tekan Enter")
out.append("-- ============================================================\n")
out.append("local RS  = game:GetService('ReplicatedStorage')")
out.append("local SSS = game:GetService('ServerScriptService')")
out.append("local SPS = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')\n")

out.append("-- 1. Ensure CombatEvents folder and Remotes")
out.append("local combatEvents = RS:FindFirstChild('CombatEvents') :: Folder?")
out.append("if not combatEvents then")
out.append("    combatEvents = Instance.new('Folder')")
out.append("    combatEvents.Name = 'CombatEvents'")
out.append("    combatEvents.Parent = RS")
out.append("end\n")

out.append("local remoteNames = { 'NinjaDashEvent', 'SidestepEvent', 'BlockEvent', 'ParryEvent', 'AttackEvent', 'AssistEvent', 'LeaderSwapEvent' }")
out.append("for _, name in remoteNames do")
out.append("    if not combatEvents:FindFirstChild(name) then")
out.append("        local ev = Instance.new('RemoteEvent')")
out.append("        ev.Name = name")
out.append("        ev.Parent = combatEvents")
out.append("        print('[Installer] ✅ RemoteEvent created: ' .. name)")
out.append("    end")
out.append("end\n")

out.append("local function installScript(name: string, scriptType: string, parent: Instance, sourceCode: string)")
out.append("    local existing = parent:FindFirstChild(name)")
out.append("    if existing then existing:Destroy() end")
out.append("    local s = Instance.new(scriptType)")
out.append("    s.Name = name")
out.append("    s.Source = sourceCode")
out.append("    s.Parent = parent")
out.append("    print('[Installer] ✅ Installed ' .. scriptType .. ': ' .. name .. ' -> ' .. parent:GetFullName())")
out.append("end\n")

for s in scripts:
    with open(s["file"], "r", encoding="utf-8") as f:
        src = f.read()
    
    out.append(f"-- ============================================================")
    out.append(f"-- INSTALL: {s['name']} ({s['type']})")
    out.append(f"-- ============================================================")
    out.append(f"do")
    out.append(f"    local src = [=====[{src}]=====]")
    out.append(f"    installScript('{s['name']}', '{s['type']}', {s['parent']}, src)")
    out.append(f"end\n")

out.append("print('====================================================')")
out.append("print('🎉 [HYBRID COMBAT ENGINE v1.0] INSTALLED SUCCESSFULLY!')")
out.append("print('Controls:')")
out.append("print('  • Left-Click (M1): 4-Hit Attack Combo')")
out.append("print('  • Ctrl + M1: Low Shinobi Sweep')")
out.append("print('  • F (Hold): Standing High/Mid Guard')")
out.append("print('  • Ctrl + F (Hold): Crouched Low Guard')")
out.append("print('  • Just-Frame F (180ms): Tekken Perfect Parry Stagger Counter')")
out.append("print('  • Double-Tap A / D: Tekken 3D Sidestep Evasion')")
out.append("print('  • Double-Tap Space: Naruto Storm 4 Homing Ninja Dash')")
out.append("print('  • T: Summon Assist Partner (Jutsu Strike)')")
out.append("print('  • G: Storm 4 Leader Swap')")
out.append("print('  • Z: Toggle Dynamic Dual-Target Lock-On Camera')")
out.append("print('====================================================')")

with open(installer_out, "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("MasterCombatInstaller.luau generated successfully! Size:", os.path.getsize(installer_out))
