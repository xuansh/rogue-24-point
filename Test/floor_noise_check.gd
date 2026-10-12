extends SceneTree
## 地面 + 卡牌的自检：godot --headless -s Test/floor_noise_check.gd
## 地面：哈希对同一格稳定（重绘不闪）、分布不退化（不是棋盘、不是一片同色）、
## 锚点落在格心上（否则玩家/敌人会像之前那样被拖偏或跟地面错位）、共享边只有一份曲线。
## 卡牌：刀身轮廓必须闭合在角点上，且必须是凸多边形（判定区用的就是它）。
## 数字碎片：同理，且数字中心必须落在碎片内部、连抖动量一起不能撞到隔壁槽位。
## 凹槽：洞口必须罩得住碎片（洞和碎片共用同一份轮廓，比例得对得上）。
## 能量罐：液面裁剪 + 费用越高液面越高。

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
	_check_number_shard()
	_check_socket()
	_check_energy_jar()
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

## 数字碎片：同样的闭合/凸性约束，另外数字中心必须落在碎片内部
## （轮廓是左重右尖的，中心常数写歪了数字就会飘到碎片外面）、
## 连抖动量一起不能顶到隔壁槽位、几何必须与值无关，且分档随值单调。
func _check_number_shard() -> void:
	var shard_script := load("res://Entities/Blocks/NumberBlock/number_shard.gd")
	var shape: Array = shard_script.SHARD
	assert(_is_convex(shape), "碎片必须是凸多边形，凸性也是 _inside_convex 的前提")
	var shard = shard_script.new()
	var outline = shard._wobbled_outline()
	var step: int = shard.segments + 1
	var wobble_bound : float = shard.wobble
	for e in shape.size():
		assert(outline[e * step].is_equal_approx(shape[e]), "轮廓必须在角点起笔")
	assert(outline[outline.size() - 1].is_equal_approx(shape[0]), "轮廓必须收回到起点")
	assert(_inside_convex(shape, shard_script.NUMBER_CENTER), "数字中心必须落在碎片内部")
	shard.free()

	# 槽位 64 宽、彼此间隔 12，所以实体最远只能越过槽边 6px。
	# 抖动量有界（= wobble），用上界算，不靠采样碰运气。
	var reach := 0.0
	for p in shape:
		reach = maxf(reach, maxf(absf(p.x), absf(p.y)))
	reach = reach + wobble_bound
	assert(reach <= 38.0, "连抖动一起不能撞到隔壁槽位(%f)" % reach)

	# 尺寸契约：分档只走颜色和辉光，几何必须与值完全无关。
	# 一排数字块一旦大小不一，槽位看着就参差不齐，数字也不齐。
	var small = shard_script.new()
	var big = shard_script.new()
	small.value = 1
	big.value = 9
	assert(small.scale.is_equal_approx(big.scale), "体型不能随值变化")
	assert(small._wobbled_outline() == big._wobbled_outline(), "轮廓不能随值变化")
	small.free()
	big.free()

	# 分档契约：1 最冷、9 最热、随值单调不减、越界要被夹住
	var previous := -1.0
	for v in range(1, 10):
		var probe = shard_script.new()
		probe.value = v
		var t: float = probe.tier()
		assert(t >= previous, "分档必须随值单调不减")
		previous = t
		probe.free()
	var edge = shard_script.new()
	edge.value = 0
	assert(is_equal_approx(edge.tier(), 0.0), "低于下限要夹到最冷档")
	edge.value = 99
	assert(is_equal_approx(edge.tier(), 1.0), "高于上限要夹到最热档")
	edge.free()

## 凹槽：洞口必须罩得住碎片，否则碎片会盖不住洞、露出毛边。
## 两个宿主用的是同一比值：buffer 是 64px 槽配满尺寸碎片(shape_scale 1.08)，
## operand 是 0.63 倍的碎片配 shape_scale 0.7，两边比值相当。
func _check_socket() -> void:
	var socket_script := load("res://Entities/Blocks/socket_shard.gd")
	var token_script := load("res://Entities/Blocks/NumberBlock/number_shard.gd")
	var socket = socket_script.new()
	var token = token_script.new()
	var shape_radius := 0.0
	for p in token_script.SHARD:
		shape_radius = maxf(shape_radius, maxf(absf(p.x), absf(p.y)))
	var socket_reach : float = (shape_radius + socket.wobble) * socket.shape_scale
	var token_reach : float = shape_radius + token.wobble
	assert(socket_reach >= token_reach,
		"洞口(%f)必须罩得住碎片(%f)" % [socket_reach, token_reach])
	socket.free()
	token.free()

## 能量罐：液面裁剪是这里唯一非平凡的几何，裁错了会漏液或者溢出罐子。
## 另外盯住两条契约：费用越高液面越高（单调），0 费时罐子要是空的。
func _check_energy_jar() -> void:
	var jar_script := load("res://UI/HUD/EnergyJar/energy_jar.gd")
	var jar = jar_script.new()

	# 裁剪本身：方形下半边的面积必须是总面积的一半
	var square := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	assert(is_equal_approx(_area(jar._clip_below(square, -1.0)), 100.0), "整条都在液面下就不该裁掉")
	assert(is_equal_approx(_area(jar._clip_below(square, 11.0)), 0.0), "液面在顶上就该是空的")
	assert(is_equal_approx(_area(jar._clip_below(square, 5.0)), 50.0), "切一半面积就该是一半")

	# 罐子：满费液面必须在罐腰以上（脖子根），0 费必须没液体
	jar.max_value = 4
	jar.current = 4
	assert(is_equal_approx(jar._liquid_level(), jar_script.LIQUID_TOP), "满费液面该在脖子根")
	var full : PackedVector2Array = jar._clip_below(jar_script.JAR, jar._liquid_level())
	assert(full.size() >= 3 and _area(full) > 0.0, "满费罐子必须有液体")
	assert(_inside(full, Vector2(0, 100)), "满费时罐腰该被液体盖住")
	jar.current = 0
	assert(is_equal_approx(jar._liquid_level(), jar_script.LIQUID_BOTTOM), "0 费液面该退到罐底")
	assert(_area(jar._clip_below(jar_script.JAR, jar._liquid_level())) < 1.0, "0 费罐子该是空的")

	# 单调：费用越高，液体面积越大
	var previous := -1.0
	for v in range(0, 5):
		jar.current = v
		var area := _area(jar._clip_below(jar_script.JAR, jar._liquid_level()))
		assert(area >= previous, "液体面积必须随费用单调不减")
		previous = area
	jar.free()
	print("energy jar ok: full_liquid=%d" % _area(full))

## 鞋带公式算多边形面积（绝对值）
func _area(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5

## 射线法点在多边形内，罐子不是凸的所以不能用半平面判定
func _inside(poly: PackedVector2Array, p: Vector2) -> bool:
	var hit := false
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if (a.y > p.y) != (b.y > p.y):
			var x := a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x)
			if x > p.x:
				hit = not hit
	return hit

## 凸多边形内部判定：点必须相对每条边都落在同一侧
func _inside_convex(poly: Array, p: Vector2) -> bool:
	var winding := 0
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var cross := (b - a).cross(p - a)
		if absf(cross) < 0.0001:
			continue
		var side := 1 if cross > 0.0 else -1
		if winding != 0 and side != winding:
			return false
		winding = side
	return winding != 0

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
