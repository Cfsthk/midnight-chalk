extends RefCounted

const STAGE_HP: Array[int] = [20, 40, 60, 80, 100]
const REMATCH_HP_BONUS := 2

# Each row's arrays follow the five campaign stages in order.
# Timed effects specify their lifetime in seconds. Fractions describe lane
# coverage or extra speed; the shuffle value is seconds between jumps.
const FAMILIES: Array[Dictionary] = [
	{
		"family": "wind", "names": ["追風紙燕", "竹尾紙燕", "旋風紙燕", "紫嵐紙燕", "裂空紙燕"],
		"cooldowns": [7.5, 7.0, 6.5, 6.0, 5.5], "normal_damage": [1, 1, 1, 2, 2], "heavy_damage": [3, 3, 3, 3, 3],
		"normal_effect": {"kind": "gust", "values": [1, 1, 2, 2, 2]},
		"heavy_effect": {"kind": "haste", "values": [0.30, 0.40, 0.50, 0.65, 0.80], "duration": 3.0},
	},
	{
		"family": "armour", "names": ["鐵甲衛", "玄鐵衛", "巨盾鐵衛", "星紋鐵衛", "月牙鐵衛"],
		"cooldowns": [9.0, 8.5, 8.0, 7.25, 6.5], "normal_damage": [1, 1, 2, 2, 2], "heavy_damage": [3, 3, 4, 4, 5],
		"normal_effect": {"kind": "armour", "values": [1, 1, 1, 2, 2]},
		"heavy_effect": {"kind": "armour", "values": [2, 2, 3, 3, 4]},
	},
	{
		"family": "bell", "names": ["銅鐘童子", "金紋鐘童", "疊聲銅鐘", "雙響鐘將", "三響鐘王"],
		"cooldowns": [9.5, 9.0, 8.5, 7.5, 6.5], "normal_damage": [2, 2, 2, 2, 3], "heavy_damage": [4, 4, 5, 6, 7],
	},
	{
		"family": "ink_fox", "names": ["墨尾狐", "飛墨狐", "流墨狐", "潑墨狐", "丹青墨狐"],
		"cooldowns": [7.75, 7.25, 6.75, 6.25, 5.75], "normal_damage": [1, 1, 1, 2, 2], "heavy_damage": [1, 1, 2, 2, 3],
		"heavy_effect": {"kind": "ink", "values": [0.20, 0.30, 0.40, 0.55, 0.70], "duration": 3.0},
	},
	{
		"family": "lantern_koi", "names": ["燈籠鯉", "映燈靈鯉", "彩燈錦鯉", "水火金鯉", "流金龍鯉"],
		"cooldowns": [10.0, 9.5, 9.0, 8.25, 7.5], "normal_damage": [2, 2, 2, 3, 3], "heavy_damage": [3, 4, 4, 5, 5],
		"heavy_effect": {"kind": "restore", "values": [2, 3, 4, 5, 6]},
	},
	{
		"family": "clockwork_crab", "names": ["齒輪蟹", "雙鉗銅蟹", "機關蟹將", "重鉗戰蟹", "百齒蟹王"],
		"cooldowns": [9.25, 8.75, 8.25, 7.5, 6.75], "normal_damage": [1, 2, 2, 2, 3], "heavy_damage": [3, 3, 4, 5, 5],
		"heavy_effect": {"kind": "shuffle", "values": [0.60, 0.55, 0.50, 0.45, 0.40], "duration": 3.0},
	},
	{
		"family": "porcelain_cat", "names": ["瓷紋貓", "青花貓", "瓷鈴靈貓", "花瓷御貓", "寶瓷貓仙"],
		"cooldowns": [8.0, 7.5, 7.0, 6.5, 6.0], "normal_damage": [1, 1, 1, 2, 2], "heavy_damage": [2, 2, 3, 3, 4],
		"heavy_effect": {"kind": "steal", "values": [1, 1, 1, 1, 1]},
	},
	{
		"family": "bamboo_snake", "names": ["竹節蛇", "綠節竹蛇", "翡翠竹蛇", "盤竹蛇將", "萬竹蛇王"],
		"cooldowns": [8.0, 7.5, 7.0, 6.25, 5.5], "normal_damage": [1, 1, 2, 2, 2], "heavy_damage": [2, 3, 3, 4, 5],
		"heavy_effect": {"kind": "mask", "values": [1, 1, 1, 1, 1], "duration": 3.0},
	},
	{
		"family": "jade_tortoise", "names": ["玉背龜", "石紋玉龜", "碧甲玉龜", "鎮池玉龜", "玄玉龜王"],
		"cooldowns": [10.5, 10.0, 9.5, 9.0, 8.0], "normal_damage": [1, 1, 1, 2, 2], "heavy_damage": [2, 3, 3, 4, 4],
		"normal_effect": {"kind": "armour", "values": [2, 2, 2, 3, 3]},
		"heavy_effect": {"kind": "freeze", "values": [1, 1, 1, 1, 1], "duration": 2.0},
	},
	{
		"family": "paper_lion", "names": ["紙獅仔", "紅鬚紙獅", "彩鼓醒獅", "金髯醒獅", "飛躍紙獅王"],
		"cooldowns": [9.25, 8.75, 8.25, 7.75, 7.0], "normal_damage": [2, 2, 2, 3, 3], "heavy_damage": [3, 4, 4, 5, 6],
		"heavy_effect": {"kind": "enrage", "values": [2, 2, 2, 2, 2]},
	},
	{
		"family": "cloud_rabbit", "names": ["棉雲兔", "跳雲兔", "紫霞雲兔", "捲雲飛兔", "望星兔仙"],
		"cooldowns": [7.75, 7.25, 6.75, 6.25, 5.75], "normal_damage": [1, 1, 1, 1, 2], "heavy_damage": [2, 2, 3, 3, 4],
		"normal_effect": {"kind": "gust", "values": [1, 1, 1, 2, 2]},
		"heavy_effect": {"kind": "rotate", "values": [1, 1, 1, 1, 1], "duration": 2.0},
	},
	{
		"family": "citrus_beetle", "names": ["柑殼甲蟲", "青葉甲蟲", "蜜橙甲蟲", "金皮甲蟲", "金柑蟲王"],
		"cooldowns": [8.5, 8.0, 7.5, 7.0, 6.5], "normal_damage": [1, 1, 2, 2, 2], "heavy_damage": [2, 2, 3, 4, 4],
		"normal_effect": {"kind": "restore", "values": [1, 1, 2, 2, 3]},
		"heavy_effect": {"kind": "drain", "values": [1, 1, 1, 2, 2]},
	},
	{
		"family": "river_otter", "names": ["溪水獺", "浪花水獺", "踏浪水獺", "長流水獺", "激流獺王"],
		"cooldowns": [8.75, 8.25, 7.75, 7.0, 6.25], "normal_damage": [1, 1, 2, 2, 2], "heavy_damage": [3, 3, 4, 4, 5],
		"normal_effect": {"kind": "gust", "values": [1, 1, 1, 1, 2]},
		"heavy_effect": {"kind": "current", "values": [1, 1, 1, 1, 1]},
	},
	{
		"family": "moon_moth", "names": ["月光蛾", "新月銀蛾", "半月光蛾", "滿月銀蛾", "月蝕蛾后"],
		"cooldowns": [8.5, 8.0, 7.5, 7.0, 6.25], "normal_damage": [1, 1, 1, 2, 2], "heavy_damage": [1, 2, 2, 3, 3],
		"heavy_effect": {"kind": "dim", "values": [1, 1, 1, 1, 1], "duration": 2.0},
	},
	{
		"family": "stone_elephant", "names": ["石鼻象", "青石象", "巨岩石象", "山壁巨象", "鎮山象王"],
		"cooldowns": [11.0, 10.5, 10.0, 9.0, 8.25], "normal_damage": [2, 2, 3, 3, 3], "heavy_damage": [3, 4, 5, 5, 6],
		"heavy_effect": {"kind": "rocks", "values": [0.10, 0.15, 0.20, 0.25, 0.30], "duration": 3.0},
	},
]

