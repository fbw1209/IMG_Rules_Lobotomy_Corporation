extends SigilEffect
# 压制（光环）：本卡在场上时，敌方所有卡牌攻击力 -1；本卡离场后还原。
# 新上场的敌人也会被压制。记录存在卡的 meta 上，进化时按进化目标决定是否继续。

const META_KEY = "pressure_suppressed"
const SIGIL_NAME = "压制"

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func _is_enemy_of_card(c) -> bool:
	return is_instance_valid(c) and c != card and _side_of(c) != _side_of(card)

func _enemy_cards() -> Array:
	if isFriendly:
		return slotManager.all_enemy_cards() + slotManager.all_enemy_cards_backrow()
	return slotManager.all_friendly_cards() + slotManager.all_friendly_cards_backrow()

func _list() -> Array:
	if not card.has_meta(META_KEY):
		card.set_meta(META_KEY, [])
	return card.get_meta(META_KEY)

func handle_event(event: String, params: Array):
	_ensure_connected()

	if event == "card_summoned":
		if params[0] == card:
			if "DoublePerish" in card.get_node("AnimationPlayer").current_animation:
				return
			for foe in _enemy_cards():
				_suppress(foe)
		elif not card.in_hand and card.is_alive() and _is_enemy_of_card(params[0]):
			_suppress(params[0])
		return

	if event == "card_perished" and params[0] == card:
		_restore_all()

func _ensure_connected() -> void:
	if not is_instance_valid(card):
		return
	var anim = card.get_node("AnimationPlayer")
	if not anim.is_connected("animation_started", self, "_on_anim_started"):
		anim.connect("animation_started", self, "_on_anim_started")

# 进化动画开始时判断：进化目标还带「压制」就继续光环，否则立刻还原
func _on_anim_started(anim_name) -> void:
	if anim_name != "Evolve":
		return
	if not card.has_sigil("Fledgling") or card.has_sigil("Fledgling 2"):
		return

	var tname = card.card_data.get("evolution", "")
	var tdat = CardInfo.from_name(tname) if tname != "" else null
	var target_keeps = tdat != null and SIGIL_NAME in tdat.get("sigils", [])
	if not target_keeps:
		_restore_all()

func _suppress(foe) -> void:
	if not is_instance_valid(foe) or not foe.is_alive():
		return

	var list = _list()
	if foe in list or foe.attack <= 0:
		return

	# 基础值和当前值一起减，否则会被 calculate_buffs 重算掉
	foe.card_data["attack"] = int(foe.card_data.get("attack", 0)) - 1
	foe.attack -= 1
	foe.draw_stats()

	list.append(foe)
	card.set_meta(META_KEY, list)

func _restore_all() -> void:
	var list = _list()
	for foe in list:
		if is_instance_valid(foe) and foe.is_alive():
			foe.card_data["attack"] = int(foe.card_data.get("attack", 0)) + 1
			foe.attack += 1
			foe.draw_stats()
	card.set_meta(META_KEY, [])
