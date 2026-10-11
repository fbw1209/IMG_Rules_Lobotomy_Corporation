extends SigilEffect
# 数据删除：击中敌人时自身攻血 +1；击杀敌人后把一张「CENSORED-1」加入手牌。

const ADD_CARD_NAME = "CENSORED-1"

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func _is_enemy(c) -> bool:
	return is_instance_valid(c) and c != card and _side_of(c) != _side_of(card)

func handle_event(event: String, params: Array):
	if event != "card_hit" or params[1] != card:
		return

	var victim = params[0]
	if not _is_enemy(victim):
		return

	# 命中敌人：自身攻血 +1（两边对称，不能加 isFriendly）
	card.card_data["attack"] = int(card.card_data.get("attack", 0)) + 1
	card.card_data["health"] = int(card.card_data.get("health", 0)) + 1
	card.attack += 1
	card.health += 1
	card.draw_stats()

	# 击杀敌人：把 CENSORED-1 加入手牌（只由拥有者执行，draw_card 会自动同步）
	if victim.health <= 0 and isFriendly:
		var dat = CardInfo.from_name(ADD_CARD_NAME)
		if dat:
			fightManager.draw_card(dat)
