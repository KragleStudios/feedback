if SERVER then AddCSLuaFile() end

fw.feedback = fw.feedback or {}
fw.feedback.cooldown = 15

fw.dep(CLIENT, "hook")
fw.dep(CLIENT, "fonts")

fw.include_sv "feedback_sv.lua"
fw.include_cl "feedback_cl.lua"
