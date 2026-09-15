extends Node

@export var max_attackers: int = 2
var current_attackers: int = 0
 
## Returns true and reserves a slot if one's available; false if all slots are taken (caller should NOT attack in that case).
func request_slot() -> bool:
	if current_attackers < max_attackers:
		current_attackers += 1
		return true
	return false
 
## Must be called exactly once per successful request_slot(), whenever that enemy stops attacking (finishes retreat, gets interrupted, or dies).
func release_slot() -> void:
	current_attackers = max(0, current_attackers - 1)
 
