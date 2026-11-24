# Midnight Chalk boss sprites

The original paper swallow, armoured guardian and bronze bell poses were produced for this project with the built-in ImageGen tool. Each transparent silhouette was isolated from the generated atlas, resampled onto a 100 × 74 grid, and mapped to a fixed family palette of 12 to 14 opaque colors. The base and rematch poses have separate sprites. Godot adds nearest-neighbour rendering, idle motion, recoil, a short impact tint and the floor shadow at runtime.

## Atlas generation prompt

Use case: stylized-concept. Production asset: one horizontal retro pixel boss sprite atlas, 3 columns × 2 rows of equally sized cells with a centered isolated character in each cell, transparent sheet, invisible grid, transparent gutters, no text, scenery or labels. Exactly six full-body poses, all completely separate. Original cute formidable enemies for a Hong Kong primary school game called Midnight Chalk. High contrast expressive 16-bit JRPG pixel art, confident sharp silhouettes and true economical clusters of square pixels at approx 80x68 native pixels per character, alert poses, sparse cream lighting from upper left on very dark eggplant shadows for use against midnight black. Top row BASIC bosses left to right: (1) paper swallow kite with upturned wings, cream-and-mint face markings, long flowing knotted ribbon tail, pointed tucked feet; (2) squat, broad armoured guardian with enormous pauldrons and gauntlets, chunky helmet, large glowing violet eyes in black angular visor, no human face, ivory/blue-violet steel with a violet plume, short legs, forward protective stance; (3) lively floating Chinese temple bronze bell spirit, shaded amber bronze body, engraved lip, intense two eyes in dark opening, tasselled crown loop, clearly visible swinging clapper and copper ribbon hands. Bottom row same order upgraded rematches: same kite with a split swallow tail and stronger layered wings in jade and ivory, same armored knight with imposing crescent helmet crest and heavier shoulder plates deep lilac and ivory, same bell with two side chimes and a forked red-purple tassel on the crown. Eye expressions, personality, asymmetry and artistic quality comparable to a beautifully crafted commercial indie RPG. Child-friendly, playful not terrifying. Character bodies have opaque materials. No ground or shadows, no surrounding scenery, no letters, no boxes or UI, no blur or gradient.

## Brush fox and lantern koi

The five-stage version adds a second transparent ImageGen atlas. The four poses are a young fox with a calligraphy-brush tail, a lantern-bodied koi with a tassel, a two-brush fox with vermilion ink and a golden dragon koi with whiskers. Each pose was isolated from its quadrant, reduced to the same 100 × 74 game canvas and exported with a limited palette and a binary alpha mask.

## Fifteen five-stage families

The current campaign uses 75 original images. Each family was generated as a separate five-form transparent sheet using built-in ImageGen. The shipped sprites are in `stages/<family>/s1.png` through `s5.png`. Each 100 × 74 image uses a transparent background and a shared family palette of up to 22 opaque colors. The game catalogue supplies the Traditional Chinese display names used for the atlas labels.

### Generation prompts

The following instruction started each of the 15 generation prompts. The corresponding family passage followed it.

Use case: stylized-concept. Production game sprite sheet for a sparse retro JRPG battle on BLACK, Midnight Chalk. Create ONE sprite atlas of exactly FIVE distinct stages of the SAME original monster family. 3 columns by 2 rows in a 3:2 landscape image: TOP ROW stages 1,2,3 left to right, BOTTOM ROW stages 4 and 5, then bottom RIGHT EMPTY. Exactly one isolated full-body sprite per occupied cell. Spacious transparent margins between all bodies, paws, tails, wings and equipment; never overlap neighboring sprites; every silhouette fully in its own cell. No attached ground, terrain, detached decoration, poster design, numbers, words, character labels, frames, logo, or grid lines. Background genuinely transparent. Pixel-art with confident readable square clusters like hand-authored premium 16-bit sprites, vivid ivory edge lights against rich midnight-plum shadows, restricted family-specific hues, big expressive faces and lively posing. Strongly differentiate stages by attached new structures and progressively unique outlines, NOT by hue alone; slight 3/4 view, family resemblance, child friendly, no gore, no human faces. Each sprite should hold its shape even when reduced to 72 pixels high.

