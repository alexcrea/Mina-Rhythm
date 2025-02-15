extends Control

@export var lanes: Array[Node]
var is_dragging = false
var apear_time: float

var lane_margin = 50  # Adjust this value to make the snapping more forgiving

func is_in_lane() -> bool:
	var margin = 20  # Adjust this value as needed for leniency

	for lane in lanes:
		if (position.x + size.x / 2) > (lane.position.x - margin) and (position.x + size.x / 2) < (lane.position.x + lane.size.x + margin):
			print("lane")
			return true
	print("nolane")
	return false
func snap_to_lane():
	var nearest_lane_x = get_nearest_lane_x(position.x)
	position.x = nearest_lane_x
	print(position.x)
func get_nearest_lane_x(current_x: float) -> float:
	var lane_positions = []
	for each in lanes:
		lane_positions.append(each.position.x)
	var nearest_lane = lane_positions[0]
	var smallest_distance = abs(current_x - lane_positions[0])
	
	for lane in lane_positions:
		var distance = abs(current_x - lane)
		if distance < smallest_distance:
			smallest_distance = distance
			nearest_lane = lane
	
	return nearest_lane
