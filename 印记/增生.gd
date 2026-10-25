extends SigilEffect
# 升级/增生：消灭一个敌方单位后，变成 upgrade_into 指定的卡（该卡必须在规则集 cards 里定义）。

const FIELD = "upgrade_into"

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func handle_event(event: String, params: Array):
	if event != "card_hit" or params[1] != card:
		return

	var victim = params[0]
	if not is_instance_valid(victim) or victim == card:
		return
	if _side_of(victim) == _side_of(card):
		return
	if victim.health > 0:
		return

	var target = card.card_data.get(FIELD, "")
	if target == "" or target == card.card_data.get("name", ""):
		return

	# 延迟到本帧结束再变形：避免在 card_hit 信号回调里重建 sigils 引发重入崩溃
	call_deferred("_upgrade", target)

func _upgrade(target: String) -> void:
	# 如果这张卡在同一瞬间被别的效果（如惩戒者）打死，就不升级
	if not is_instance_valid(card) or not card.is_alive():
		return
	if card.card_data.get("name", "") == target:
		return

	var dat = CardInfo.from_name(target)
	if dat:
		card.from_data(dat)
