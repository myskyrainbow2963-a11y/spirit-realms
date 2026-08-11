class_name StateStore
extends RefCounted

const REALMS := {
	"demon": {"name":"赤烬魔域", "subtitle":"赤月照临之地，万物以力量铭刻真名", "messenger":"烬罗", "messenger_art":"res://picture/Messenger1-Demon-solid.png", "egg_art":"res://picture/egg1-demon-solid-v2.png"},
	"celestial": {"name":"九霄仙界", "subtitle":"云海浮宫之间，灵息如星河流转", "messenger":"瑶华", "messenger_art":"res://picture/Messenger2-Celestial-clean.png", "egg_art":"res://picture/egg2-celestial-solid-v2.png"},
	"human": {"name":"烟火人界", "subtitle":"万家灯火之中，命运悄然生根", "messenger":"青衡", "messenger_art":"res://picture/Messenger3-human-anime-solid.png", "egg_art":"res://picture/egg3-human-solid-v2.png"},
	"underworld": {"name":"幽冥冥界", "subtitle":"忘川倒映月色，亡魂亦可缔结灵契", "messenger":"玄绡", "messenger_art":"res://picture/Messenger4-Underworld-solid.png", "egg_art":"res://picture/egg4-underworld-solid-v2.png"}
}

static var quest_accepted := false
static var active_realm := "demon"
static var egg_realm := ""
static var egg_started_unix := 0
static var training_skill := ""
static var hatch_reveal_pending := false
static var hatched_cards: Array[Dictionary] = []
static var ui_font_scale := 1.0
static var round_font := true
static var bold_font := true
static var ui_opacity := 0.92
static var object_opacity := 1.0
static var character_opacity := 1.0
static var blue_tone := 0.18
static var base_stats := {"智力": 50, "体力": 50, "灵力": 50, "魔力": 50, "耐力": 50}
static var admin_return_scene := "res://landing.tscn"

const CARD_ART_POOL := [
	"res://picture/card4.png", "res://picture/card5.png", "res://picture/card6.png",
	"res://picture/card17.png", "res://picture/card18.png", "res://picture/card19.png",
	"res://picture/card20.png", "res://picture/card21.png", "res://picture/card22.png",
	"res://picture/card23.png", "res://picture/card24.png", "res://picture/card25.png",
	"res://picture/card26.png", "res://picture/card27.png", "res://picture/card28.png",
	"res://picture/card29.png", "res://picture/card30.png", "res://picture/card31.png",
	"res://picture/card32.png", "res://picture/card33.png", "res://picture/card34.png",
	"res://picture/card35.png", "res://picture/card36.png", "res://picture/card37.png",
	"res://picture/card38.png", "res://picture/card39.png", "res://picture/card40.png",
	"res://picture/card41.png", "res://picture/card42.png", "res://picture/card43.png",
	"res://picture/card44.png", "res://picture/card45.png", "res://picture/card46.png",
	"res://picture/card47.png", "res://picture/card48.png", "res://picture/card49.png",
	"res://picture/card50.png", "res://picture/card51.png", "res://picture/card52.png",
	"res://picture/card53.png", "res://picture/card54.png", "res://picture/card55.png",
	"res://picture/card56.png", "res://picture/card57.png", "res://picture/card58.png",
	"res://picture/card59.png", "res://picture/card60.png", "res://picture/card61.png",
	"res://picture/card62.png", "res://picture/card63.png", "res://picture/card64.png",
	"res://picture/card65.png", "res://picture/card66.png", "res://picture/card67.png",
	"res://picture/card68.png"
]
const MAX_CARD_COLLECTION := 100

const TALENT_RULES := {
	"体力": {"key":"reflect", "label":"反弹", "min":20, "max":40, "unit":"%"},
	"魔力": {"key":"curse", "label":"诅咒", "min":120, "max":140, "unit":"%"},
	"灵力": {"key":"heal", "label":"治疗", "min":20, "max":40, "unit":"%"},
	"耐力": {"key":"endurance_boost", "label":"攻守成长", "min":0, "max":0, "unit":"%"},
	"智力": {"key":"intelligence_boost", "label":"智守成长", "min":0, "max":0, "unit":"%"}
}

static func font_for(base: Font) -> Font:
	var variation := FontVariation.new()
	variation.base_font = base
	if bold_font:
		variation.variation_embolden = 0.8
	return variation

static func realm() -> Dictionary:
	return REALMS.get(active_realm, REALMS["demon"])

static func receive_egg() -> void:
	egg_realm = active_realm
	egg_started_unix = 0
	training_skill = ""

static func start_training(skill: String) -> void:
	if not has_egg(): return
	training_skill = skill
	egg_started_unix = int(Time.get_unix_time_from_system())

static func complete_training_now() -> void:
	if not has_egg(): receive_egg()
	if training_skill == "": training_skill = "灵力"
	egg_started_unix = int(Time.get_unix_time_from_system()) - 86400
	hatch_reveal_pending = true

