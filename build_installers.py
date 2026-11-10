import os

scripts = [
    {
        "src": "src/client/CombatComboController.luau",
        "dst": "installers/CombatComboController.luau",
        "name": "CombatComboController",
        "service": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "cls": "LocalScript"
    },
    {
        "src": "src/client/StormMovementController.luau",
        "dst": "installers/StormMovementController.luau",
        "name": "StormMovementController",
        "service": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "cls": "LocalScript"
    },
    {
        "src": "src/client/StormCameraController.luau",
        "dst": "installers/StormCameraController.luau",
        "name": "StormCameraController",
        "service": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "cls": "LocalScript"
    },
    {
        "src": "src/server/CombatServerMaster.luau",
        "dst": "installers/CombatServerMaster.luau",
        "name": "CombatServerMaster",
        "service": "game:GetService('ServerScriptService')",
        "cls": "Script"
    },
    {
        "src": "src/client/StormAnimationController.luau",
        "dst": "installers/StormAnimationController.luau",
        "name": "StormAnimationController",
        "service": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "cls": "LocalScript"
    },
    {
        "src": "src/client/MobileCombatHUD.luau",
        "dst": "installers/MobileCombatHUD.luau",
        "name": "MobileCombatHUD",
        "service": "game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')",
        "cls": "LocalScript"
    },
    {
        "src": "src/server/TrainingDummySpawner.luau",
        "dst": "installers/TrainingDummySpawner.luau",
        "name": "TrainingDummySpawner",
        "service": "game:GetService('ServerScriptService')",
        "cls": "Script"
    }
]

os.makedirs("installers", exist_ok=True)

for item in scripts:
    with open(item["src"], "r", encoding="utf-8") as f:
        src_code = f.read()

    template = f"""local ex = {item['service']}:FindFirstChild('{item['name']}')
if ex then ex:Destroy() end
local s = Instance.new('{item['cls']}')
s.Name = '{item['name']}'
s.Source = [=====[{src_code}]=====]
s.Parent = {item['service']}
return 'Installed {item['cls']}: {item['name']}'
"""
    with open(item["dst"], "w", encoding="utf-8") as f:
        f.write(template)
    print(f"Generated {item['dst']} ({len(template)} bytes)")
