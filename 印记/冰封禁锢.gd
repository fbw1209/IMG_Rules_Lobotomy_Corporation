extends SigilEffect
# 冰封禁锢（自定义版）
# 死亡时在空位召唤 frozen_evolution 指定的卡；没有该字段就退回 evolution（和原版一致）。
#
# 部署（二选一）：
#   1) 覆盖原版：放进 user://scripts/ 并命名为 <规则集名>_Frozen Away.gd
#   2) 当成新印记：改名为 冰封禁锢.gd，卡上写 "sigils": [..., "冰封禁锢"]
# 联机：把本脚本地址填进 custom_sigils 对应条目的 url，双方会自动下载。

func handle_event(event: String, params: Array):
	if event != "card_perished" or params[0] != card:
		return

	var target = card.card_data.get("frozen_evolution", card.card_data.get("evolution", ""))
	if target == "":
		return

	var idx = card.slot_idx()
	var slot = slotManager.playerSlots[idx] if isFriendly else slotManager.enemySlots[idx]
	if not slotManager.is_slot_empty(slot):
		return

	var dat = CardInfo.from_name(target)
	if dat:
		slotManager.summon_card(dat, idx, isFriendly)
