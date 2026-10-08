class_name ArenaCatalog
extends RefCounted

const IDS: PackedStringArray = ["training", "courtyard", "konoha", "valley", "forest", "hideout", "ruins"]
const NAMES: PackedStringArray = ["Campo de treino", "Pátio ao entardecer", "Konoha • Distrito Uchiha", "Vale do Fim", "Floresta dos desafios", "Esconderijo subterrâneo", "Vila destruída"]

static func valid(id: String) -> bool:
    return id in IDS
