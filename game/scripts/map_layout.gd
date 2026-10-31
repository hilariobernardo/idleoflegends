extends RefCounted
## Immutable, image-aligned paths. Coordinates share the full texture rectangle.
static var graph: AStar2D
static var data: Dictionary
static var lanes: Array[PackedVector2Array] = []
static var lengths: Array[PackedFloat32Array] = []

static func prepare() -> void:
	if graph != null:
		return
	data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/arena_navigation.json"))
	graph = AStar2D.new()
	for id: int in range(data.nodes.size()):
		graph.add_point(id, Vector2(data.nodes[id][0], data.nodes[id][1]))
	for edge: Array in data.edges:
		graph.connect_points(int(edge[0]), int(edge[1]))
	for ids: Array in data.lanes:
		var points: PackedVector2Array = PackedVector2Array()
		var distances: PackedFloat32Array = PackedFloat32Array([0.0])
		for id: int in ids:
			points.append(graph.get_point_position(id))
		for i: int in range(1, points.size()):
			distances.append(distances[-1] + points[i - 1].distance_to(points[i]))
		lanes.append(points)
		lengths.append(distances)

static func lane_points(lane: int) -> PackedVector2Array:
	prepare()
	return lanes[lane]

static func lane_length(lane: int) -> float:
	prepare()
	return lengths[lane][-1]

static func sample(lane: int, progress: float) -> Vector2:
	prepare()
	var target: float = clampf(progress, 0.0, 1.0) * lengths[lane][-1]
	var low: int = 0
	var high: int = lengths[lane].size() - 1
	while high - low > 1:
		var middle: int = (low + high) / 2
		if lengths[lane][middle] < target:
			low = middle
		else:
			high = middle
	return lanes[lane][low].lerp(lanes[lane][high], (target - lengths[lane][low]) / (lengths[lane][high] - lengths[lane][low]))

static func camps(team: int) -> PackedVector2Array:
	prepare()
	var result: PackedVector2Array = PackedVector2Array()
	for id: int in data.camps[team]:
		result.append(graph.get_point_position(id))
	return result

static func base(team: int) -> Vector2:
	prepare()
	return graph.get_point_position(int(data.bases[team]))

static func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	prepare()
	# Endpoints are on a lane segment or a camp. Nearest graph nodes are at
	# most one 5-pixel sample away, never a long direct shortcut through terrain.
	var result: PackedVector2Array = graph.get_point_path(graph.get_closest_point(from), graph.get_closest_point(to))
	if result.is_empty():
		push_error("Disconnected arena route")
		return result
	result.append(to)
	return result
