extends GdUnitTestSuite

const BulletScript = preload("res://scripts/bullet.gd")

func test_lob_progress_is_bounded_and_handles_zero_distance() -> void:
	var bullet = BulletScript.new()
	var start = Vector2.ZERO
	var target = Vector2(300, 0)

	assert_float(bullet._get_progress(150, start, target)).is_equal(50.0)
	assert_float(bullet._get_progress(450, start, target)).is_equal(100.0)
	assert_float(bullet._get_progress(0, start, start)).is_equal(100.0)
