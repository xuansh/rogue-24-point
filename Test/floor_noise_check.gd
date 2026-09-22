extends SceneTree
## 地面随机地砖自检：godot --headless -s Test/floor_noise_check.gd
## 守三件事：哈希对同一格稳定（重绘不闪）、分布不退化（不是棋盘、不是一片同色）、
## 锚点落在格心上（否则玩家/敌人会像之前那样被拖偏或跟地面错位）；
## 外加怪诞网格的共享边必须只有一份曲线。

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
