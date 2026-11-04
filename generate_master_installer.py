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
        "name": "StormWeaponServer",
        "type": "Script",
        "parent": "game:GetService('ServerScriptService')",
        "file": os.path.join(base_dir, "server", "StormWeaponServer.luau")
    },
    {
        "name": "StormCharacterMorphServer",
        "type": "ModuleScript",
        "parent": "game:GetService('ServerScriptService')",
        "file": os.path.join(base_dir, "server", "StormCharacterMorphServer.luau")
    },
    {
        "name": "LobbyManagerServer",
        "type": "Script",
        "parent": "game:GetService('ServerScriptService')",
        "file": os.path.join(base_dir, "server", "LobbyManagerServer.luau")
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
        "name": "StormRangedController",
        "type": "LocalScript",
        "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "file": os.path.join(base_dir, "client", "StormRangedController.luau")
    },
    {
        "name": "StormAssistController",
        "type": "LocalScript",
        "parent": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "file": os.path.join(base_dir, "client", "StormAssistController.luau")
    },
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

out = []
out.append("--!strict")
out.append("-- ============================================================")
out.append("-- ★ STORM CLASH: HYBRID ANIME COMBAT ENGINE (v2.0) ★")
out.append("-- Pillars: Naruto Storm 4 + Tekken + MUGEN 14")
out.append("-- Controls: WASD (Move) + IJKL (Combat) + Mobile Touch + Gamepad")
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

out.append("local remoteNames = { 'NinjaDashEvent', 'SidestepEvent', 'BlockEvent', 'ParryEvent', 'AttackEvent', 'AssistEvent', 'LeaderSwapEvent', 'UltimateEvent', 'WeaponStanceEvent' }")
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
out.append("print('🎉 [STORM CLASH v2.0] INSTALLED SUCCESSFULLY!')")
out.append("print('Controls (PC / Laptop):')")
out.append("print('  • W, A, S, D: Orbital Movement & 3D Strafing')")
out.append("print('  • J / Left-Click: 4-Hit Attack Combo String')")
out.append("print('  • S + J: Low Shinobi Sweep (Pierces High Guard)')")
out.append("print('  • K / F (Hold): Standing High/Mid Guard')")
out.append("print('  • S + K (Hold): Crouched Low Guard')")
out.append("print('  • Just-Frame K (180ms): Tekken Perfect Parry Stagger Counter')")
out.append("print('  • L / Double-Tap Space: Naruto Storm 4 Homing Ninja Dash')")
out.append("print('  • Double-Tap A / D: Tekken 3D Sidestep Evasion')")
out.append("print('  • I / T: Summon Assist Partner (Jutsu Projectile Strike)')")
out.append("print('  • U / G: Storm 4 Leader Swap')")
out.append("print('  • O: Ultimate Secret Technique (Cinematic Finisher when Chakra=100%)')")
out.append("print('  • C: Charge Chakra / Energy (Hold to Charge)')")
out.append("print('  • Z: Toggle Dynamic Dual-Target Lock-On Camera')")
out.append("print('  • Tekken Awakening / Rage: Auto-triggers when HP < 30% (+25% Damage Boost)')")
out.append("print('Multi-Platform & Worldwide Features:')")
out.append("print('  • ⚔️ Procedural Anime Katana Model with Glowing Slash Trail')")
out.append("print('  • 🥋 100% Asset-Independent Procedural Anime Motor6D Combat Animations')")
out.append("print('  • 📊 Storm 4 Dual Top Fighting Healthbars & 99s Round Announcer')")
out.append("print('  • 📱 Mobile Touch Controls HUD (Right-Thumb Action Cluster)')")
out.append("print('  • 🎮 Gamepad Support (PlayStation & Xbox Controller)')")
out.append("print('  • ⚡ Low-GFX / 60FPS Performance Mode Toggle')")
out.append("print('====================================================')")

with open(installer_out, "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("MasterCombatInstaller.luau generated successfully! Size:", os.path.getsize(installer_out))
