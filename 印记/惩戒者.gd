extends SigilEffect
# 惩戒者：本卡被敌方单位消灭时，消灭那个单位。

func _side_of(c) -> String:
	return c.get_parent().get_parent().name

func handle_event(event: String, params: Array):
	if event != "card_hit" or params[0] != card:
		return

	var killer = params[1]
	if not is_instance_valid(killer) or killer == card:
		return
	if _side_of(killer) == _side_of(card):
		return

	# 只有自己真的被消灭时才触发
	var dying = card.health <= 0 or "Perish" in card.get_node("AnimationPlayer").current_animation
	if not dying:
		return

	_kill_later(killer)

func _kill_later(unit) -> void:
	if not is_instance_valid(unit):
		return

	var anim = unit.get_node("AnimationPlayer")

	# 如果它正在攻击，就等这次攻击动画播完再杀，避免打断战斗协程
	if anim.current_animation in ["Attack", "AttackRemote"]:
		yield(anim, "animation_finished")
	else:
		yield(fightManager.get_tree().create_timer(0.0), "timeout")

	if not is_instance_valid(unit) or not unit.is_alive():
		return

	# 磐石之身免疫，和死神之触一致
	if unit.has_sigil("Made of Stone"):
		return

	unit.health = 0
	unit.draw_stats()

	var a2 = unit.get_node("AnimationPlayer")
	if not "Perish" in a2.current_animation:
		a2.play("Perish")
