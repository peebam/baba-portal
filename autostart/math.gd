extends Node

const ROUND_PRECISION := 100.0

func are_vector3_parallel(v1: Vector3, v2: Vector3) -> bool:
	return abs(
		v1.dot(v2)
	)


func compute_alignment_quaternion(from: Vector3, to: Vector3) -> Quaternion:
	var dot := roundf(from.dot(to) * ROUND_PRECISION) / ROUND_PRECISION

	if dot == 1.0:
		return Quaternion.IDENTITY

	if dot == -1.0:
		var perpendicular := compute_vector3_perpendicular(from)
		return Quaternion(perpendicular, PI)

	return Quaternion(from, to)


func compute_vector3_perpendicular(from: Vector3) -> Vector3:
	var reference := Vector3.RIGHT if are_vector3_parallel(from, Vector3.UP) else Vector3.UP
	return from.cross(reference)
