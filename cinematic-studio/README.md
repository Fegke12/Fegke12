# Cinematic Studio — reference sources

This branch is a **temporary handoff workspace** for the Roblox cinematic-camera project. The repository's \`main\` branch is unchanged.

## Contents
- \`cinematic-studio/VehicleRig_V31_Reconstructed.lua\` — complete **reconstruction** of the working Vehicle Rig V3.1 design described in the ChatGPT conversation, including the critical ActiveTrack fix: camera position depends only on the *own vehicle*, never on the tracking target.
- \`cinematic-studio/HeadFreeCam_V51_Reconstructed.lua\` — complete **reconstruction** of the earlier Head FreeCam V5.1 design: low-speed horizontal camera, mouse/gamepad, cropping, smooth zoom, handheld modes and cleanup.
- \`cinematic-studio/INTEGRATION_NOTES.md\` — architecture and safety constraints for integrating both into FRAMEWORK.

### Important source-provenance note

The original complete code messages exist in the previous chat, but were not accessible as downloadable files in this GitHub upload workflow. **Neither source file here is a byte-for-byte archive of the user's tested scripts.** They are functional reconstructions for reference and require testing before replacement. The previously working VehicleRig V3.1 should remain the fallback.

### How to use with Work

Work can read this branch directly:
\`https://github.com/Fegke12/Fegke12/tree/cinematic-studio-sources/cinematic-studio\`

Use the scripts as source references for the modular CameraManager, FreeCamera and VehicleRig modules. Preserve existing behavior first; implement new UI on top. Do not claim the code is tested in the player's specific Roblox place.

### Note on platform rules

These camera scripts target client-side visual control. Hosting source code on GitHub, or receiving permission from a game's moderators, does not override Roblox's rules regarding unofficial executors or modified clients. For a permission-safe integration, have the place developer use Roblox Studio LocalScripts.
