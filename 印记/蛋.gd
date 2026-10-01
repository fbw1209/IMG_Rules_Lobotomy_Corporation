extends SigilEffect
# 印记名：蛋
# 效果：这张卡死亡时，对"与自己同边"的终末鸟造成 333 点伤害（只打第一只）。
# 依赖卡名：终末鸟（必须和规则集 cards 里的名字完全一致）
#
# 注意：333 点伤害会被 Warded（纳米铠甲）强制降为 1 点，也会被 Highlight（缝合待结算）完全免掉。
#       想必定击杀可以改用 _force_kill 的写法（见 大怪兽.gd）。
#
# 部署方式（二选一）：
#   1) 自定义印记：复制到 user://scripts/ ，重命名为 <你的规则集名>_蛋.gd
#   2) 当内置印记：直接放进 res://scripts/classes/sigils/
#
# 联机：双方对称执行，用 isFriendly 选边，不会 desync。

const TARGET_NAME = "终末鸟"

func handle_event(event: String, params: Array):
	if event != "card_perished" or params[0] != card:
		return

	var allies = slotManager.all_friendly_cards() if isFriendly else slotManager.all_enemy_cards()

	for unit in allies:
		if unit.card_data.get("name", "") == TARGET_NAME:
			unit.take_damage(null, 333)
			break
