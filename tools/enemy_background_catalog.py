"""Catalog and prompts for all 33 enemy backgrounds in Aetheria Online.
Maps each enemy to their lore, title, elemental concept, status, and 16:9 prompt (1376x768).
Total: 33 enemies
"""
import os

ENEMY_BACKGROUND_DIR = "backround image/new backround enemy/enemy_backgrounds"

ENEMY_BACKGROUND_CATALOG = {
    "eroghost": {
        "name": "Eroghost",
        "title": "SPECTRAL SHADOW WIGHT",
        "element": "DARK",
        "class": "ASSASSIN",
        "file": "bg_eroghost.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Translucent Silver, Pale Ghostly Cyan & Midnight Blue",
        "concept": "Eerie moonlit gothic cemetery on a foggy hill, weathered cracked marble gravestones, ancient twisted leafless oaks, floating pale cyan ghostly wisps, silver moonlight mist.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of an eerie moonlit gothic cemetery atop a foggy hill. Weathered cracked ancient marble gravestones, gothic stone crosses, and iron fences emerge from thick rolling silver moonlight mist. Ancient twisted leafless oak trees with gnarled dark branches frame the scenery. Luminous pale ghostly cyan wisps and translucent silver spirit motes float gently through the foggy air. Overhead, a massive pale silver full moon illuminates dramatic midnight blue clouds, casting cool silver and ghostly cyan rim lighting across damp earth and stone. Color palette of translucent silver, pale ghostly cyan, and deep midnight blue. Rich painterly anime background art style, intricate atmospheric depth, cinematic lighting. Strictly no characters, no figures, no silhouettes, and no text."
    },
    "evy_blood_sage": {
        "name": "Evy Blood Sage",
        "title": "SANGUINE CRIMSON WITCH",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_evy_blood_sage.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Sanguine Blood Crimson, Deep Arcane Violet & Obsidian",
        "concept": "Dark gothic blood ritual chamber with polished obsidian floor, floating glowing crimson blood orbs, deep violet arcane lightning arcs, blood-red velvet draperies, candelabras with violet flames.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a dark gothic blood ritual chamber. Highly polished black obsidian stone floor reflecting ambient light. Floating glowing crimson blood orbs and deep violet arcane energy arcs illuminate towering vaulted gothic pillars and ornate stone arches. Heavy blood-red crimson velvet draperies hang along the stone walls, with ornate wrought-iron candelabras burning with eerie violet flames. Color palette of rich sanguine crimson, deep arcane violet, and obsidian black. Painterly anime background art style, dramatic mysterious lighting, deep atmospheric contrast. Strictly no characters, no figures, no silhouettes, and no text."
    },
    "gumi_wolf": {
        "name": "Gumi Wolf",
        "title": "NINE-TAIL ASTRAL LUPINE",
        "element": "FIRE",
        "class": "WARRIOR",
        "file": "bg_gumi_wolf.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Astral Violet Flame, Deep Indigo & Magenta Embers",
        "concept": "Mystical rocky mountain wolf den in a midnight bamboo forest, burning with floating purple and magenta astral spirit fire, glowing violet embers drifting in midnight indigo fog under a purple crescent moon.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a mystical rocky mountain wolf den surrounded by a midnight bamboo forest. Jagged mossy boulders and rocky crags illuminated by floating purple and magenta astral spirit fire (kitsunebi). Swirling violet embers and spectral wisps drift quietly through midnight indigo mountain mist under a glowing purple crescent moon. Ancient gnarled pine roots and stone lanterns scattered along a secluded mountain path. Color palette of astral violet, vibrant magenta flame, deep indigo, and moonlit stone. Rich painterly anime background art style, mystical glowing lighting. Strictly no characters, no figures, no animals, no wolves, and no text."
    },
    "slarkoi": {
        "name": "Slarkoi",
        "title": "CRYPT MUMMY BEHEMOTH",
        "element": "EARTH",
        "class": "TANK",
        "file": "bg_slarkoi.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Dark Crimson Blood, Ash Grey & Bone Ivory",
        "concept": "Deep underground crypt altar cavern, surrounded by ancient stone columns carved with horned demonic runes, piles of ancient warrior bones, burning dark crimson brazier flames, and heavy stone tomb slabs.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a deep underground crypt altar cavern. Massive crumbling stone monoliths and columns carved with ominous horned demonic runes. Piles of ancient weathered warrior bones and broken armored relics half-buried in volcanic ash. Dark crimson oil braziers and iron torch sconces cast flickering red firelight across heavy cracked stone tomb sarcophagi. Color palette of dark crimson blood, ash grey, bone ivory, and subterranean shadows. Painterly anime visual novel background, moody atmospheric lighting. Strictly no characters, no monsters, no skeletons, no figures, and no text."
    },
    "ygg_naar": {
        "name": "Ygg-Naar",
        "title": "EYE OF THE PRIMORDIAL",
        "element": "CHAOS",
        "class": "MAGE",
        "file": "bg_ygg_naar.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Galactic Violet, Obsidian Void & Starry Amethyst",
        "concept": "Primordial cosmic void dimension, swirling cosmic nebulas in deep amethyst and midnight violet, floating fractured obsidian monoliths, glowing cosmic rift stars, surreal eldritch space abyss.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a primordial cosmic void dimension. Breathtaking swirling nebulas in deep galactic violet, amethyst purple, and cosmic magenta. Floating fractured geometric obsidian monoliths and glowing celestial crystal shards drift weightlessly through an endless starry abyss. Pulsating astral rift rings and ethereal cosmic energy ribbons weave across the space horizon. Color palette of galactic violet, starry amethyst, vibrant nebula magenta, and deep obsidian black. Breathtaking anime sci-fi fantasy scenery, cinematic celestial scale. Strictly no characters, no faces, no eyes, no figures, and no text."
    },
    "ex_nymph": {
        "name": "Ex-Nymph",
        "title": "CORRUPTED FOREST NYMPH",
        "element": "WIND",
        "class": "RANGER",
        "file": "bg_ex_nymph.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Corrupted Canopy Olive, Bronze Amber & Glowing Ruby Spores",
        "concept": "Deep corrupted primeval forest canopy, colossal hollow ancient twisted tree trunks, glowing ruby-red fungal spores and luminous amber tree sap dripping from giant roots, filtered golden-bronze twilight mist.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a deep corrupted primeval forest canopy. Colossal hollow twisted ancient ironwood tree trunks and sprawling mossy roots spanning across a deep ravine. Glowing ruby-red fungal spore bioluminescence and luminous golden-amber tree sap drip from hanging vines. Shafts of filtered bronze twilight and warm golden sunbeams pierce through heavy forest mist and thick ancient canopy foliage. Color palette of corrupted canopy olive green, bronze amber, deep forest brown, and glowing ruby red. Lush painterly anime background art, ethereal enchanted nature scenery. Strictly no characters, no figures, no creatures, and no text."
    },
    "slime": {
        "name": "Slime Queen",
        "title": "GELATINOUS OVERLORD",
        "element": "WATER",
        "class": "TANK",
        "file": "bg_slime.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Mint Green, Shimmering Cyan & Iridescent Pastel Rainbow",
        "concept": "Sparkling underground crystalline slime cavern, shimmering pools of translucent mint-green and iridescent cyan gelatinous liquid, giant glowing prismatic crystal stalactites, floating iridescent bubbles.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a sparkling underground crystalline gelatinous cavern. Serene terraced pools of glowing translucent mint-green and crystal cyan gelatinous water. Towering prismatic iridescent crystal stalactites and stalagmites glitter with pastel rainbow refractions. Floating iridescent luminous bubbles drift peacefully across the cavern air, reflecting shimmering light ripples on smooth moist cavern walls. Color palette of mint green, turquoise cyan, soft pastel rainbow reflections, and crystal clear water. Magical enchanting anime scenery, whimsical fantasy lighting. Strictly no characters, no slimes, no figures, and no text."
    },
    "hairly": {
        "name": "Hairly",
        "title": "WITCH OF THE SHADOW TRESSES",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_hairly.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Starlight Jet Black, Celestial Amethyst & Weeping Indigo",
        "concept": "High gothic sanctuary observatory of weeping shadow, towering stained glass windows overlooking a dark nebula starry void, crystalline black dragon-horn pillars, pools of mirror-still dark water reflecting starlight.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a high gothic sanctuary observatory high above the clouds. Towering arched gothic stained-glass windows overlooking a deep starry midnight nebula sky. Crystalline black polished stone pillars and ornate sweeping balustrades surround mirror-still dark reflecting pools that echo the celestial starlight. Subtle cascades of weeping silver and indigo starlight mist pool along the polished obsidian floor. Color palette of starlight jet black, celestial amethyst, and deep weeping indigo. Elegant mystical anime background art style. Strictly no characters, no figures, no silhouettes, and no text."
    },
    "svormentis": {
        "name": "Svormentis",
        "title": "THE DEVOURING MAW",
        "element": "WATER",
        "class": "TANK",
        "file": "bg_svormentis.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Abyssal Deep Sea Cyan, Emerald Murk & Leviathan Indigo",
        "concept": "Colossal deep-sea trench abyss, massive sunken shipwreck hulls overgrown with glowing emerald sea flora, drifting leviathan rib bones, eerie cyan bioluminescent deep-ocean currents.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a colossal deep-sea ocean trench abyss. Ancient sunken wooden and iron galleon shipwreck hulls encrusted with glowing emerald marine flora and sea fans. Giant leviathan rib bones arch across the seafloor like ancient forgotten cathedral pillars. Bioluminescent cyan jellyfish and drifting deep-sea embers glow softly in the dark sapphire-indigo oceanic depths, with shimmering light shafts filtering from far above. Color palette of abyssal deep-sea cyan, emerald bioluminescence, and leviathan indigo. Atmospheric underwater anime game background. Strictly no characters, no monsters, no creatures, and no text."
    },
    "ymir": {
        "name": "Ymir",
        "title": "QUEEN OF THE BONE THRONE",
        "element": "EARTH",
        "class": "WARRIOR",
        "file": "bg_ymir.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Blackened Gold, Bone Ivory & Blood Ruby",
        "concept": "Ancient necrotic throne hall of skulls, massive mound throne formed of ancient giant beast skulls and blackened gold crowns, crimson torches casting flickering shadows across ruined catacomb arches.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of an ancient necrotic throne hall within vast ruined stone catacombs. In the center raised upon stone steps stands a monumental throne crafted from blackened gold, carved bone ivory, and weathered ancient dragon skulls. Crimson torches and iron wall sconces cast flickering red firelight across cracked gothic catacomb arches and blood-red velvet carpeting. Piles of ancient gold chalices and ornate relics gleam in dark corners. Color palette of blackened gold, bone ivory, deep blood ruby, and charcoal stone. Imposing dark fantasy anime background art. Strictly no characters, no figures on the throne, no skeletons, and no text."
    },
    "scomantis": {
        "name": "Scomantis",
        "title": "EMERALD STINGER",
        "element": "WIND",
        "class": "ASSASSIN",
        "file": "bg_scomantis.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Neon Emerald Green, Acid Lime & Industrial Chitin Charcoal",
        "concept": "Subterranean cybernetic mantis hive, high-tech metallic chitin hive walls glowing with neon lime-green conduit lines, acid emerald toxic chemical pools, robotic pincer claw maintenance docks.",
        "prompt": "High-quality anime sci-fi fantasy background illustration, wide 16:9 cinematic landscape scenery of a subterranean cybernetic hive laboratory. Hexagonal metallic biomechanical hive walls glowing with pulsating neon lime-green circuit lines and coolant conduits. Industrial catwalks and metallic pincer claw crane assemblies suspend over steaming pools of glowing acid-emerald biochemical fluid. Green volumetric laser scans and toxic mist cut through dark industrial charcoal machinery. Color palette of neon emerald green, vivid acid lime, and dark metallic chitin charcoal. Sleek futuristic anime sci-fi environment. Strictly no characters, no insects, no figures, and no text."
    },
    "skelinch": {
        "name": "Skelinch",
        "title": "HELLFIRE PUNK",
        "element": "FIRE",
        "class": "WARRIOR",
        "file": "bg_skelinch.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Punk Goth Charcoal, Electric Violet Neon & Smoldering Ash",
        "concept": "Grungy underground gothic punk club dungeon, heavy iron chains, graffiti tags glowing under electric violet and magenta neon signs, smoldering oil drum fires, leather-clad spiked pillars.",
        "prompt": "High-quality anime visual novel background illustration, wide 16:9 cinematic landscape scenery of a grungy underground gothic punk club dungeon. Heavy rusted iron chains hanging from exposed concrete and stone pillars. Glowing electric violet and hot magenta neon signs reflect across wet stone pavement. Weathered brick walls adorned with vibrant stylized graffiti art, with smoldering metal oil drums emitting glowing orange fire embers and dark smoky haze. Amplifier stacks and speaker cabinets line the back alcoves. Color palette of punk goth charcoal, electric violet neon, hot magenta, and smoldering ember orange. Grungy anime street-punk aesthetic. Strictly no characters, no people, no figures, and no text."
    },
    "serpentia": {
        "name": "Serpentia",
        "title": "FLAME-SCALE LAMIA",
        "element": "FIRE",
        "class": "MAGE",
        "file": "bg_serpentia.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Rose Quartz Pink, Molten Gold & Peach Amber Flame",
        "concept": "Sacred desert serpent caldera oasis, surrounded by rose-quartz sandstone cliffs, pools of glowing molten gold lava reflecting warm peach-pink firelight, ancient snake stone carvings in twilight.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a sacred desert serpent caldera oasis at twilight. Surrounded by towering rose-quartz sandstone canyon cliffs intricately carved with ancient snake reliefs. Stepped rock pools filled with glowing molten gold geothermal lava emitting a soft peach-pink and amber warm glow. Ancient serpent braziers and stone dragon lanterns cast warm flickering light across crystalline mineral deposits and tranquil steaming thermal pools under a dusky violet desert sky. Color palette of rose quartz pink, molten gold, peach amber flame, and twilight lavender. Painterly fantasy scenery, warm luminous ambiance. Strictly no characters, no snakes, no figures, and no text."
    },
    "voodoo": {
        "name": "Voodoo Doll",
        "title": "THE STITCHED DANCER",
        "element": "DARK",
        "class": "ASSASSIN",
        "file": "bg_voodoo.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Porcelain White, Velvet Burgundy & Silver Antique",
        "concept": "Creepy antique marionette theater stage, rich burgundy velvet stage curtains, dusty wooden floorboards strewn with porcelain doll fragments and silver sewing needles, eerie moonlight through a broken skylight.",
        "prompt": "High-quality anime gothic horror background illustration, wide 16:9 cinematic landscape scenery of an abandoned antique marionette theater stage. Grand ornate burgundy velvet curtains trimmed with tarnished gold fringe frame the stage. Worn weathered wooden floorboards littered with antique porcelain doll parts, spools of silver silk thread, and vintage wooden marionette control crosses hanging from ceiling rafters. A dramatic beam of pale silver moonlight streams through a broken circular stained-glass skylight, cutting through floating dust motes. Color palette of rich burgundy velvet, antique porcelain white, tarnished gold, and moonlight silver. Eerie atmospheric gothic anime background art. Strictly no characters, no dolls, no figures, and no text."
    },
    "lizamorph": {
        "name": "Lizamorph",
        "title": "THE CRAWLING SHADOW",
        "element": "DARK",
        "class": "TANK",
        "file": "bg_lizamorph.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Glossy Obsidian Black, Vivid Violet Flame & Crimson Seams",
        "concept": "Subterranean shadow lizard lair in a deep volcanic obsidian cavern, glowing cracks of purple geothermal flames escaping from black volcanic basalt rock, glistening dark pools with violet reflections.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a subterranean shadow lair inside a jagged volcanic basalt cavern. Sharp glossy obsidian rock pillars and geometric basalt formations. Glowing fissures and magma cracks pulse with vivid violet geothermal fire and deep crimson magma veins along the cavern floor. Still, glass-like obsidian pools reflect the purple firelight and rising ethereal heat haze. Sharp stalactites hang from the vaulted dark cavern ceiling. Color palette of glossy obsidian black, vivid violet fire, deep crimson seams, and purple volcanic smoke. Moody, dramatic anime fantasy landscape. Strictly no characters, no lizards, no monsters, no figures, and no text."
    },
    "octra": {
        "name": "Octra",
        "title": "MISTRESS OF THE ABYSS BEAST",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_octra.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Abyssal Midnight Blue, Bioluminescent Cerulean & Eldritch Crimson",
        "concept": "Sunken eldritch abyssal ruins beneath crushing oceanic depths, massive cyclopean stone monoliths covered in alien runes, glowing crimson and cerulean eldritch eyes watching from the deep dark trenches.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of sunken cyclopean eldritch ruins in the abyssal ocean deep. Towering ancient alien stone monoliths, non-Euclidean temple arches carved with glowing crimson runic sigils, and crumbling underwater pavilions. Bioluminescent cerulean sea flora, glowing tentacles made of pure arcane light in the distance, and eerie crimson embers floating through pitch-black ocean water. Eerie shafts of supernatural light pierce the deep midnight abyss. Color palette of abyssal midnight blue, bioluminescent cerulean, and glowing eldritch crimson. Atmospheric Lovecraftian anime visual novel scenery. Strictly no characters, no faces, no monsters, no figures, and no text."
    },
    "amatera": {
        "name": "Amatera",
        "title": "CHAINED HAND OF THE PIT",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_amatera.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Nether Amethyst Purple, Demonic Red & Iron Charcoal",
        "concept": "Cursed subterranean sacrificial chasm, massive iron chains descending into a swirling violet void rift, red glowing ofuda paper talismans fluttering along dark stone pillars, demonic red embers.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a cursed subterranean sacrificial chasm. Colossal iron binding chains anchor into massive obsidian pillars and plunge into a swirling nether void rift of deep amethyst purple and demonic crimson fire. Red glowing Shinto ofuda paper talismans and sacred shimenawa ropes flutter in an eerie supernatural updraft. Glowing red soul embers and dark smoke rise from cracked sacrificial stone altars. Color palette of nether amethyst purple, demonic crimson red, and heavy iron charcoal stone. Intense dark fantasy anime scenery. Strictly no characters, no hands, no figures, and no text."
    },
    "anthis": {
        "name": "Anthis",
        "title": "PALE MOTH WANDERER",
        "element": "WIND",
        "class": "ASSASSIN",
        "file": "bg_anthis.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Pale Mint Green, Ghostly Silver-White & Luminous Dew",
        "concept": "Ethereal silver-white moth forest clearing at twilight, giant glowing pale mint-green silken cocoons suspended among ancient pale birch trees, floating luminous green moth scales and silver dew mist.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of an ethereal pale birch grove clearing at magical twilight. Slender silver-white birch trees and weeping willow branches draped in delicate gossamer spider silk and glowing pale mint-green silken cocoons. Shimmering silver dew droplets glisten on oversized fern fronds, while glowing mint-green moth powder motes drift like fireflies through soft rolling silver twilight mist. In the background, a serene moonlit forest lake mirrors the twilight sky. Color palette of pale mint green, ghostly silver-white, soft jade, and moonlight cyan. Ethereal, dreamy anime fantasy landscape. Strictly no characters, no moths, no figures, and no text."
    },
    "cleara": {
        "name": "Cleara",
        "title": "PHARAOH OF THE GILDED TOMB",
        "element": "EARTH",
        "class": "MAGE",
        "file": "bg_cleara.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Gilded Pharaoh Gold, Sandstone Amber & Lapis Blue Accents",
        "concept": "Opulent golden burial chamber of the Egyptian pharaoh, grand carved sandstone columns with gold hieroglyphs, golden anubis statues, glowing oil braziers illuminating piles of gold relics and ornate sarcophagi.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of an opulent golden Egyptian pharaoh burial chamber. Grand sandstone columns adorned with inlaid gold hieroglyphic reliefs and deep lapis lazuli gemstones. Majestic carved golden jackal and falcon statues flank a raised central dais. Ancient bronze oil braziers cast warm flickering golden firelight across ornate gold sarcophagi, piled treasure chests, and golden chalices. Color palette of gleaming pharaoh gold, warm sandstone amber, and vibrant lapis lazuli blue. Rich, magnificent anime visual novel background art. Strictly no characters, no mummies, no figures, and no text."
    },
    "code_zero": {
        "name": "Code Zero",
        "title": "PILOT OF THE SKULL WORM",
        "element": "LIGHTNING",
        "class": "TANK",
        "file": "bg_code_zero.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Toxic Neon Green, Pearlescent White Armor & Industrial Steel",
        "concept": "Futuristic subterranean worm excavation shaft, giant carved mechanical launch tunnels illuminated by toxic neon green power conduits, heavy industrial cranes, metallic machinery and green coolant mist.",
        "prompt": "High-quality anime sci-fi background illustration, wide 16:9 cinematic landscape scenery of a subterranean industrial excavation mega-shaft. Colossal cylindrical tunneling borehole carved through raw bedrock, lined with heavy industrial steel ribs and pearlescent white composite armor plating. Vibrant toxic neon green energy conduits, laser guide grids, and hydraulic machinery emit glowing green steam and coolant mist. Heavy industrial gantry cranes and yellow hazard catwalks span across the deep shaft. Color palette of toxic neon green, clean pearlescent white, dark industrial steel, and warning yellow. Sleek cybernetic anime sci-fi environment. Strictly no characters, no mechs, no figures, and no text."
    },
    "cow_girl": {
        "name": "Cow Girl",
        "title": "MEADOW BRUISER",
        "element": "EARTH",
        "class": "WARRIOR",
        "file": "bg_cow_girl.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Vibrant Meadow Green, Sunlit Golden Amber & Cedar Wood",
        "concept": "Sun-drenched highland pasture and ranch meadow on a clear summer afternoon, rolling emerald-green grassy hills, wooden post-and-rail fences, wildflowers, rustic wooden barn silhouette under warm sunbeams.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a sun-drenched highland ranch pasture on a clear summer afternoon. Rolling vibrant emerald-green hills dotted with colorful wildflowers, clover, and rustic cedar post-and-rail fences. In the midground, a charming rustic timber barn and a stone well overlook the valley under sweeping golden sunbeams. Towering puffy white cumulus clouds drift across a brilliant azure blue summer sky, with majestic distant mountain peaks. Color palette of vibrant meadow green, sunlit golden amber, rustic cedar brown, and bright sky blue. Cheerful, expansive anime pastoral scenery. Strictly no characters, no cows, no people, and no text."
    },
    "graeae": {
        "name": "Graeae",
        "title": "THE BANDAGED MAW",
        "element": "DARK",
        "class": "TANK",
        "file": "bg_graeae.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Linen Bone White, Pale Lavender Mist & Cursed Charcoal",
        "concept": "Ancient crumbling tomb catacombs draped in endless tattered white linen mummy wraps hanging from stone ceiling arches, weathered stone sarcophagi, eerie pale lavender mist swirling along the stone floor.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of ancient ruined subterranean catacombs. Towering cracked stone vaulted arches draped in endless tattered bone-white linen wraps and burial shrouds hanging like ghostly curtains. Weathered stone sarcophagi and shattered urns rest half-submerged in eerie pale lavender mist swirling across the cracked flagstone floor. Distant stone braziers flicker with cold violet flames, casting long eerie shadows. Color palette of linen bone white, pale lavender mist, cursed charcoal stone, and muted lilac. Haunting, atmospheric anime scenery. Strictly no characters, no figures, no mummies, and no text."
    },
    "kurenai": {
        "name": "Kurenai",
        "title": "EMERALD MANTIS BLADE",
        "element": "WIND",
        "class": "ASSASSIN",
        "file": "bg_kurenai.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Deep Forest Emerald, Bamboo Jade & Mossy Bronze",
        "concept": "Dense secluded bamboo rainforest canyon, soaring green bamboo stalks cutting into misty green sky, moss-covered ancient stone lanterns, sharp morning dew glistening on broad jungle leaves.",
        "prompt": "High-quality anime visual novel background illustration, wide 16:9 cinematic landscape scenery of a secluded misty bamboo rainforest canyon in the early morning. Soaring emerald-green and jade bamboo stalks reach into a canopy of gentle filtered emerald light. Ancient weathered moss-covered stone toro lanterns line a winding flagstone woodland trail. Sharp morning dew glistens on broad tropical leaves and stone bridges crossing a crystal-clear pebble brook. Light mountain fog wafts between bamboo groves. Color palette of deep forest emerald, bamboo jade green, mossy bronze, and morning dew silver. Tranquil yet sharp oriental anime fantasy landscape. Strictly no characters, no ninjas, no figures, and no text."
    },
    "lamia": {
        "name": "Lamia",
        "title": "VIOLET REAVER",
        "element": "DARK",
        "class": "WARRIOR",
        "file": "bg_lamia.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Metallic Dragon Violet, Radiant Magenta & Obsidian Shadow",
        "concept": "Deep jagged abyssal crystal chasm, sharp violet crystal spires erupting from obsidian canyon walls, glowing magenta energy rifts pulsating along the floor, dark purple atmospheric haze.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a deep jagged abyssal crystal chasm. Towering sharp crystalline spires in metallic violet and glowing magenta erupt from sheer black obsidian canyon walls. Fissures along the canyon floor pulse with radiant magenta arcane geothermal energy, casting vibrant violet rim lighting across razor-sharp mineral formations. A dark violet atmospheric haze fills the chasm under a stormy starry night sky. Color palette of metallic dragon violet, radiant neon magenta, and deep obsidian black. Fierce, dramatic anime fantasy landscape. Strictly no characters, no dragons, no figures, and no text."
    },
    "lolth": {
        "name": "Lolth",
        "title": "BROODMOTHER OF WHISPERS",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_lolth.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Spectral Violet Purple, Arachnid Chitin Brown & Web White",
        "concept": "Colossal subterranean spider broodmother cavern, draped in dense layers of thick glowing spiderwebs, spectral violet wisp flames illuminating ancient skeletal cocoons and dark stone cavern stalactites.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a colossal subterranean spider broodmother cavern. Sweeping layers of dense silken spiderwebs stretch between massive stalactites and rocky limestone pillars. Floating spectral violet wisp orbs illuminate ancient silken cocoons and glistening dew droplets suspended in the web canopy. Deep chasms drop into bottomless purple shadows below, with eerie violet bioluminescence reflecting on damp cave walls. Color palette of spectral violet purple, web white, arachnid chitin brown, and deep cavern black. Menacing yet majestic dark fantasy anime scenery. Strictly no characters, no spiders, no figures, and no text."
    },
    "nagini": {
        "name": "Nagini",
        "title": "GORGON OF THE STILL LAKE",
        "element": "WATER",
        "class": "MAGE",
        "file": "bg_nagini.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Serene Glacial Cyan, Mirror Turquoise & Petrified Silver Stone",
        "concept": "Subterranean sacred still lake cavern, mirror-smooth turquoise-cyan water reflecting luminous pale blue crystals on the ceiling, ancient petrified marble serpent statues standing quietly along the misty shores.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a subterranean sacred subterranean lake cavern. Glass-smooth, mirror-like turquoise-cyan water perfectly reflects glowing pale blue crystal formations clustered on the arched cavern ceiling. Along the misty white shores stand ancient petrified white marble serpent statues, half-overgrown with pale cyan moss and water lilies. Gentle silver mist drifts across the water surface, creating an aura of timeless silence. Color palette of serene glacial cyan, mirror turquoise, petrified silver stone, and crystal pale blue. Breathtaking, mystical anime visual novel background. Strictly no characters, no gorgons, no figures, and no text."
    },
    "nox": {
        "name": "Nox",
        "title": "MIDNIGHT GEL",
        "element": "CHAOS",
        "class": "TANK",
        "file": "bg_nox.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Pitch Black Slime, Radiant Hot Magenta Neon & Violet Glow",
        "concept": "Surreal underground black slime cavern, pools of glossy jet-black viscous liquid glowing with vibrant neon hot-magenta edges, dark stalactites dripping black gel into glowing magenta bubbling puddles.",
        "prompt": "High-quality anime fantasy background illustration, wide 16:9 cinematic landscape scenery of a surreal underground black slime cavern. Terraced pools of glossy jet-black viscous liquid, where the shoreline and ripples glow with vibrant neon hot-magenta and electric violet bioluminescence. Sleek black stalactites drip glossy dark gel into bubbling magenta puddles. Prismatic dark crystals and violet glowing fungi scatter across the dark stone cave walls. Color palette of pitch-black glossy slime, radiant hot-magenta neon, and electric violet glow. Edgy surreal anime game scenery. Strictly no characters, no creatures, no figures, and no text."
    },
    "octavia": {
        "name": "Octavia-Vex",
        "title": "DEEP CURRENT WARDEN",
        "element": "WATER",
        "class": "TANK",
        "file": "bg_octavia.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Royal Abyssal Violet, Indigo Sea Trench & Deep Bronze",
        "concept": "Deep-sea oceanic warden temple terrace at the floor of the Mariana trench, massive dark violet kelp forests swaying in strong currents, ancient bronze runic sea-gates, deep indigo water with pale luminescence.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of an ancient underwater warden temple terrace at the floor of an oceanic abyss. Monumental bronze sea-gates carved with nautical sea runes stand against massive dark violet kelp forests that sway gracefully in deep-sea currents. Glowing blue-violet hydro-thermal chimneys release shimmering pearl bubbles, while ethereal cyan light beams filter through deep indigo waters onto polished stone terrace tiles. Color palette of royal abyssal violet, indigo sea trench blue, ancient bronze, and luminescent cyan. Grand underwater anime background scenery. Strictly no characters, no figures, no sea monsters, and no text."
    },
    "rin": {
        "name": "Rin",
        "title": "AZURE STINGER",
        "element": "ICE",
        "class": "RANGER",
        "file": "bg_rin.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Glacial Azure Blue, Frosted Diamond Cyan & Subzero Ice White",
        "concept": "Subzero glacial insect ice hive cavern, translucent azure ice walls embedded with frozen fossilized chitin structures, glowing diamond-sharp icicles hanging overhead, pale cyan frost mist.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a subzero glacial ice cavern. Towering translucent azure ice walls and geometric frost arches embedded with frozen ancient crystal structures. Thousands of diamond-sharp glowing icicles hang from the glacial ceiling like a crystalline chandelier. Drifting pale cyan frost mist swirls across the glassy, frozen blue ice floor, reflecting brilliant diamond light prisms. Color palette of glacial azure blue, frosted diamond cyan, and subzero ice white. Crisp, breathtaking frozen anime landscape. Strictly no characters, no insects, no figures, and no text."
    },
    "roza": {
        "name": "Roza",
        "title": "GILDED GUNSLINGER",
        "element": "LIGHT",
        "class": "RANGER",
        "file": "bg_roza.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Gilded Sovereign Gold, Polished White Marble & Metropolitan Twilight",
        "concept": "Ultra-luxurious penthouse mob boss armory and vault, polished white marble floor, glass display cabinets filled with gilded gold-plated firearms, panoramic glass windows overlooking a glittering gold-lit metropolis at dusk.",
        "prompt": "High-quality anime visual novel background illustration, wide 16:9 cinematic landscape scenery of an ultra-luxurious penthouse private vault and armory lounge. Highly polished white marble floor with gold geometric inlays. Backlit glass display cabinets showcasing gilded gold weapons and antique crystal decanters. Floor-to-ceiling panoramic glass windows reveal a breathtaking golden hour twilight view of a glittering futuristic metropolis skyline with glowing skyscrapers and flying vehicle sky-lanes. Plush leather seating and warm architectural lighting. Color palette of sovereign gold, polished white marble, warm champagne amber, and metropolitan twilight indigo. Glamorous anime interior background art. Strictly no characters, no people, no figures, and no text."
    },
    "selene": {
        "name": "Selene",
        "title": "NIGHTWING SUCCUBUS",
        "element": "DARK",
        "class": "MAGE",
        "file": "bg_selene.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Midnight Gothic Charcoal, Silver Full Moon & Velvet Crimson",
        "concept": "Gothic moonlit vampire castle terrace high above mist-covered mountain valleys, framed by ornate black stone balustrades and climbing black rose vines, illuminated by an immense silver full moon in a starry night sky.",
        "prompt": "High-quality anime gothic fantasy background illustration, wide 16:9 cinematic landscape scenery of an ancient vampire castle balcony terrace high above mist-shrouded mountain valleys. Ornate black gothic stone balustrades entwined with blooming crimson and black rose vines. A monumental, breathtaking silver full moon dominates the starry midnight sky, casting dramatic silver moonlight across stone gargoyles, flying buttresses, and velvet red banners. Swirling silver mist settles in the dark valley far below. Color palette of midnight gothic charcoal, radiant silver moonlight, velvet crimson, and deep night sky blue. Romantic, dark gothic anime scenery. Strictly no characters, no bats, no figures, and no text."
    },
    "veyr_nok": {
        "name": "Veyr'Nok",
        "title": "KEEPER OF THE WATCHING BALLOONS",
        "element": "CHAOS",
        "class": "MAGE",
        "file": "bg_veyr_nok.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Circus Teal, Surreal Pastel Violet & Dreamscape Magenta",
        "concept": "Creepy surreal carnival ground in an endless twilight wasteland, striped circus tents glowing under a violet evening sky, floating giant eyeball balloons drifting silently above weathered carnival rides and colorful lanterns.",
        "prompt": "High-quality anime fantasy background illustration, wide 16:9 cinematic landscape scenery of a surreal, whimsical carnival fairground set in a twilight dreamscape wasteland. Weathered striped circus tents illuminated from within by warm whimsical lanterns under a dreamy violet and magenta evening sky. Distant abandoned Ferris wheel and carousel silhouettes stand against floating pastel hot air balloons and glowing fairy-light garlands. Soft dreamscape mist glides across weathered wooden boardwalks. Color palette of circus teal, surreal pastel violet, dreamscape magenta, and carnival amber glow. Whimsical eerie anime fantasy scenery. Strictly no characters, no people, no figures, and no text."
    },
    "xaniyus": {
        "name": "Xa'niyus",
        "title": "HORNED TIDE HERALD",
        "element": "WIND",
        "class": "WARRIOR",
        "file": "bg_xaniyus.jpg",
        "status": "PENDING_GENERATION",
        "tone": "Seafoam Mint Green, Pearlescent Steel & Deep Tide Teal",
        "concept": "Sunken biomechanical reef terrace in the deep ocean, churning tidal whirlpool currents spiraling around glowing seafoam-mint hydrothermal vents, pearlescent metallic coral reefs and ancient sunken pillars.",
        "prompt": "High-quality anime fantasy game background illustration, wide 16:9 cinematic landscape scenery of a sunken biomechanical reef terrace in the deep ocean. Spiraling turquoise and teal tidal vortex currents churn gracefully around glowing seafoam-mint hydrothermal crystal vents. Pearlescent metallic coral structures and ancient spiraled sunken pillars rise from the sea floor. Swirling schools of bioluminescent cyan plankton drift through churning seafoam currents under the deep aquatic light. Color palette of seafoam mint green, pearlescent steel, deep tide teal, and oceanic turquoise. Powerful, fluid anime underwater environment. Strictly no characters, no fish, no figures, and no text."
    }
}


def get_status_summary():
    """Returns total, completed, and pending counts."""
    total = len(ENEMY_BACKGROUND_CATALOG)
    completed = 0
    pending = 0
    for k, v in ENEMY_BACKGROUND_CATALOG.items():
        dest = os.path.join(ENEMY_BACKGROUND_DIR, v["file"])
        if os.path.exists(dest):
            completed += 1
        else:
            pending += 1
    return {"total": total, "completed": completed, "pending": pending}


if __name__ == "__main__":
    summary = get_status_summary()
    print(f"Enemy Backgrounds: Total={summary['total']}, Completed={summary['completed']}, Pending={summary['pending']}")
