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

	_force_kill(killer)

# 直接击杀（绕过 Warded / Highlight），且不会再次触发对方的"惩戒者"
func _force_kill(unit) -> void:
	if not is_instance_valid(unit) or not unit.is_alive():
		return

	# 磐石之身免疫，和死神之触一致
	if unit.has_sigil("Made of Stone"):
		return

	unit.health = 0
	unit.draw_stats()

	var anim = unit.get_node("AnimationPlayer")
	if not "Perish" in anim.current_animation:
		anim.play("Perish")
