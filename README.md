# Midnight Chalk · 字陣

[Play 字陣](https://cfsthk.github.io/midnight-chalk/) · [教師手冊](https://cfsthk.github.io/midnight-chalk/teacher/handbook.html) · [下載手冊 PDF](https://cfsthk.github.io/midnight-chalk/teacher/handbook.pdf) · [字庫審閱表 CSV](https://cfsthk.github.io/midnight-chalk/teacher/character-review.csv)

香港小學中文組字遊戲。選好必殺技後，點選落下的部件，再點中心字旁邊的方格。組字成功即可攻擊首領，並聽到該字的粵語讀音。

This Godot prototype covers the first P.4 **組字** playtest. It has twelve component decks, fifteen original boss families with five stage forms each, a one-off final dragon, and bundled synthetic Hong Kong Cantonese speech. A run has two bosses in each of five stages, four shops and a final dragon encounter, for eleven fights in total. Grade selection and the **組詞** mode are planned for later classroom builds.

## Play in Godot

Extract the project and open `project.godot` in Godot **4.7.2**. Run the main scene with **F6** when `main.tscn` is open, or the whole project with **F5**. [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)

### Battle controls

The game opens on three different special cards drawn from a pool of twelve. Choose one. Its icon and numbers show what it does. Selection starts the 3–2–1 countdown. The foe and its three gauges appear when the first components begin falling. The top-left row shows the level in bold, then the coin balance and chest countdown. **關卡 2-2** means the second fight in Stage 2. Two components enter at different heights and a third can join them. A full fall takes approximately 10.91, 10.45, 10.00, 9.55 and 9.09 seconds across the five stages. The marked tile is selected. Tap another falling tile to change selection, then tap a square around the anchor to place it. On a keyboard, 1–3 select the left, middle or right falling tile. The arrow keys place it, X marks it incompatible, and P or Esc pauses and resumes. The crossed-tile **不相配** button sits in the bottom-right cell of the anchor grid, directly below the right arrow and beside the down arrow. It has the same hit area as each placement square.

On phones and portrait screens, the boss has a taller arena. Falling tiles occupy the full left column beneath it. Across the top of the right column are horizontal HP and energy gauges and a row of three inventory slots. The anchor grid sits directly below them. On a landscape desktop or tablet, the anchor, falling tiles and player gauges occupy three adjacent panels. All boss forms face the pupil with their stance turned slightly towards the HP side.

On a correct placement the completed character appears in translucent green Kai script in the centre of the anchor board. Its strokes fade as it grows over 0.48 seconds. The game plays its Cantonese reading and launches a shot. Rapid matches queue their readings so clips can play in order. An incorrect placement flashes red. If a tile placed in the wrong slot or marked incompatible can make a character, an accepted slot shows the component, the complete character appears in red in the falling lane, and the tile leaves play. A documented alternate position outside the lesson brings up a familiar character in a light colour in the falling lane. The tile leaves play with both sides’ charge unchanged. Tile glyphs can return through normal rotation after at least three other drops. Correctly identifying a distinct incompatible tile sends a visible gold charge to the special gauge when it earns an energy point. Yellow flames surround the chosen special when it is ready. Tap the icon to fire it. The rose gauge beside it shows player HP. Tap a filled item slot to use the item.

The monster has separate health, heavy-attack and cooldown bars. An incorrect placement or deliberate rejection of a matchable component adds one enemy heavy charge. 安心符 protects the next two such judgements. If a matchable component falls out, its completed character expands and fades in red in the falling lane. Expiry grants neither side energy. At three charges the next scheduled shot uses that boss form’s heavy attack. Damage and any boss effect apply when the projectile reaches its target. Pause at the top right to freeze the fight and its clocks. Choose Restart in the pause menu to end the current run and return directly to a fresh draw of three special attacks. The top-left clock shows the time left to earn a chest.

An ordinary shot has a short launch tone and flashes the boss on impact. A heavy shot has a deeper impact, a gold flash and a stronger shake. The foe lunges towards the player and springs back when it fires. Losing HP sounds a descending tone. A damaging heavy hit also lights the player’s status panel. A shielded hit has its own block sound. Each of the twelve items has its own use cue. Buttons play a short click. Choosing a special starts *Inkbolt Rush*, an original 164 BPM battle theme in 4/4 with a legato lead, sustained bass and lighter percussion. Music and effects grow quieter during Cantonese readings. Pause freezes the score, and the 音樂 switch in the pause menu lets you turn off just the music.

### Bosses, rewards and shops

Stage 1 draws two different families. Each later stage opens with a family the pupil has yet to meet in this run. Its second fight revisits a family from an earlier stage, using the current stage’s name, sprite and attacks with two extra HP. No two consecutive encounters have the same boss family or anchor. Regular boss HP rises across the stages from **20 / 40 / 60 / 80 / 100**, and each family’s cooldown gets shorter. The [boss catalogue](game/boss_catalogue.gd) lists the damage, cooldown, effects and Chinese names of all 75 forms.

The fifteen heavy attacks have different classroom and combat effects. The paper swallow speeds falling tiles by 30–80% for three seconds and deals 3 damage. The ink fox covers the top 20–70% for three seconds and deals 1 / 1 / 2 / 2 / 3 damage. The elephant builds a rock wall over the bottom 10 / 15 / 20 / 25 / 30% for three seconds. The bell deals 4–7 direct damage. Other families steal an item, hide the anchor, freeze the fall, scramble selection, rotate or dim tile faces, move tiles sideways, take energy, gain armour, heal, or strengthen their next two normal shots. A regular unboosted placement deals two damage. Active armour lowers that base to one, and a pupil’s special clears the armour.

The five stage base awards are **5 / 8 / 11 / 15 / 20 coins** per foe. Each win also earns one coin per ten whole seconds left on the chest clock, up to four, and one per four remaining player HP, up to three. Clearing Stages 1–4 adds **15 / 24 / 33 / 45 coins** to the second boss’s payout before the shop. Using a 賞金袋 adds five coins on winning that fight. Stage 5 and the dragon use the ordinary victory payout. The chest clock starts at 45 seconds. Pupils can finish a fight after it runs out. The vitality bonus uses HP at the finishing impact. Each victory then restores full HP and preserves the pupil’s special charge and items. A chest draws three of twelve consumable items. With three slots full, tap one of four item icons to give it up. The first three show the held slots in order. The fourth is the incoming item. Identical items in different slots remain separate choices.

After **1-2, 2-2, 3-2 and 4-2**, the shop displays three different upgrades as icon cards. Each costs **10, 15, 20 or 25 coins** at the respective shop. Tap a card to buy it. Each card can be bought once per visit, so pupils with enough coins can take all three. The same upgrade can appear and stack in a later shop. The heavy-charge upgrade drops out of the draw once the energy cost reaches one. Use the arrow to continue.

| Shop upgrade | Effect per purchase |
|---|---|
| 生命上限 | +2 maximum HP |
| 攻擊力 | +1 damage to normal and special attacks |
| 防禦力 | −1 incoming HP damage, to a minimum of zero. Boss effects still apply. |
| 必殺技蓄能 | −1 energy required for a special, to a minimum of one |
| 寶箱限時 | +5 seconds on the chest clock |

After **5-2**, collect the usual payout and any earned chest, then face **燼夜黑龍**. The dragon has 150 HP and fires every six seconds. Its normal shot deals 3 damage. Its heavy deals 5 and, unless an open 防擾傘 protects the field, incinerates every tile still in the falling area at impact. Burned tiles give no charge or learning penalty. Defeating the dragon settles the final coins, plays the fireworks and opens the completion screen for all 11 victories. Coins and upgrades reset when a fresh run begins.

## Browser build

GitHub Pages serves the single-threaded Web export from the root of the `gh-pages` branch. To publish a new build, install the Godot 4.7.2 export templates and check out that branch in a sibling worktree. Run the following from the source project on `main`.

```sh
git worktree add ../midnight-chalk-site gh-pages
godot --headless --editor --import --quit
godot --headless --export-release Web ../midnight-chalk-site/index.html
```

Serve the site worktree with `python3 -m http.server --directory ../midnight-chalk-site 8000` for a local playtest. Commit and push the updated export on `gh-pages` to publish it. The site also carries the teaching materials and the asset licence notices. [Godot Web export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

## Content and checks

See `content/README.md` for the EDB, glyph and speech references. The twelve decks use **青、包、口、木、氵、扌、艹、日、女、土、火、禾** as anchors. Each family has ten screened incompatible components. The 318 accepted characters occur across 330 placements. A falling 今 above 口 makes 含 as in 含有. On the right it makes 吟 as in 吟詩. A falling 火 goes left of 包 for 炮 as in 鞭炮, and right of 禾 for 秋 as in 秋天. The bundled clips use Google’s Hong Kong Cantonese voice A from CanTone. Each result has an intended Jyutping reading, and the game preloads the encounter’s audio before battle. The main interface uses Hong Kong Traditional Chinese glyphs. The match animation uses 標楷體 when available and bundles Kai glyphs for devices that cannot supply that face. See `assets/` for the font and art credits.

From the project root, import with `godot --headless --editor --import --quit`, then run `godot --headless --script res://tests/verify_prototype.gd`, `godot --headless --script res://tests/verify_ui.gd`, `godot --headless --script res://tests/verify_sounds.gd` and `godot --headless --script res://tests/verify_combat_motion.gd`. Run the other scripts in `tests/` for the lesson-bank and equipment checks. The checks cover seeded routes, tile matching and spacing, speech assets, boss forms and timed effects, impact and coin timing, shop purchases, final payout, inventory and responsive layouts.
