extends SigilEffect
# 数据删除：击中敌人时自身攻血 +1；击杀敌人后把它的复制（费用 0、1/1、图换成"复制"）加入手牌。

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

	# 命中敌人：自身攻血 +1（两边对称，不能加 isFriendly 判断）
	card.card_data["attack"] = int(card.card_data.get("attack", 0)) + 1
	card.card_data["health"] = int(card.card_data.get("health", 0)) + 1
	card.attack += 1
	card.health += 1
	card.draw_stats()

	# 击杀敌人：复制进手牌（只由拥有者执行，draw_card 会自动同步）
	if victim.health <= 0 and isFriendly:
		_add_copy(victim.card_data)

func _add_copy(src: Dictionary) -> void:
	var copy = src.duplicate(true)
	copy.erase("blood_cost")
	copy.erase("bone_cost")
	copy.erase("energy_cost")
	copy.erase("mox_cost")
	copy["attack"] = 1
	copy["health"] = 1
	copy.erase("atkspecial")

	var new_card = fightManager.draw_card(copy)
	if is_instance_valid(new_card):
		var tex = _load_card_texture(COPY_CARD_NAME)
		if tex:
			new_card.get_node("CardBody/CardPort").texture = tex

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
