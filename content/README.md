# 組字牌組 Character bank

Each fight fixes one anchor in the centre. Place the falling component above, below, left or right of it. Some components produce a different character when moved to another side.

| Fixed anchor | Falling tile | First placement | Another placement |
| --- | --- | --- | --- |
| 口 | 今 | Above → 含（含有） | Right → 吟（吟詩） |
| 口 | 隹 | Above → 售（售賣） | Right → 唯（唯一） |
| 木 | 甘 | Above → 某（某人） | Right → 柑（柑橘） |
| 木 | 隹 | Above → 集（集合） | Right → 椎（脊椎） |
| 日 | 京 | Below → 景（風景） | Right → 晾（晾衫） |
| 木 | 口 | Above → 呆（發呆） | Below → 杏（杏仁） |

A falling 火 goes left of 包 for 炮 or right of 禾 for 秋. With 火 fixed, 禾 goes left for 秋, 頁 goes right for 煩, and 林 goes above for 焚. Stacking two 火 in either order makes 炎. All of these examples preserve the four-stroke 火 shape, including the lower component of 焚.

## Family inventory

| Fixed anchor | Matchable tiles | Incompatible tiles | Accepted placements |
| --- | ---: | ---: | ---: |
| 青 | 10 | 10 | 10 |
| 包 | 12 | 10 | 12 |
| 口 | 32 | 10 | 37 |
| 木 | 32 | 10 | 36 |
| 氵 | 30 | 10 | 30 |
| 扌 | 30 | 10 | 30 |
| 艹 | 29 | 10 | 29 |
| 日 | 27 | 10 | 28 |
| 女 | 27 | 10 | 27 |
| 土 | 30 | 10 | 30 |
| 火 | 30 | 10 | 31 |
| 禾 | 30 | 10 | 30 |
| **Total** | **319** | **120** | **330** |

## Choosing classroom answers

We checked the previous 359 character forms against the Education Bureau’s primary lexical list, distinguishing entries in the main list from appendix entries. The revised bank includes 296 characters found in main P.1–P.6 entries and 22 additional characters with a familiar local or classroom use. The additional characters include 雹 in 冰雹, 嫦 in 嫦娥 and 椎 in 脊椎動物. A school story about handing in a lost wallet can introduce 昧 in 拾金不昧. Familiarity varies with pupils’ spoken vocabulary and reading experience. [EDB 香港小學學習字詞表](https://www.edbchinese.hk/lexlist_ch/) · [EDB primary science curriculum](https://www.edb.gov.hk/attachment/tc/curriculum-development/kla/science-edu/pri-sci/PSCG%282025%29.pdf)

The review covered every recorded placement. When a component’s only possible answer was withdrawn, the whole tile was removed from that family. When the same two components have a familiar construction in another direction, the tile remains playable. A pupil who uses a documented withdrawn direction sees the familiar in-bank character in a light colour. The tile leaves play and both sides retain their charge. For example, with 禾 in the centre, 火 on the right makes 秋 and launches a shot. Putting 火 on the left brings up 秋 as the classroom form.

Each family has ten screened incompatible tiles. With 包, for example, 氵 forms 泡, while 冫 is incompatible. The game draws eight matchable tiles and four incompatible tiles per group of twelve and gives priority to components a pupil has seen least during that fight.

## Forms and readings

The inventory uses direct pairings from the Hong Kong forms in the Unicode 16.0 BabelStone IDS database. 胞 uses the moon-shaped component of 肉, represented on its tile as 月. Checks on incompatible pairs covered binary and enclosing structures and common component variants across the database’s regions. [BabelStone IDS database](https://www.babelstone.co.uk/CJK/IDS.HTML)

The 330 accepted placements produce 318 distinct spoken characters. Each entry in `decks.json` specifies a Jyutping syllable and tone. Examples include 泡 pou5 in 氣泡, 鮑 baau1 in 鮑魚, 茄 ke2 in 番茄, 妖 jiu2 in 妖怪 and 坡 bo1 in 山坡. [CUHK 粵語審音配詞字庫](https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/main.php)

## Hong Kong Cantonese speech

The game preloads each active family’s WAV recordings. The bank uses 268 distinct Cantonese syllable-and-tone combinations. The source recordings use the Google Hong Kong Cantonese voice from AlienKevin’s Cantone collection, requested with explicit Jyutping and pinned to revision `9ae2dec425f472255c1e146cd6b3f428e7c21e80`. [Cantone dataset](https://huggingface.co/datasets/AlienKevin/cantone) · [Audio licence](audio/LICENSE-Cantone.txt)