# This opponent appears once, beyond the five randomised stages.
const DARK_DRAGON: Dictionary = {
	"family": "dark_dragon", "id": "dark_dragon", "stage_form": 1, "name": "燼夜黑龍",
	"max_hp": 150, "cooldown": 6.0, "damage": 3, "heavy_damage": 5, "rematch": false,
	"normal_effect": {}, "heavy_effect": {"kind": "incinerate", "value": 1, "duration": 0.0},
}


static func form(family: Dictionary, stage: int, rematch: bool = false) -> Dictionary:
	var index: int = stage - 1
	return {
		"family": family["family"],
		"id": "%s_%d" % [family["family"], stage],
		"stage_form": stage,
		"name": family["names"][index],
		"max_hp": STAGE_HP[index] + (REMATCH_HP_BONUS if rematch else 0),
		"cooldown": family["cooldowns"][index],
		"damage": family["normal_damage"][index],
		"heavy_damage": family["heavy_damage"][index],
		"normal_effect": _effect_at(family.get("normal_effect", {}), index),
		"heavy_effect": _effect_at(family.get("heavy_effect", {}), index),
		"rematch": rematch,
	}


static func _effect_at(definition: Dictionary, index: int) -> Dictionary:
	if definition.is_empty():
		return {}
	return {"kind": definition["kind"], "value": definition["values"][index], "duration": definition.get("duration", 0.0)}
