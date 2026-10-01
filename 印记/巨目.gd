extends SigilEffect
# 印记名：巨目
# 效果：当"巨目的敌方单位"攻击巨目同边单位后，削弱巨目的敌方最左侧、攻击力大于 0 的单位 1 点攻击力；
#       若该单位攻击力为 0 则跳过，顺延到下一个（"若为0则顺延"）。
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_巨目.gd
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/
#
# 联机：双方对称执行，用 isFriendly 选边，不会 desync。
# 说明：直接受到其它印记伤害时，如果 take_damage 带了攻击者，也可能触发本效果（本作 card_hit 不区分来源）。

func _on_player_side(c: Node) -> bool:
	# 卡挂在格子节点下，格子在 PlayerSlots / EnemySlots（或其后排）下
	return c.get_parent().get_parent().name in ["PlayerSlots", "PlayerSlotsBack"]

func handle_event(event: String, params: Array):
	if card.in_hand or not card.is_alive():
		return
	if event != "card_hit":
		return

	var defender = params[0]  # 被攻击的卡
	var attacker = params[1]  # 攻击者（可能是 null）

	if attacker == null or not is_instance_valid(attacker):
		return

	# 被攻击的必须和巨目同边，攻击者必须和巨目不同边
	if _on_player_side(defender) != isFriendly:
		return
	if _on_player_side(attacker) == isFriendly:
		return

	# 从最左侧开始，找巨目的敌方第一只攻击力 > 0 的单位
	for i in range(4):
		var foe = slotManager.get_enemy_card(i) if isFriendly else slotManager.get_friendly_card(i)
		if foe and foe.is_alive() and foe.attack > 0:
			# 同时改基础值（持久，calculate_buffs 会从这里重算）和当前值（立刻刷新显示）
			foe.card_data["attack"] = max(0, int(foe.card_data.get("attack", 0)) - 1)
			foe.attack = max(0, foe.attack - 1)
			foe.draw_stats()
			break
