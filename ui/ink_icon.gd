extends Control

const INK := Color("#fffdf4")
const VIOLET := Color("#c9acfb")
const GOLD := Color("#ffce60")
const ROSE := Color("#ff8395")
const MINT := Color("#95d8c5")
const STAMPS := {
	# Each silhouette also reads as a single-colour stamp at small card sizes.
	"power_heavy": [
		"...........WWW", "..........WGGW", ".........WGGGW", ".....G..WGGGW.",
		"...GGG.WGGGW..", "....GGWGGGW...", "....WGGGGW.G..", "...WGGGW..GG..",
		"....GGGWGGGG..", "...G.WW..G....", "..GG..........", ".GG..G........",
		"GW..G.........", "W............."],
	"power_ward": [
		"......WW......", "....WWVVWW....", "..WWVVVVVVWW..", ".WVVVVWWVVVVW.",
		".WVVVWWWWVVVW.", ".WVWWVVVVWWVW.", ".WVVVVWWVVVVW.", "..WVVVWWVVVW..",
		"..WVVVWWVVVW..", "...WVVWWVVW...", "....WVVVVW....", ".....WVVW.....",
		"......WW......", ".............."],
	"power_delay": [
		".WWWWWWWWWWWW.", ".MMMMMMMMMMMM.", "...W......W...", "...W.MMMM.W...",
		"....W.MM.W....", ".....W..W.....", "......WW......", "......WW......",
		".....W..W.....", "....W.MM.W....", "...W.MMMM.W...", "...WMMMMMMW...",
		".MMMMMMMMMMMM.", ".WWWWWWWWWWWW."],
	"power_heal": [
		"......WW......", ".....WMMW.....", ".....WMMW.....", ".....WMMW.....",
		"..WWWWMMWWWW..", ".WMMMMMMMMMMW.", ".WMMMMMMMMMMW.", "..WWWWMMWWWW..",
		".....WMMW.....", ".....WMMW.....", ".....WMMW.....", "......WW......",
		".MM.......MM..", "..MMM...MMM..."],
	"chest_open": [
		"....WWWWWWWW..", "...WGGGGGGGGS.", "..WGGSSSSSGGS.", "..WGGSSSSSGGS.",
		"...SSSSSSSSS..", "......W....G..", "...G.WGW..W...", ".GGGGGGGGGGGG.",
		"GGSSSSSSSSSSGG", "SGGGGGWWGGGGGS", "SGSSSSWWSSSSGS", "SGSSSSSSSSSSGS",
		".GGGGGGGGGGGG.", "..SSSSSSSSSS.."],
	"item_attack": [
		"..........W...", ".........WWW..", ".......WWWWWWW", "....WWWWWGW...",
		"...WRRRRRWW...", "..WRRWWRRRSW..", ".WRRWWRRRSRSW.", "WRRRRRRRSSRRRW",
		"WRRRRRSSSSRRRS", ".WRRRSSSSRRRSS", ".WRRSSSSRRRSS.", "..WRSSSRRRSS..",
		"...WSSSSSSS...", "....WWWWWW...."],
	"item_energy": [
		"......WW......", ".....WMMW.....", "....WMMWMW....", "...WMMWGWMW...",
		"..WMMWGGMMMW..", "..WMWGGMWWMW..", "..WMWGGGGWMW..", "..WWWGGGGWWW..",
		"..WMMMWGGWMW..", "...WMWGGWMW...", "....WWGWMW....", ".....WWMW.....",
		"......WW......", ".............."],
	"item_heal": [
		"....SSSSSS....", "....SGGGGS....", "....WWWWWW....", ".....W..W.....",
		"....W....W....", "...W......W...", "..WRRRRRRRRW..", ".WRRWWRRRRRRW.",
		".WRRWWRWWRRRW.", ".WRRRRWWWWRRW.", ".WRRRRRWWRRRW.", "..WRRRRRRRRW..",
		"...WRRRRRRW...", "....WWWWWW...."],
	"power_mark": [
		"......WWW.....", ".....WRRRW....", ".....WRRRW....", ".....WRRRW....",
		"......RRR.....", "....WWWWWWW...", "...WRRRRRRRW..", "..WRRRRRRRRW..",
		".WRSSGSRSSSRW.", ".WRSGGSRSSSRW.", ".WRSSSSRRRSRW.", ".WRRRRRRRRRRW.",
		".WWWWWWWWWWWW.", ".............."],
	"power_break_charge": [
		"........WWWWW.", ".......WGGGW..", "......WGGGW...", "......WGGGW...",
		".....WGGGWWW..", "....WGGGGGW...", "...WWWWGGW....", ".....VWGW.V..V",
		"V....WGW..V.VV", "VVV.VWW..VVVVV", ".VVVWWV..VVVV.", ".VVVWVV.VVVVV.",
		"..VVVVV..VVVV.", "..V......V...."],
	"power_mirror": [
		"......WWWW....", ".....WVWWWW...", "....WVWMWMWW..", "...WVWMWMMMWW.",
		"...WVWWMMMMWW.", "...WVWMMMMVWW.", "...WVVWMMVWVW.", "....WVVWVWVW..",
		".....WVVVVW...", "....WVWWWW....", "...WVVVW......", "..WVVVW.......",
		".WWVWW........", "...W.........."],
	"power_slow": [
		"..............", "......WWW.....", "....WWWWWW....", "....WWWWWWWW..",
		"..W.WWMWMWWW..", ".WMWWWMWMWMW..", "..WMWMMMMMMW..", "...WMMMMMMW...",
		"....WMMMMMW...", ".....WWWWW....", "..MMM......MM.", "MM...MMMMMM...",
		"....VVV.....VV", "..VV...VVVVV.."],
	"power_cleanse": [
		"..........G...", ".........GSGG.", ".G.......GSG..", "GGG.....GSSG..",
		".G.....GSSG...", "......GSSG....", "......GSG.....", ".....WGSG.....",
		"....WMWW......", "...WMMW.....V.", "..WMMMW..VV...", "..WMWW..V.....",
		".WWW..........", ".W............"],
	"power_comeback": [
		".....R......W.", ".....RR.....W.", "...RRRRRR..WW.", "..R..RR....WW.",
		".R...R....WWW.", ".R.......WWW..", ".R.....WWWMW..", ".R....WWMMW...",
		"...G.WWMWWW...", "..GGGWMWW.....", "..SGGGW.......", ".SSSGGG.......",
		"SSS..GGG......", "SS....G......."],
	"power_stars": [
		"..........G...", "...G......G...", "...G....GGWGG.", ".GGWGG....G...",
		"...G......G...", "...G....V.....", "..V....V.G....", ".V.....V.G....",
		".V....VGGWGG..", "V........G....", ".........G....", ".......V......",
		"......V.......", ".....V........"],
	"power_reject_flame": [
		".......G......", "......GG......", "......GG......", ".....GRG...G..",
		"...G.GRG..GG..", "..GRGRRRG.GRG.", "..GRGRRRRWRRG.", ".GRRRRWRWWWRG.",
		".GRRRWWWWWRRG.", ".GRRRRWWWRRRG.", "..GRRWWWWWRRG.", "..GRRRWRWWWG..",
		"...GGRRRRWG...", ".....GGGGG...."],
	"item_hourglass": [
		"..GGGGGGGGGG..", "..GGGGGGGGGG..", "...W......W...", "...WMMMMMMW...",
		"...W.MMMM.W...", "....W....W....", ".....W..W.....", "......WW......",
		".....W.GW.....", "....W.GGGW....", "...W.GGGG.W...", "...WGGGGGGW...",
		"..GGGGGGGGGG..", "..GGGGGGGGGG.."],
	"item_fan": [
		"..............", ".....WWWWW....", "...WMVVMVVWW..", ".WWVMVVMVVVMW.",
		"WVVVMVVMVVMVW.", "WMVVVMVMVVMVMW", "WVMVVMVMVMVMVW", "WVVMVMMVVMMVW.",
		".WVMVMMVMMVW..", "..WWMVMMMWW...", "....WMSMW.....", ".....SGS......",
		".....SS.......", "....SSS......."],
	"item_lantern": [
		"......GGG.....", ".....G...G....", "....G.....G...", "..WWWWWWWWWW..",
		"..WWWWWWWWWW..", "...SSWWSRSS...", "...SGWWGRGGS..", "..SGGWWGRGGS..",
		"..SGGWWGRGGS..", "...SGWWGRGS...", "...SSSSSRSS...", "...GGGGGGGG...",
		"......R.......", "......R.R....."],
	"item_clip": [
		"...WW....WW...", "..W..W..W..W..", "..W..W..W..W..", "..W..W..W..W..",
		"...WW....WW...", "....W....W....", "...WWWWWWWW...", "...WMMMMMMMW..",
		"..WMWWWWWMMW..", "..WMMMMMMMMMW.", ".WMMMMMMMMMMW.", ".WVVVVVVVVVVW.",
		".WWWWWWWWWWWW.", ".............."],
	"item_calm": [
		"......GG......", ".....G..G.....", ".....G..G.....", "....WWWWWW....",
		"...WRRRRRRW...", "..WRRRGRRRRW..", "..WRRGRGGRRW..", "..WRGRRRRGRW..",
		"..WRRGRGGRRW..", "..WRRRGRRRRW..", "..WWRRRRRRRW..", "....WWWWWWW...",
		".....G..R.....", ".....G..R....."],
	"item_umbrella": [
		".......G......", ".......G......", ".....WWWW.....", "...WWMVMVWW...",
		"..WMMVMMMVMW..", ".WMMMVMMMVMMW.", ".WMMVMMMMMVMW.", "WWMMWWMMWWMWWW",
		"..WW..WW..W...", ".......G......", ".......G......", ".......G......",
		"...G...G......", "....GGG......."],
	"item_bell": [
		"......WW......", ".....WGGW.....", ".....WGGW.....", ".....WWWW.....",
		"....WGWGGW....", "....WWGGGGW...", "...WWGGGGGW...", "...WGGGGGGGW..",
		"...WSSSSSSGW..", "..WGGGGGGGGW..", ".WGGGGGGGGGGW.", ".WWWWWWWWWWWW.",
		".....WWWW.....", "......G......."],
	"item_bounty": [
		"...GG...GG....", "...GSGGGSSG...", "...GSSSSSG....", "....GSSSSG....",
		"....WWWWWW....", "....GGGGGG....", "...GSSSSSSG...", "..GSSSWWSSSG..",
		"..GSSWGGWSSG..", ".GSSWGSSGWSSG.", ".GSSWGSSGWSSG.", ".GSSSWGGWSSG..",
		".GGSSSWWSSGG..", "...GGGGGGG...."],
	"discard": [
		"......WW......", ".....W..W.....", ".....W.....R..", ".......RRRRR..",
		"...RRRRR......", "...R..........", "..WWWWWWWWWW..", "..WRRRRRRRRW..",
		"..WRRSRRSRRW..", "..WRRSRRSRW...", "...WRSRRSRW...", "...WRSRRSRW...",
		"...WRRRRRRW...", "....WWWWWW...."],
	"coin": [
		"....GGGGGG....", "..GGWWWWGGGG..", ".GWWGGGGGGSSG.", ".GWGGGGGGGSSG.",
		"GWWGGGGGGGGSSG", "GWGGGWWWWGGSSG", "GWGGGW..SGGSSG", "GWGGGW..SGGSSG",
		"GWGGGSSSSGGSSG", ".GWGGGGGGGSSG.", ".GGGGGGGGSSSG.", "..GGGSSSSSSG..",
		"....GGGGGG....", ".............."],
	"reward_boss": [
		"..............", "..WW......WW..", ".WVVW....WVVW.", ".WVVVWWWWVVVW.",
		"..WVVVVVVVVW..", "..WVVVVVVVVW..", "..WVVWWWWVVW..", ".WVVW....WVVW.",
		".WVVW.WW.WVVW.", ".WVVVWWWWVVVW.", "..WVVVVVVVVW..", "...WVVWWVVW...",
		"....WW..WW....", ".............."]
}
const PIXELS := {"W": INK, "G": GOLD, "S": Color("#a77536"), "V": VIOLET, "M": MINT, "R": ROSE}