#### wind

Family: a jade and ivory Chinese paper swallow kite spirit, perky triangular beak and visible bamboo spars.
Five occupied cells in reading order:
1. single knotted tail and folded triangular wings
2. long forked ribbon tail and vivid crimson bow
3. two broad swept wings with carved cream cloud motifs and a double tail
4. four layered wing sails with wind ribbons wound around the body
5. crowned sky-empress swallow kite with expansive split wings and five streaming brush-tipped tails.

#### armour

Family: a violet and chalk-white armoured guardian, two expressive bright violet eyes in a black visor, huge fists, short legs, no human face.
Five occupied cells in reading order:
1. compact helmet and simple pauldrons
2. high violet plume and one massive gauntlet
3. moon-shaped helmet crest and dual engraved pauldrons
4. layered cape, angular helm fins and wide tower-gauntlets
5. regal luminous crescent crown, flared ivory armour, purple mantle and star-shaped pauldrons.

#### bell

Family: an animate Chinese bronze temple bell spirit with bright eyes beneath its bell crown, ribbon hands and a visible clapper.
Five occupied cells in reading order:
1. small smooth bronze bell with round loop
2. large bell with a vermilion tassel and broad bronze lip
3. triple-bell spirit with two hanging side chimes
4. weathered jade and bronze bell with arc-shaped carrying yoke
5. majestic golden bell crowned with a miniature pavilion and a ring of distinct flanking chimes.

#### ink_fox

Family: a mischievous ink-and-ivory calligraphy fox, sharply pointed ears, paws tipped as brush nibs, vivid vermilion ear accents.
Five occupied cells in reading order:
1. single brush tail curled around one paw
2. two inkbrush tails and a red neck knot
3. three curling brush tails, pale ink markings, sash
4. five spread brush tails and a flowing calligraphic cape
5. majestic nine-brush-tailed white-ink fox, bright seal-red forehead jewel and fan-shaped ink tails.

#### lantern_koi

Family: a lantern-like floating vermilion, cream, and gold koi fish, lively eye, carp whiskers and paper-lantern fins.
Five occupied cells in reading order:
1. small goldfish-shaped koi with a single paper tassel
2. broad red lantern belly and two ribbon fins
3. ornate gold koi with forked tail and paired dangling lantern tassels
4. giant scarlet koi with dragon whiskers and raised scalloped lantern crest
5. celestial long-finned golden dragon-koi with horned crest and five visible lantern streamers.

#### clockwork_crab

Family: a clockwork crab with bronze geared claws, expressive eye stalks, riveted deep teal shell, child-friendly.
Five occupied cells in reading order:
1. little brass crab with simple pincers
2. crab with one exposed large gear pincer and winding key
3. two toothed claw wheels and a domed clock shell
4. broad clockwork crab with twin mainsprings and gear-shield carapace
5. regal immense gear crab with elaborate turret crown, twin giant spoked claws and pendulum.

#### porcelain_cat

Family: a glossy blue-and-white Chinese porcelain cat spirit with cobalt floral brush details, rosy nose, lively dark eyes.
Five occupied cells in reading order:
1. small seated porcelain kitten with a curly handle tail
2. porcelain cat with upright tail, ceramic ruff and jade bell
3. poised large teacup cat with curled handles and floral body
4. tall porcelain guardian cat with pottery shoulder plates and three scroll tails
5. grand crowned cobalt-and-white ceramic guardian cat with enormous fanned tails and baluster-vase collar.

#### bamboo_snake

Family: a jade-green bamboo-jointed serpent with leaf-shaped brows and yellow eyes, curious confident face.
Five occupied cells in reading order:
1. tiny snake coiled round one bamboo shoot
2. bamboo-jointed snake with paired leaf whiskers
3. taller hooded snake with broad bamboo-leaf fan and ringed trunk
4. large spiral bamboo snake with knotted staff-like crest and flaring bamboo-leaf frill
5. ancient jade bamboo-dragon serpent crowned with tall bamboo canopy and sweeping split leaf fins.

#### jade_tortoise