static func reveal_hatched_card() -> Dictionary:
	if hatched_cards.size() >= MAX_CARD_COLLECTION:
		hatch_reveal_pending = false
		return {"collection_full": true, "name": "灵契图鉴已满"}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var attack := rng.randi_range(18, 42)
	var defense := rng.randi_range(8, 28)
	var talent := _talent_for_skill(training_skill, rng)
	if talent.key == "endurance_boost":
		var endurance_attack_bonus := rng.randf_range(0.15, 0.25)
		var endurance_defense_bonus := rng.randf_range(0.05, 0.15)
		attack = int(round(float(attack) * (1.0 + endurance_attack_bonus)))
		defense = int(round(float(defense) * (1.0 + endurance_defense_bonus)))
		talent.attack_bonus = int(round(endurance_attack_bonus * 100.0))
		talent.defense_bonus = int(round(endurance_defense_bonus * 100.0))
	elif talent.key == "intelligence_boost":
		var intelligence_defense_bonus := rng.randf_range(0.15, 0.25)
		var intelligence_attack_bonus := rng.randf_range(0.05, 0.15)
		attack = int(round(float(attack) * (1.0 + intelligence_attack_bonus)))
		defense = int(round(float(defense) * (1.0 + intelligence_defense_bonus)))
		talent.attack_bonus = int(round(intelligence_attack_bonus * 100.0))
		talent.defense_bonus = int(round(intelligence_defense_bonus * 100.0))
	var data := {
		"id": "spirit_%d_%d" % [int(Time.get_unix_time_from_system()), rng.randi()],
		"name": "新生灵契",
		"art": CARD_ART_POOL[rng.randi_range(0, CARD_ART_POOL.size() - 1)],
		"skill": training_skill,
		"cost": 1,
		"attack": attack,
		"defense": defense,
		"talent": talent,
		"intelligence": rng.randi_range(35, 99),
		"vitality": rng.randi_range(35, 99),
		"spirit": rng.randi_range(35, 99),
		"magic": rng.randi_range(35, 99),
		"endurance": rng.randi_range(35, 99)
	}
	hatch_reveal_pending = false
	hatched_cards.append(data)
	egg_realm = ""
	egg_started_unix = 0
	training_skill = ""
	return data

static func _talent_for_skill(skill: String, rng: RandomNumberGenerator) -> Dictionary:
	var rule: Dictionary = TALENT_RULES.get(skill, {"key":"none", "label":"无", "min":0, "max":0, "unit":""})
	var value := 0
	if int(rule.min) > 0 or int(rule.max) > 0:
		value = rng.randi_range(int(rule.min), int(rule.max))
	return {
		"key": str(rule.key),
		"label": str(rule.label),
		"value": value,
		"unit": str(rule.unit)
	}

static func build_battle_deck() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var source: Array[Dictionary] = []
	for card in hatched_cards:
		source.append(_normalize_card(card.duplicate(true), rng))
	if source.is_empty():
		for i in 5:
			source.append(_fallback_card(i, rng))
	var deck: Array[Dictionary] = []
	var cursor := 0
	while deck.size() < 15:
		var base: Dictionary = source[cursor % source.size()].duplicate(true)
		base.deck_uid = "deck_%02d" % deck.size()
		deck.append(base)
		cursor += 1
	deck.shuffle()
	return deck

static func _normalize_card(card: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not card.has("name"):
		card.name = "新生灵契"
	if not card.has("art") or not ResourceLoader.exists(str(card.art)):
		card.art = CARD_ART_POOL[rng.randi_range(0, CARD_ART_POOL.size() - 1)]
	if not card.has("cost"):
		card.cost = 1
	if not card.has("attack"):
		card.attack = rng.randi_range(18, 42)
	if not card.has("defense"):
		card.defense = rng.randi_range(8, 28)
	if not card.has("talent"):
		card.talent = _talent_for_skill(str(card.get("skill", "灵力")), rng)
	return card

static func _fallback_card(index: int, rng: RandomNumberGenerator) -> Dictionary:
	var skills: Array[String] = ["智力", "体力", "灵力", "魔力", "耐力"]
	var skill: String = skills[index % skills.size()]
	var attack := rng.randi_range(18, 42)
	var defense := rng.randi_range(8, 28)
	var talent := _talent_for_skill(skill, rng)
	return {
		"id": "fallback_%d" % index,
		"name": "试炼灵契",
		"art": CARD_ART_POOL[rng.randi_range(0, CARD_ART_POOL.size() - 1)],
		"skill": skill,
		"cost": 1,
		"attack": attack,
		"defense": defense,
		"talent": talent,
		"intelligence": rng.randi_range(35, 99),
		"vitality": rng.randi_range(35, 99),
		"spirit": rng.randi_range(35, 99),
		"magic": rng.randi_range(35, 99),
		"endurance": rng.randi_range(35, 99)
	}

static func has_egg() -> bool:
	return egg_realm != ""

static func hatch_remaining() -> int:
	if not has_egg(): return 0
	if egg_started_unix <= 0: return 86400
	return max(0, 86400 - (int(Time.get_unix_time_from_system()) - egg_started_unix))

static func is_hatched() -> bool:
	return has_egg() and hatch_remaining() == 0

static func hatch_text() -> String:
	if not has_egg(): return "尚未获得灵兽蛋"
	if training_skill == "": return "待修炼 · 选择一项天赋后开始 24 小时孵化"
	if is_hatched(): return "孵化完成 · 前往灵契图鉴收录卡牌"
	var remain := hatch_remaining()
	return "%s 修炼中 · %02d:%02d:%02d 后苏醒" % [training_skill, remain / 3600, (remain % 3600) / 60, remain % 60]
