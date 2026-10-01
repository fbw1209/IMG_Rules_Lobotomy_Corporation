extends SigilEffect
# 印记名：大怪兽
# 效果：这张卡被召唤时，消灭我方场上其他所有单位，然后在其余 3 个空格依次召唤 小喙 / 巨目 / 长臂。
# 依赖卡名：小喙、巨目、长臂（必须和规则集 cards 里的名字完全一致）
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_大怪兽.gd
#      并在规则集 custom_sigils 里声明 "大怪兽"。
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/ ，任何规则集都能直接写这个名字。
#
# 联机：本脚本在双方各跑一遍，用 isFriendly 决定"以哪一边为我的视角"，保证对称执行、不会 desync。

const TRIO = ["小喙", "巨目", "长臂"]

func handle_event(event: String, params: Array):
	if event != "card_summoned" or params[0] != card:
		return

	# 防止"双重死亡/复活"时重复触发
	if "DoublePerish" in card.get_node("AnimationPlayer").current_animation:
		return

	# isFriendly 只用来选边，不做"只在自己这边执行"的判断
	var my_slots = slotManager.playerSlots if isFriendly else slotManager.enemySlots
	var my_cards = slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards()
	var my_slot = card.slot_idx()

	# 1) 消灭其他所有同边单位
	for ally in my_cards:
		if ally != card:
			_force_kill(ally)

	# 2) 在其余 3 个空格依次召唤部件
	var idx = 0
	for i in range(4):
		if i == my_slot:
			continue
		if idx >= TRIO.size():
			break

		var dat = CardInfo.from_name(TRIO[idx])
		idx += 1

		if dat and slotManager.is_slot_empty(my_slots[i]):
			slotManager.summon_card(dat, i, isFriendly)

# 直接击杀：绕过 Warded（纳米铠甲）和 Highlight（缝合待结算）的减伤/免伤
func _force_kill(unit) -> void:
	if not is_instance_valid(unit) or not unit.is_alive():
		return

	unit.health = 0
	unit.draw_stats()

	var anim = unit.get_node("AnimationPlayer")
	if not "Perish" in anim.current_animation:
		anim.play("Perish")
