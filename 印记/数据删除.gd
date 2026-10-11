extends SigilEffect
# 印记名：数据删除
# 效果：本单位消灭一个敌方单位后，把该单位的复制加入自己手中；
#       复制品费用为 0、属性 1/1，卡图替换为 "复制" 这张卡的图片。
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_数据删除.gd
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/
#
# 联机：只有"拥有者"这边执行（isFriendly），并调用会自动广播的 draw_card；
#       对手端通过回放 _opponent_drew_card 获得手牌数变化，不会 desync。

# 用来当卡图的卡名（你自定义规则集里那张叫 "复制" 的卡）
const COPY_CARD_NAME = "复制"

func _side_of(c: Node) -> String:
	# 卡 -> 格子 -> PlayerSlots / EnemySlots（含后排）
	return c.get_parent().get_parent().name

func handle_event(event: String, params: Array):
	if event != "card_hit":
		return

	var victim = params[0]    # 被击者
	var attacker = params[1]  # 攻击者（可能是 null）

	# 1) 必须是我打中的
	if attacker != card:
		return

	# 2) 目标必须是敌人（不同边），且不是自己
	if not is_instance_valid(victim) or victim == card:
		return
	if _side_of(victim) == _side_of(card):
		return

	# 3) 目标必须真的被消灭
	if victim.health > 0:
		return

	# 4) 只由拥有者这边执行；draw_card 会自动把"抽一张"同步给对手
	if not isFriendly:
		return

	_add_copy_to_hand(victim.card_data)

func _add_copy_to_hand(src: Dictionary) -> void:
	var copy = src.duplicate(true)

	# 费用全部清零
	copy.erase("blood_cost")
	copy.erase("bone_cost")
	copy.erase("energy_cost")
	copy.erase("mox_cost")

	# 属性固定为 1/1；同时去掉会覆盖攻击力的特殊算法，保证真的是 1/1
	copy["attack"] = 1
	copy["health"] = 1
	copy.erase("atkspecial")

	# 抽到手牌（返回创建出来的那张卡）
	var new_card = fightManager.draw_card(copy)

	# 把手牌里这张卡的卡图替换成 "复制" 的图片
	if is_instance_valid(new_card):
		var tex = _load_card_texture(COPY_CARD_NAME)
		if tex:
			new_card.get_node("CardBody/CardPort").texture = tex

# 按卡名找图，查找顺序和引擎一致：本地覆盖 -> 规则集下载 -> 游戏自带
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

	print("数据删除：找不到卡图 '", card_name, "'")
	return null

func _load_img(path: String):
	var img = Image.new()
	if img.load(path) != OK:
		return null
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags -= tex.FLAG_FILTER
	return tex
