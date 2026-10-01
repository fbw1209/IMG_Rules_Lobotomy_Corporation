extends SigilEffect
# 印记名：小喙
# 效果：
#   1) 敌方单位被召唤到场上时，对其造成 1 点伤害；
#   2) 敌方单位攻击小喙同边单位时，对攻击者造成 1 点伤害（反弹）。
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_小喙.gd
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/
#
# 联机：双方对称执行，用 isFriendly 选边，不会 desync。

func _on_player_side(c: Node) -> bool:
	return c.get_parent().get_parent().name in ["PlayerSlots", "PlayerSlotsBack"]

func handle_event(event: String, params: Array):
	# 自己不在场上就不做事
	if card.in_hand or not card.is_alive():
		return

	# 1) 敌方单位被召唤
	if event == "card_summoned":
		var summoned = params[0]
		if summoned != card and _on_player_side(summoned) != isFriendly:
			summoned.take_damage(null, 1)

	# 2) 敌方单位攻击我方（小喙同边）单位
	if event == "card_hit":
		var defender = params[0]
		var attacker = params[1]

		if attacker == null or not is_instance_valid(attacker):
			return
		if _on_player_side(defender) != isFriendly:
			return
		if _on_player_side(attacker) == isFriendly:
			return

		attacker.take_damage(null, 1)
