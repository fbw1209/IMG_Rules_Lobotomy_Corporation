extends SigilEffect
# 升级：消灭一个敌方单位后，变成 upgrade_into 指定的卡（该卡必须在规则集 cards 里定义）。

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

	var dat = CardInfo.from_name(target)
	if dat:
		card.from_data(dat)
