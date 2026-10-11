extends SigilEffect
# 印记名：战利品
# 效果：本单位消灭一个敌方单位后，把该单位的复制加入自己手中；
#       复制品的费用变为 0，攻击/生命变为 1/1。
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_战利品.gd
#      并在规则集 custom_sigils 里声明 "战利品"。
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/ ，任何规则集直接写名字即可。
#
# 联机：只有"拥有者"这边执行（isFriendly），并调用会自动广播的 draw_card；
#       对手端通过回放 _opponent_drew_card 获得手牌数变化，不会 desync。

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

	fightManager.draw_card(copy)