Family: a friendly but determined carved-jade tortoise, warm yellow eyes, broad feet, a shell of angular mineral plates.
Five occupied cells in reading order:
1. small smooth jade tortoise with one spiral shell carving
2. larger tortoise with a scalloped shell and little jade horns
3. heavy tortoise with six raised gemstone plates and angular crest
4. stout guardian carrying a jade gate arch carved into its shell
5. ancient jade mountain tortoise carrying a stepped jade hill and pagoda on its shell.

#### paper_lion

Family: an animated Hong Kong festival paper lion, huge expressive hinged eyes, vermilion and ivory paper-cut mane, gold details.
Five occupied cells in reading order:
1. small bright playful lion head and short patchwork body
2. red-and-gold lion with jaunty eyebrow pom-poms and a ruffled tail
3. drum-dance lion with twin forehead fans and thick layered waist cloth
4. leaping fire-red lion with long layered petal mane and brocade train
5. imperial gold-and-crimson festival lion with a sculpted headdress and a spectacular fan-shaped tail.

#### cloud_rabbit

Family: a moonlit white and lilac cloud rabbit spirit, plump expressive cheeks, long ears, fluffy cloud-swirled feet.
Five occupied cells in reading order:
1. small ivory rabbit with cloud puff tail
2. large lilac-tipped ears, paired cloud sandals and crescent charm
3. bounding hare with a curling cloud mane and long misty scarf
4. long-eared cloud rabbit astride a curled storm-cloud cushion, star forehead
5. celestial moon-cloud rabbit with a crescent halo and towering tiered cloud plume.

#### citrus_beetle

Family: a charismatic Hong Kong tangerine beetle creature with bright orange-peel wing cases, green citrus leaf antennae, dark eyes.
Five occupied cells in reading order:
1. round tangerine bug with one leaf and tiny feet
2. glossy two-winged beetle with thick leaf antennae and pebbled rind
3. orange stag beetle with forked branch-like mandibles and opened shell
4. sturdy rhinoceros beetle with a tall citrus twig horn and leaf shoulder guards
5. kingly orange-and-gold citrus beetle with a leafy crown, fan-shaped wing covers and enormous forked horn.

#### river_otter

Family: a friendly blue-brown river otter spirit with cream muzzle, turquoise river markings, active paws, flowing webbed tail.
Five occupied cells in reading order:
1. small otter clutching a river pebble
2. playful otter wearing a knotted blue river scarf and holding two stones
3. upright otter with a shelllike river shield and swirling turquoise tail
4. river guardian otter with a broad reed cape, water ribbons and a spiral spear-like reed
5. majestic blue river otter with an enormous curling wave tail and a pearl-studded reed crown.

#### moon_moth

Family: a silver and lilac moon moth with expressive large dark insect eyes, delicate pale antennae, broad lunar-patterned wings.
Five occupied cells in reading order:
1. small round moth with two crescent-spotted wings
2. crescent moth with elongated lower wing tips and two feathered antennae
3. wide silver four-winged moth with bold lunar disc eyespots
4. eclipse moth with sharply scalloped layered wings and a dark crescent head crest
5. regal lunar moth with a triple-tier silver wing silhouette, five moonphase eyespots and long ribbon tails.

#### stone_elephant

Family: a gentle but formidable temple stone elephant with carved charcoal-gray masonry plates, cream tusks and luminous jade eyes.
Five occupied cells in reading order:
1. small stone calf with rough square feet and a rounded trunk
2. masonry elephant with short tusks and a carved shoulder collar
3. larger stone elephant with square armor plates and jade-inlaid forehead
4. tusked gatekeeper elephant with sculpted bracket ears and arched saddle
5. grand mountain elephant carrying a miniature stone watchtower, ornate long tusks and tall jade crest.

## Final encounter

燼夜黑龍 was generated separately with ImageGen as a transparent pixel-art sprite. The prompt called for a coiled Chinese dragon with a charcoal and indigo body, lavender edge lighting, antique-gold antlers, pale whiskers and an ember-orange belly. The final game sprite is a 100 × 74 RGBA image with 22 opaque palette entries in `stages/dark_dragon/s1.png`.
