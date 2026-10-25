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

func _force_kill(unit) -> void:
	if not is_instance_valid(unit) or not unit.is_alive():
		return

	# 磐石之身免疫，和死神之触一致
	if unit.has_sigil("Made of Stone"):
		return

	# 立刻判定死亡（这样它不会继续攻击），但把播 Perish 延迟到本帧结束，
	# 避免在它自己的攻击动画回调里同步切动画导致崩溃。
	unit.health = 0
	unit.draw_stats()
	call_deferred("_play_perish", unit)

func _play_perish(unit) -> void:
	if not is_instance_valid(unit) or unit.is_queued_for_deletion():
		return
	var anim = unit.get_node("AnimationPlayer")
	if not "Perish" in anim.current_animation:
		anim.play("Perish")