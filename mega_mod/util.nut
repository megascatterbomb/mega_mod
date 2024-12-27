function MM_GetEntByName(name) {
    return Entities.FindByName(null, name);
}

function MM_GetEntArrayByName(name) {
    local ents = [];
    local ent = Entities.FindByName(null, name);
    while(ent != null) {
        ents.push(ent);
        ent = Entities.FindByName(ent, name);
    }
    return ents;
}

// Entity optimization
function MM_KillAllByName(name) {
    local killed = 0;
    local ents = MM_GetEntArrayByName(name);
    foreach (ent in ents) {
        ent.Kill();
        killed++;
    }
    return killed;
}

function MM_KillAllButOneByName(name) {
    local killed = 0;
    local ents = MM_GetEntArrayByName(name);
    local skip = true;
    foreach (ent in ents) {
        if(!skip && ent) {
            ent.Kill();
            killed++;
        }
        skip = false;
    }
    return killed;
}

// Create thinks that aren't attached to any particular entity
function MM_CreateDummyThink(funcName) {
    local relay = Entities.CreateByClassname("logic_relay");
    AddThinkToEnt(relay, funcName);
}