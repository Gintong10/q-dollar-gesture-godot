extends Node

const NUM_POINTS := 64
const SQUARE_SIZE := 250.0
const ORIGIN := Vector2.ZERO
const THETA := deg_to_rad(45)
const DELTA := deg_to_rad(2)

var templates = []  # Array of preprocessed templates (each is an array of points)

	
#Step 1
func resample(points: Array, n: int) -> Array: #correct
	var I = path_length(points) / (n - 1)
	var D = 0.0
	var new_points = [points[0]]
	
	for i in range(1, points.size()):
		var d = points[i - 1].distance_to(points[i])
		if (D + d) >= I:
			var qx = points[i-1].X + ((I - D) / d) * (points[i].X - points[i-1].X);
			var qy = points[i-1].Y + ((I - D) / d) * (points[i].Y - points[i-1].Y);
			var q = Vector2(qx, qy)
			new_points.append(q) #append new point 'q'
			points.insert(i, q) #insert 'q' at position i in points s.t. 'q' will be the next i
			D = 0.0;
		else:
			D += d
		
	if new_points.size() == n - 1: #somtimes we fall a rounding-error short of adding the last point, so add it if so
		new_points.append(Vector2(points[points.size() - 1].x, points[points.size() - 1].y))
	return new_points

func path_length(points: Array) -> float: #correct
	var d = 0.0
	for i in range(1, points.size()):
		d += points[i - 1].distance_to(points[i])
	return d

#Step 2
#indicative angle(points) is missing
func rotate_by(points: Array, radians: float) -> Array: #correct
	var c = centroid(points)
	var cos = cos(radians)
	var sin = sin(radians)
	var new_points = []
	
	for p in points:
		var qx = (p.x - c.x) * cos - (p.y - c.y) * sin + c.x
		var qy = (p.x - c.x) * sin + (p.y - c.y) * cos + c.y

		new_points.append(Vector2(qx, qy))
		
	return new_points

#Step 3
func centroid(points: Array) -> Vector2:
	var total = Vector2.ZERO
	for p in points:
		total += p
	return total / points.size()

func bounding_box(points : Array) -> Vector4: #correct
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)
		
	return Vector4(min_x, min_y, max_x - min_x, max_y - min_y)

func scale_to_square(points: Array, size: float) -> Array: #correct
	var B = bounding_box(points) #Rectangle(minX, minY, maxX - minX, maxY - minY); x, y, width, height
	var new_points = []
	
	for p in points:
		var qx = p.x * (size / B[2])
		var qy = p.y * (size / B[3])
		new_points.append(Vector2(qx, qy))
	return new_points

func translate_to(points: Array, pt: Vector2) -> Array: #correct
	var c = centroid(points)
	var new_points = []
	for p in points:
		var qx = p.x + pt.x - c.x
		var qy = p.y + pt.y - c.y
		new_points.append(Vector2())
	return new_points

#Step 4
func recognize(points : Array) -> String: # Call this when recognizing a gesture
	var candidate = normalize(points)
	var b = INF
	var best_name = ""
	for template in templates:
		var d = distance_at_best_angle(candidate, template.points)
		if d < b:
			b = d
			best_name = template.name
	return best_name
	
func distance_at_best_angle(points: Array, template: Array) -> float:
	var a = -THETA
	var b = THETA
	var threshold = DELTA
	var phi = 0.5 * (-1 + sqrt(5))
	var x1 = phi * a + (1 - phi) * b
	var x2 = (1 - phi) * a + phi * b
	var f1 = distance_at_angle(points, template, x1)
	var f2 = distance_at_angle(points, template, x2)
	
	while abs(b - a) > threshold:
		if f1 < f2:
			b = x2
			x2 = x1
			f2 = f1
			x1 = phi * a + (1 - phi) * b
			f1 = distance_at_angle(points, template, x1)
		else:
			a = x1
			x1 = x2
			f1 = f2
			x2 = (1 - phi) * a + phi * b
			f2 = distance_at_angle(points, template, x2)
	return min(f1, f2)

func normalize(points : Array) -> Array:
	points = resample(points, NUM_POINTS)
	var c = centroid(points)
	var indicative_angle = points[0].angle_to_point(c)
	points = rotate_by(points, -indicative_angle)
	points = scale_to_square(points, SQUARE_SIZE)
	points = translate_to(points, ORIGIN)
	return points


func distance_at_angle(points: Array, template: Array, theta: float) -> float:
	var new_points = rotate_by(points, theta)
	return path_distance(new_points, template)

func path_distance(a: Array, b: Array) -> float:
	var d = 0.0
	for i in range(a.size()):
		d += a[i].distance_to(b[i])
	return d / a.size()

func add_template(name: String, raw_points: Array):
	var norm = normalize(raw_points)
	templates.append({ "name": name, "points": norm })