var icon := "":
	set(next):
		icon = next
		queue_redraw()


func _draw() -> void:
	var stamp := icon
	if icon == "reward_time" or icon == "time":
		stamp = "power_delay"
	elif icon == "reward_health" or icon == "hp":
		stamp = "power_heal"
	elif icon == "item_shield":
		stamp = "power_ward"
	if STAMPS.has(stamp):
		_draw_stamp(STAMPS[stamp])
		return
	var factor := minf(size.x, size.y) / 26.0
	if icon == "reject":
		factor = minf(size.x / 47.0, size.y / 23.0)
	if factor <= 0.0:
		return
	draw_set_transform((size * 0.5).round(), 0.0, Vector2.ONE * factor)
	match icon:
		"reject":
			draw_polyline(PackedVector2Array([Vector2(-13, -7), Vector2(-22, -7), Vector2(-22, 5), Vector2(-10, 5), Vector2(-10, -2), Vector2(-13, -2), Vector2(-13, -7)]), INK, 1.4)
			draw_polyline(PackedVector2Array([Vector2(11, -5), Vector2(22, -5), Vector2(22, 7), Vector2(10, 7), Vector2(10, 0), Vector2(13, 0), Vector2(13, -5)]), INK, 1.4)
			draw_line(Vector2(-4, -4), Vector2(4, 4), VIOLET, 2.0)
			draw_line(Vector2(-4, 4), Vector2(4, -4), VIOLET, 2.0)
		"energy", "bolt":
			draw_colored_polygon(PackedVector2Array([Vector2(2, -10), Vector2(-7, 2), Vector2(-1, 2), Vector2(-3, 10), Vector2(8, -3), Vector2(1, -3)]), GOLD)
		"shop_attack":
			# The ordinary player shot has a mint nib, pale point and a broken trail.
			draw_rect(Rect2(-11, 8, 2, 2), Color("#508f83"))
			draw_rect(Rect2(-8, 5, 3, 3), Color("#508f83"))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 4), Vector2(5, -6), Vector2(10, -8), Vector2(8, -3), Vector2(-2, 7)]), MINT)
			draw_colored_polygon(PackedVector2Array([Vector2(4, -4), Vector2(7, -7), Vector2(10, -8), Vector2(9, -5), Vector2(6, -2)]), INK)
		"chest_time":
			draw_rect(Rect2(-11, -7, 17, 13), GOLD)
			draw_rect(Rect2(-9, -5, 13, 9), Color("#866236"))
			draw_rect(Rect2(-10, -2, 15, 2), GOLD)
			draw_rect(Rect2(-4, -2, 3, 4), INK)
			# The small hourglass ties the five-point increase to the chest timer.
			draw_rect(Rect2(0, -2, 12, 15), Color("#10131b"))
			draw_rect(Rect2(1, -1, 10, 2), MINT)
			draw_rect(Rect2(1, 10, 10, 2), MINT)
			draw_polyline(PackedVector2Array([Vector2(3, 1), Vector2(3, 3), Vector2(8, 7), Vector2(8, 9)]), INK, 1.6)
			draw_polyline(PackedVector2Array([Vector2(9, 1), Vector2(9, 3), Vector2(4, 7), Vector2(4, 9)]), INK, 1.6)
		"shop":
			draw_rect(Rect2(-10, -5, 20, 3), INK)
			draw_rect(Rect2(-9, -9, 18, 5), GOLD)
			for x in [-6, 0, 6]:
				draw_rect(Rect2(x - 1, -9, 3, 7), ROSE)
			draw_rect(Rect2(-9, -1, 2, 9), INK)
			draw_rect(Rect2(7, -1, 2, 9), INK)
			draw_rect(Rect2(-10, 6, 20, 3), GOLD)
		"stage_clear":
			draw_rect(Rect2(-7, -9, 2, 18), INK)
			draw_rect(Rect2(-8, 8, 7, 2), INK)
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -8), Vector2(9, -8), Vector2(5, -4), Vector2(9, 0), Vector2(-5, 0)]), GOLD)
		"purchased":
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(-7, -3), Vector2(-2, 2), Vector2(7, -7), Vector2(10, -4), Vector2(-2, 8)]), MINT)
		"continue":
			draw_colored_polygon(PackedVector2Array([Vector2(-9, -2), Vector2(1, -2), Vector2(1, -6), Vector2(9, 0), Vector2(1, 6), Vector2(1, 2), Vector2(-9, 2)]), INK)
		"pause":
			draw_rect(Rect2(-7, -8, 5, 16), INK)
			draw_rect(Rect2(2, -8, 5, 16), INK)
		"cooldown", "clock":
			draw_rect(Rect2(-7, -9, 14, 2), MINT)
			draw_rect(Rect2(-7, 7, 14, 2), MINT)
			draw_polyline(PackedVector2Array([Vector2(-5, -7), Vector2(-5, -4), Vector2(4, 4), Vector2(4, 7)]), MINT, 1.8)
			draw_polyline(PackedVector2Array([Vector2(5, -7), Vector2(5, -4), Vector2(-4, 4), Vector2(-4, 7)]), MINT, 1.8)
			draw_rect(Rect2(-2, 5, 4, 2), INK)
		"foe_charge", "charge":
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(-2, -4), Vector2(1, -10), Vector2(4, -4), Vector2(9, -6), Vector2(7, 3), Vector2(0, 9), Vector2(-7, 3)]), VIOLET)
			draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(0, 2), Vector2(4, -1), Vector2(2, 4), Vector2(-1, 5)]), Color("#38233e"))
		"bag", "items":
			draw_rect(Rect2(-4, -8, 8, 4), INK, false, 2)
			draw_rect(Rect2(-8, -4, 16, 12), INK, false, 2)
			draw_rect(Rect2(-8, 0, 16, 2), INK)
			draw_rect(Rect2(-2, -1, 4, 5), VIOLET)
		"empty":
			draw_rect(Rect2(-3, -1, 6, 2), Color("#665d73"))
		"health":
			draw_rect(Rect2(-3, -8, 6, 16), ROSE)
			draw_rect(Rect2(-8, -3, 16, 6), ROSE)
		"shield":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(8, -5), Vector2(7, 3), Vector2(0, 9), Vector2(-7, 3), Vector2(-8, -5)]), VIOLET)
			draw_line(Vector2(0, -5), Vector2(0, 5), INK, 1.5)
		"attack":
			draw_line(Vector2(-5, 7), Vector2(7, -7), GOLD, 3)
			draw_line(Vector2(-7, 0), Vector2(0, 6), INK, 2)
		"heal":
			draw_rect(Rect2(-3, -9, 6, 5), INK)
			draw_rect(Rect2(-7, -4, 14, 12), ROSE)
			draw_line(Vector2(-4, 1), Vector2(4, 1), INK, 1.5)
		"chest":
			draw_rect(Rect2(-8, -7, 16, 2), GOLD)
			draw_rect(Rect2(-10, -5, 20, 12), GOLD, false, 2)
			draw_rect(Rect2(-9, -1, 18, 2), GOLD)
			draw_rect(Rect2(-2, -2, 4, 5), INK)


func _draw_stamp(rows: Array) -> void:
	var cell := minf(size.x, size.y) / 16.0
	if cell <= 0.0:
		return
	var start := (size - Vector2(14, 14) * cell) * 0.5
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var tint: Variant = PIXELS.get(row[x])
			if tint != null:
				var at := (start + Vector2(x, y) * cell).round()
				var end := (start + Vector2(x + 1, y + 1) * cell).round()
				draw_rect(Rect2(at, end - at), tint)
