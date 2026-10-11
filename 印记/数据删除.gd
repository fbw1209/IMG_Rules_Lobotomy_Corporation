extends SigilEffect
# 数据删除：击中敌人时自身攻血 +1；击杀后把它的复制（费用0、1/1、图=「复制」、带本印记）加入手牌。

const SIGIL_NAME = "数据删除"
const COPY_CARD_NAME = "复制"

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func _is_enemy(c) -> bool:
	return is_instance_valid(c) and c != card and _side_of(c) != _side_of(card)

func handle_event(event: String, params: Array):
	if event != "card_hit" or params[1] != card:
		return

	var victim = params[0]
	if not _is_enemy(victim):
		return

	# 命中敌人：自身攻血 +1（两边对称，不能加 isFriendly）
	card.card_data["attack"] = int(card.card_data.get("attack", 0)) + 1
	card.card_data["health"] = int(card.card_data.get("health", 0)) + 1
	card.attack += 1
	card.health += 1
	card.draw_stats()

	# 击杀敌人：生成复制品
	if victim.health <= 0:
		_make_copy(victim.card_data)

func _make_copy(src: Dictionary) -> void:
	var copy = src.duplicate(true)
	copy.erase("blood_cost")
	copy.erase("bone_cost")
	copy.erase("energy_cost")
	copy.erase("mox_cost")
	copy["attack"] = 1
	copy["health"] = 1
	copy.erase("atkspecial")

	# 加上本印记；已有 3 个印记则替换最左侧那个
	var sigs = copy.get("sigils", []).duplicate()
	if not SIGIL_NAME in sigs:
		if sigs.size() >= 3:
			sigs[0] = SIGIL_NAME
		else:
			sigs.append(SIGIL_NAME)
	copy["sigils"] = sigs

	_spawn_in_hand(copy)

# 双方各自在自己手牌里生成（对手端 -> EnemyHand），这样对手也能看到"复制"的图
func _spawn_in_hand(dat: Dictionary) -> void:
	var hand = fightManager.handManager.get_node("PlayerHand" if isFriendly else "EnemyHand")

	var nCard = fightManager.cardPrefab.instance()
	hand.add_child(nCard)
	nCard.from_data(dat)
	nCard.fightManager = fightManager
	nCard.slotManager = slotManager
	fightManager.connect("sigil_event", nCard, "handle_sigil_event")

	# 卡图换成「复制」
	var tex = _load_card_texture(COPY_CARD_NAME)
	if tex:
		nCard.get_node("CardBody/CardPort").texture = tex

	# 手牌间距
	var nC = 0
	for c in hand.get_children():
		if not c.is_queued_for_deletion():
			nC += 1
	hand.add_constant_override("separation", - min(nC, 12) * 4)

func _load_card_texture(card_name: String):
	var d = Directory.new()
	var override_path = CardInfo.portrait_override_path + card_name + ".png"
	if d.file_exists(override_path):
		return _load_img(override_path)
	var custom_path = CardInfo.custom_portrait_path + CardInfo.ruleset + "_" + card_name + ".png"
	if d.file_exists(custom_path):
		return _load_img(custom_path)
	var builtin_path = "res://gfx/pixport/" + card_name + ".png"
	if ResourceLoader.exists(builtin_path):
		return load(builtin_path)
	return null

func _load_img(path: String):
	var img = Image.new()
	if img.load(path) != OK:
		return null
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags -= tex.FLAG_FILTER
	return tex
