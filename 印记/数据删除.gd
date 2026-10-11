extends SigilEffect
# 数据删除：击中敌人时自身攻血 +1；击杀敌人后把它的复制（费用0、1/1、图=「复制」、带本印记）加入手牌。

const SIGIL_NAME = "数据删除"
const COPY_CARD_NAME = "复制"       # 复制品用的名字/图（规则集里的卡）
const SIGIL_ICON_NAME = "CENSORED"  # 本印记图标用哪张图

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func _is_enemy(c) -> bool:
	return is_instance_valid(c) and c != card and _side_of(c) != _side_of(card)

func handle_event(event: String, params: Array):
	# 上场时补一下印记图标（引擎画的时候会画成空白）
	if event == "card_summoned" and params[0] == card:
		_apply_sigil_icon(card)
		return

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

	# 击杀敌人：只由拥有者抽一张（对手端会显示为空白手牌，不会暴露）
	if victim.health <= 0 and isFriendly:
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

	# 名字/图改成「复制」（数据驱动，打出到场上双方都显示正确）
	var rep = CardInfo.from_name(COPY_CARD_NAME)
	copy["name"] = COPY_CARD_NAME
	if rep and "pixport_url" in rep:
		copy["pixport_url"] = rep.pixport_url
	else:
		copy.erase("pixport_url")

	# 加上本印记；已有 3 个印记则替换最左侧那个
	var sigs = copy.get("sigils", []).duplicate()
	if not SIGIL_NAME in sigs:
		if sigs.size() >= 3:
			sigs[0] = SIGIL_NAME
		else:
			sigs.append(SIGIL_NAME)
	copy["sigils"] = sigs

	var nCard = fightManager.draw_card(copy)
	_apply_sigil_icon(nCard)

# 把本印记的图标替换成 SIGIL_ICON_NAME 的图
func _apply_sigil_icon(target) -> void:
	if not is_instance_valid(target):
		return
	var sigs = target.card_data.get("sigils", [])
	var idx = sigs.find(SIGIL_NAME)
	if idx < 0 or idx > 5:
		return
	var slot = target.get_node_or_null([
		"CardBody/Sigils/Row1/S1",
		"CardBody/Sigils/Row1/S2",
		"CardBody/Sigils/Row1/S3",
		"CardBody/Sigils/Row2/S1",
		"CardBody/Sigils/Row2/S2",
		"CardBody/Sigils/Row2/S3",
	][idx])
	if slot:
		var tex = _load_texture(SIGIL_ICON_NAME)
		if tex:
			slot.texture = tex

func _load_texture(card_name: String):
	var d = Directory.new()
	for path in [
		CardInfo.portrait_override_path + card_name + ".png",
		CardInfo.icon_override_path + card_name + ".png",
		CardInfo.custom_portrait_path + CardInfo.ruleset + "_" + card_name + ".png",
		CardInfo.custom_icon_path + CardInfo.ruleset + "_" + card_name + ".png",
	]:
		if d.file_exists(path):
			return _load_img(path)
	for builtin in ["res://gfx/sigils/" + card_name + ".png", "res://gfx/pixport/" + card_name + ".png"]:
		if ResourceLoader.exists(builtin):
			return load(builtin)
	return null

func _load_img(path: String):
	var img = Image.new()
	if img.load(path) != OK:
		return null
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags -= tex.FLAG_FILTER
	return tex
