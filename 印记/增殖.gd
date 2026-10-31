extends SigilEffect
# 增殖：每击杀一个单位，自身攻击 +1、生命 +1。

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

	# 击杀：+1 攻 / +1 生命（两边对称，不能加 isFriendly）
	card.card_data["attack"] = int(card.card_data.get("attack", 0)) + 1
	card.card_data["health"] = int(card.card_data.get("health", 0)) + 1
	card.attack += 1
	card.health += 1
	card.draw_stats()
