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