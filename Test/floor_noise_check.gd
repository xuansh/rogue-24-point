extends SceneTree
## 地面 + 卡牌的自检：godot --headless -s Test/floor_noise_check.gd
## 地面：哈希对同一格稳定（重绘不闪）、分布不退化（不是棋盘、不是一片同色）、
## 锚点落在格心上（否则玩家/敌人会像之前那样被拖偏或跟地面错位）、共享边只有一份曲线。
## 卡牌：刀身轮廓必须闭合在角点上，且必须是凸多边形（判定区用的就是它）。

func _initialize() -> void:
	var floor_script := load("res://Scenes/iso_floor.gd")
	var anchor: Vector2 = floor_script.ANCHOR
	assert(floor_script.mirror(anchor) == Vector2(floor_script.DESIGN_SIZE.x - anchor.x, anchor.y),
			"锚点必须本身就是格心，镜像点才不会偏")
	# 砖 (0,0) 的东南边 = 砖 (1,0) 的西北边，两条必须共用一个 key，
	# 否则怪诞网格会在共享边上画出两条错开的线
	assert(floor_script._edge_key(Vector2i(0, 0), 1) == floor_script._edge_key(Vector2i(1, 1), 3),
			"共享边的 key 必须一致")
	assert(floor_script._edge_key(Vector2i(0, 0), 3) == floor_script._edge_key(Vector2i(-1, -1), 1),
			"共享边的 key 必须一致")
	_check_shard()
	var mids: Array[float] = []
	var even := 0.0
	var odd := 0.0
	var even_n := 0
	var odd_n := 0
	var kinds := {}
	for i in range(-20, 21):
		for j in range(-20, 21):
			var roll: float = floor_script._hash(i, j, 0)
			assert(roll >= 0.0 and roll <= 1.0, "哈希必须落在 [0,1]")
			assert(roll == floor_script._hash(i, j, 0), "同一格的哈希必须稳定")
			var kind := "pit" if roll < 0.10 else ("bright" if roll > 0.90 else "mid")
			kinds[kind] = true
			if kind != "mid":
				continue
			var t: float = (floor_script._hash(i, j, 1) + floor_script._hash(i, j, 4)) * 0.5
			mids.append(t)
			if (i + j) % 2 == 0:
				even += t
				even_n += 1
			else:
				odd += t
				odd_n += 1
	assert(kinds.size() == 3, "深坑/普通/亮石三类都要出现")
	var mean := 0.0
	for t in mids:
		mean += t
	mean /= mids.size()
	var variance := 0.0
	for t in mids:
		variance += (t - mean) * (t - mean)
	var deviation := sqrt(variance / mids.size())
	assert(deviation > 0.10, "砖面色要够随机，不能退回近似单一色")
	assert(absf(even / even_n - odd / odd_n) < 0.1, "不能残留棋盘格的奇偶差异")
	print("floor noise ok: mean=%.3f sd=%.3f mid_tiles=%d" % [mean, deviation, mids.size()])
	quit()

## 运算块刀身：轮廓起笔/收笔必须落在角点上（边角才接得上），
## 且 SHARD 必须是凸多边形，否则 ConvexPolygonShape2D 会按凸包算，判定跟画面对不上
func _check_shard() -> void:
	# 用 load 而不是类名：脚本单独跑时类名缓存可能还没刷新，按路径拿最稳
	var shard_script := load("res://Entities/Blocks/OperatorBlock/card_shard.gd")
	var shape: Array = shard_script.SHARD
	var shard = shard_script.new()
	var outline = shard._wobbled_outline()
	var step: int = shard.segments + 1
	for e in shape.size():
		# 用近似比较：收笔那一点会有 1e-16 量级的浮点残差，肉眼和像素都看不出来
		assert(outline[e * step].is_equal_approx(shape[e]), "轮廓必须在角点起笔")
	assert(outline[outline.size() - 1].is_equal_approx(shape[0]), "轮廓必须收回到起点")
	assert(_is_convex(shape), "刀身必须是凸多边形")
	shard.free()

func _is_convex(poly: Array) -> bool:
	var winding := 0
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var c: Vector2 = poly[(i + 2) % poly.size()]
		var cross := (b - a).cross(c - b)
		if absf(cross) < 0.0001:
			continue
		var turn := 1 if cross > 0.0 else -1
		if winding != 0 and turn != winding:
			return false
		winding = turn
	return true
