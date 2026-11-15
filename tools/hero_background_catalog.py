"""Catalog and prompts for all 40 hero backgrounds in Aetheria Online.
Maps each hero to their lore, title, elemental concept, and 16:9 prompt (1376x768).
"""

HERO_BACKGROUND_CATALOG = {
    # --- COMPLETED BATCH (15 heroes) ---
    "shina": {
        "name": "Shina",
        "title": "DRAGONIC FLAME MONARCH",
        "element": "FIRE",
        "status": "COMPLETED",
        "file": "bg_shina.jpg",
        "concept": "Ancient volcanic dragon sanctuary, glowing magma rivers, obsidian cliffs, golden dragon statues, and drifting embers in twilight.",
        "prompt": "Anime visual novel background of an ancient majestic Dragon Monarch sanctuary, towering obsidian and crimson volcanic shrines, glowing lava channels, burning embers drifting in twilight sky, ornate draconic banners and golden dragon statues, high fantasy JRPG background art, highly detailed, landscape only, no characters"
    },
    "valeria": {
        "name": "Valeria",
        "title": "FROSTVALE EMPRESS",
        "element": "ICE",
        "status": "COMPLETED",
        "file": "bg_valeria.jpg",
        "concept": "Frostvale Imperial palace terrace of snowy white marble overlooking crystalline ice spires and pine forest under a vivid aurora borealis.",
        "prompt": "Anime visual novel background of the Frostvale Imperial palace terrace, glistening crystalline ice spires, frost-covered snow pine forest in the distance, aurora borealis northern lights glowing in the cold blue twilight sky, elegant snowy marble castle architecture, high fantasy JRPG background art, highly detailed, landscape only, no characters"
    },
    "xylia": {
        "name": "Xylia",
        "title": "ARCH-DEMON ARCHITECT",
        "element": "DARK",
        "status": "COMPLETED",
        "file": "bg_xylia.jpg",
        "concept": "Arch-demon grand library and workshop, towering obsidian Gothic cathedral arches, floating purple glowing blueprints overlooking a starry nether sky.",
        "prompt": "Anime visual novel background of an arch-demon architect grand library and workshop, towering obsidian Gothic cathedral arches, floating purple glowing blueprints and arcane geometric diagrams, dark gothic castle interior overlooking a starry purple nether sky, highly detailed fantasy JRPG art, landscape only, no characters"
    },
    "micca": {
        "name": "Micca Pandora",
        "title": "CHAOS BOX SOVEREIGN",
        "element": "CHAOS",
        "status": "COMPLETED",
        "file": "bg_micca.jpg",
        "concept": "Surrealistic whimsical toy realm, floating glowing Pandora boxes, neon crystals, ribbons, and playing cards in pastel cosmos.",
        "prompt": "Anime visual novel background of a chaotic whimsical wonderland realm, floating glowing Pandora boxes bursting with colorful ribbons and sparkles, oversized playing cards and neon crystals floating in pastel cosmic space, vibrant playful fantasy art, landscape only, no characters"
    },
    "cthollia": {
        "name": "Cthollia",
        "title": "ABYSS TENTACLE SOVEREIGN",
        "element": "WATER",
        "status": "COMPLETED",
        "file": "bg_cthollia.jpg",
        "concept": "Ancient sunken abyssal underwater sanctuary, bioluminescent cyan and deep purple coral reefs, ocean stone pillars, and drifting glowing jellyfish.",
        "prompt": "Anime visual novel background of an ancient sunken abyssal underwater sanctuary, bioluminescent cyan and deep purple coral reefs, glowing deep-sea jellyfish floating around grand ruined oceanic stone pillars, sunbeams filtering faintly through the dark ocean depths, landscape only, no characters"
    },
    "lumeira": {
        "name": "Lumeira",
        "title": "ASTRAL BUTTERFLY SAGE",
        "element": "WIND",
        "status": "COMPLETED",
        "file": "bg_lumeira.jpg",
        "concept": "Ethereal astral butterfly grove, glowing purple and teal giant mushrooms, swarms of luminous spirit butterflies under a starlit twilight canopy.",
        "prompt": "Anime visual novel background of an ethereal astral butterfly grove, glowing purple and teal giant mushrooms, swarms of luminous spirit butterflies fluttering under a starlit twilight canopy, magical fairytale fantasy landscape, landscape only, no characters"
    },
    "gemora": {
        "name": "Gemora",
        "title": "COSMIC VOID ENVOY",
        "element": "LIGHTNING",
        "status": "COMPLETED",
        "file": "bg_gemora.jpg",
        "concept": "Advanced cosmic orbital observatory, sleek command deck with holographic blue star maps and panoramic viewport facing an electric nebula.",
        "prompt": "Anime visual novel background of an advanced cosmic orbital observatory, sleek metallic command deck with glowing blue holographic star maps and planetary charts, massive panoramic viewport overlooking an electric nebula and distant stars, sci-fi anime interior, landscape only, no characters"
    },
    "fidelia": {
        "name": "Fidelia",
        "title": "VALKYRIE TIDAL SHIELD",
        "element": "WATER",
        "status": "COMPLETED",
        "file": "bg_fidelia.jpg",
        "concept": "White marble coastal fortress terrace, azure blue ocean waves crashing against sea walls, fluttering valkyrie banners in morning light.",
        "prompt": "Anime visual novel background of an imposing white marble coastal fortress terrace, azure blue ocean waves crashing against stone sea walls, fluttering valkyrie banners, majestic divine coastal bastion under clear morning light, landscape only, no characters"
    },
    "aqua": {
        "name": "Aqua",
        "title": "CHALICE OF THE TIDES",
        "element": "WATER",
        "status": "COMPLETED",
        "file": "bg_aqua.jpg",
        "concept": "Sacred tidal water garden with glowing crystal water basins overflowing with holy spring water, waterfalls, water lilies, and white hydrangeas.",
        "prompt": "Anime visual novel background of a sacred tidal water garden, glowing crystal water basins overflowing with holy spring water, floating water lilies and gentle cascading waterfalls surrounded by blooming white hydrangeas, pure sparkling oasis, landscape only, no characters"
    },
    "atalanta": {
        "name": "Atalanta",
        "title": "THUNDERSTEP HUNTRESS",
        "element": "LIGHTNING",
        "status": "COMPLETED",
        "file": "bg_atalanta.jpg",
        "concept": "Wind-swept stormy mountain ridge at twilight with electric blue lightning arcs dancing across clouds and an ancient stone watchtower.",
        "prompt": "Anime visual novel background of a wind-swept stormy mountain ridge at twilight, jagged crags with electric blue lightning arcs dancing across the clouds, ancient stone watchtower overlooking a tempest valley, dynamic anime storm background, landscape only, no characters"
    },
    "kali": {
        "name": "Kali",
        "title": "HUNDRED BLADE SAINT",
        "element": "WIND",
        "status": "COMPLETED",
        "file": "bg_kali.jpg",
        "concept": "Ancient sword cemetery in a serene bamboo forest with masterwork katanas embedded into stone mounds beneath swirling crimson autumn leaves.",
        "prompt": "Anime visual novel background of an ancient sword cemetery inside a serene bamboo forest, hundreds of masterwork katanas and blades thrust into stone mounds and mossy ground, swirling wind carrying crimson autumn leaves, legendary martial sanctuary, landscape only, no characters"
    },
    "sven": {
        "name": "Sven",
        "title": "GREATSWORD WANDERER",
        "element": "EARTH",
        "status": "COMPLETED",
        "file": "bg_sven.jpg",
        "concept": "Rustic lone traveler campsite at dusk with campfire, iron kettle, dirt road through an autumn pine forest, and mountain silhouette.",
        "prompt": "Anime visual novel background of a lone traveler campsite at dusk, a glowing campfire with iron kettle, a rustic dirt road winding through an autumn pine forest, rugged mountain silhouette in the orange twilight sky, landscape only, no characters"
    },
    "angela": {
        "name": "Angela",
        "title": "SERAPHIC VALKYRIE",
        "element": "LIGHT",
        "status": "COMPLETED",
        "file": "bg_angela.jpg",
        "concept": "Heavenly floating sanctuary above clouds with golden marble pillars, angelic arches, divine rays of sun, and drifting holy feathers.",
        "prompt": "Anime visual novel background of a heavenly floating sanctuary above a sea of clouds, magnificent golden marble pillars and angelic arches, divine rays of golden sunlight, white holy feathers drifting in the warm celestial breeze, landscape only, no characters"
    },
    "gala": {
        "name": "Gala",
        "title": "NEBULA FLAME TEMPTRESS",
        "element": "FIRE",
        "status": "COMPLETED",
        "file": "bg_gala.jpg",
        "concept": "Cosmic nebula festival harbor at night with colorful glowing lanterns, warm amber boardwalk lights, and purple cosmos reflected on water.",
        "prompt": "Anime visual novel background of a cosmic nebula festival harbor at night, colorful glowing paper lanterns reflecting on calm water, starry nebula swirls in the night sky, festive boardwalk with warm amber lights and purple cosmos, landscape only, no characters"
    },
    "morana": {
        "name": "Morana",
        "title": "THE BLACK PRIESTESS",
        "element": "DARK",
        "status": "COMPLETED",
        "file": "bg_morana.jpg",
        "concept": "Black Chapel interior with soaring gothic vaulted ceilings, lit black candles, holy altar, incense haze, and moonlight through stained glass.",
        "prompt": "Anime visual novel background of the Black Chapel interior, soaring gothic vaulted ceilings, dark stained glass windows with silver moonlight shining through, dozens of lit black candles on a marble altar, mysterious sacred incense haze, landscape only, no characters"
    },

    # --- PENDING RESUME UPON QUOTA RESET (25 heroes) ---
    "eropatra": {
        "name": "Eropatra",
        "title": "DESERT SERPENT EMPRESS",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_eropatra.jpg",
        "concept": "Opulent golden desert serpent palace terrace overlooking glowing twilight sand dunes, serpent braziers, and sandstone pillars.",
        "prompt": "Anime visual novel background of an opulent desert serpent palace terrace, golden sandstone Egyptian temple pillars, glowing hieroglyphs, golden snake braziers with burning fire, overlooking vast glowing golden sand dunes at twilight, luxurious oasis palace, landscape only, no characters"
    },
    "furu": {
        "name": "Furu",
        "title": "CELESTIAL ARCH-PRIESTESS",
        "element": "LIGHT",
        "status": "PENDING_QUOTA",
        "file": "bg_furu.jpg",
        "concept": "Grand celestial cathedral sun garden, brilliant holy sunlight filtering through white marble colonnades and stained glass.",
        "prompt": "Anime visual novel background of a grand celestial cathedral sun garden, brilliant holy sunlight filtering through white marble colonnades and stained glass, glowing golden flowers and holy fountain, peaceful divine sanctuary, high fantasy anime art, landscape only, no characters"
    },
    "glytta": {
        "name": "Glytta",
        "title": "CRYSTAL BLADE DANCER",
        "element": "WIND",
        "status": "PENDING_QUOTA",
        "file": "bg_glytta.jpg",
        "concept": "Sparkling crystalline highland plateau, giant glowing prism crystals sprouting from emerald grass with floating wind petals.",
        "prompt": "Anime visual novel background of a sparkling crystalline highland plateau, giant glowing prism crystals sprouting from emerald grass, floating iridescent wind petals, crystalline amphitheater with clear mountain blue sky and gentle breeze, landscape only, no characters"
    },
    "hyeonxa": {
        "name": "Hyeonxa",
        "title": "NINE-HEAD HYDRA MATRIARCH",
        "element": "WATER",
        "status": "PENDING_QUOTA",
        "file": "bg_hyeonxa.jpg",
        "concept": "Enchanted misty swamp marsh, glowing emerald poisonous lotus blossoms, ancient hydra carved stone shrines emerging from still waters.",
        "prompt": "Anime visual novel background of an enchanted misty swamp marsh, glowing emerald poisonous lotus blossoms, ancient hydra carved stone shrines emerging from still murky waters, toxic bioluminescent mist, dark enchanted wetland, landscape only, no characters"
    },
    "scylla": {
        "name": "Scylla",
        "title": "KRAKEN ABYSS QUEEN",
        "element": "WATER",
        "status": "PENDING_QUOTA",
        "file": "bg_scylla.jpg",
        "concept": "Stormy ocean sea cliffs at midnight, crashing dark blue waves with glowing seafoam, ancient black rocks and weathered oceanic tower.",
        "prompt": "Anime visual novel background of stormy ocean sea cliffs at midnight, crashing dark blue waves with glowing seafoam, ancient jagged black rocks and a weathered oceanic tower silhouette under moonlight and sea mist, mysterious kraken lair, landscape only, no characters"
    },
    "lucidria": {
        "name": "Lucidria",
        "title": "ANCIENT MACE GUARDIAN",
        "element": "EARTH",
        "status": "PENDING_QUOTA",
        "file": "bg_lucidria.jpg",
        "concept": "Ancient forgotten stone monolith forest, giant moss-covered megalith pillars, lush ivy and blooming wildflowers climbing ruins.",
        "prompt": "Anime visual novel background of an ancient forgotten stone monolith forest, giant moss-covered megalith pillars, lush ivy and blooming wildflowers climbing ancient cobblestone ruins, gentle dappled golden sunbeams, serene sacred grove, landscape only, no characters"
    },
    "eurnipha": {
        "name": "Eurnipha",
        "title": "VOID ABYSSAL MATRON",
        "element": "DARK",
        "status": "PENDING_QUOTA",
        "file": "bg_eurnipha.jpg",
        "concept": "Cosmic void sanctuary, swirling violet and deep magenta nebulas, dark floating obsidian crystal islands in endless starry expanse.",
        "prompt": "Anime visual novel background of a deep cosmic void sanctuary, swirling violet and deep magenta nebulas, dark floating obsidian crystal islands connected by ribbons of purple light, mysterious endless starry expanse, landscape only, no characters"
    },
    "rumi": {
        "name": "Rumi",
        "title": "CRIMSON HORN EXORCIST",
        "element": "DARK",
        "status": "PENDING_QUOTA",
        "file": "bg_rumi.jpg",
        "concept": "Mystical Japanese demon shrine at midnight, multiple crimson torii gates, red paper lanterns, and spirit fire wisps.",
        "prompt": "Anime visual novel background of a mystical Japanese demon shrine at midnight, multiple crimson torii gates lining a stone path, glowing red paper lanterns hanging from ancient cedar trees, floating sacred talismans and spirit fire wisps, landscape only, no characters"
    },
    "mora": {
        "name": "Mora",
        "title": "CHRONOS ASTRAL SISTER",
        "element": "LIGHT",
        "status": "PENDING_QUOTA",
        "file": "bg_mora.jpg",
        "concept": "Celestial clockwork observatory, giant glowing golden time gears and pendulums floating in the air under a vaulted starry dome.",
        "prompt": "Anime visual novel background of a magnificent celestial clockwork observatory, giant glowing golden time gears and pendulums floating in the air, astronomical astrolabes, starry midnight sky visible through a vaulted glass dome, landscape only, no characters"
    },
    "abadonia": {
        "name": "Abadonia",
        "title": "ABYSSAL LION QUEEN",
        "element": "DARK",
        "status": "PENDING_QUOTA",
        "file": "bg_abadonia.jpg",
        "concept": "Abyssal Pride royal throne room, black marble pillars, regal crimson velvet banners with golden lion emblems, burning torches.",
        "prompt": "Anime visual novel background of the Abyssal Pride royal throne room, majestic black marble pillars, regal crimson velvet banners with golden lion emblems, burning golden torch braziers, grand dark royal palace interior, landscape only, no characters"
    },
    "rubby": {
        "name": "Rubby",
        "title": "BOMB BELLE",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_rubby.jpg",
        "concept": "Colorful pyrotechnics workshop and festival courtyard, exploding colorful fireworks illuminating the evening sky.",
        "prompt": "Anime visual novel background of a bustling colorful pyrotechnics workshop and festival courtyard, exploding colorful fireworks illuminating the evening sky, brass gears, barrels, and sparklers, vibrant festive atmosphere, landscape only, no characters"
    },
    "schylua": {
        "name": "Schylua",
        "title": "FROST REAPER",
        "element": "ICE",
        "status": "PENDING_QUOTA",
        "file": "bg_schylua.jpg",
        "concept": "Silent frozen glacial cave, towering translucent blue ice crystals and hanging icicles, glassy frozen lake under winter moon.",
        "prompt": "Anime visual novel background of a silent frozen glacial cave, towering translucent blue ice crystals and hanging icicles, a glassy frozen lake reflecting a pale winter moon, gentle drifting snow, serene glacial landscape, landscape only, no characters"
    },
    "siv": {
        "name": "Siv",
        "title": "THUNDER HAMMER MAIDEN",
        "element": "LIGHTNING",
        "status": "PENDING_QUOTA",
        "file": "bg_siv.jpg",
        "concept": "Grand dwarven lightning forge inside a massive cavern, giant glowing runic anvils, streams of molten metal and electric sparks.",
        "prompt": "Anime visual novel background of a grand dwarven lightning forge inside a massive cavern, giant glowing runic anvils, streams of molten metal and crackling electric lightning sparks, heavy iron chains and colossal stone arches, landscape only, no characters"
    },
    "vexira": {
        "name": "Vexira",
        "title": "SUCCUBUS TEMPTRESS",
        "element": "DARK",
        "status": "PENDING_QUOTA",
        "file": "bg_vexira.jpg",
        "concept": "Luxurious gothic demon palace bedroom lounge, deep purple velvet curtains, violet candelabras, scattered black rose petals on marble.",
        "prompt": "Anime visual novel background of a luxurious gothic demon palace bedroom lounge, deep purple and velvet crimson curtains, glowing violet candelabras, scattered black rose petals on polished marble, arched gothic balcony overlooking a full moon, landscape only, no characters"
    },
    "zennyo": {
        "name": "Zennyo Ryuo",
        "title": "DRAGON KING'S DAUGHTER",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_zennyo.jpg",
        "concept": "Dragon King's mountain retreat, traditional vermilion Japanese pagoda overlooking steaming natural onsen hot springs, cherry blossoms.",
        "prompt": "Anime visual novel background of the Dragon King's mountain retreat, traditional vermilion Japanese pagoda overlooking steaming natural onsen hot springs, blooming cherry blossom trees, dragon carvings and mountain peaks in twilight, landscape only, no characters"
    },
    "kara": {
        "name": "Kara",
        "title": "PHOENIX REAPER",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_kara.jpg",
        "concept": "Ancient gothic graveyard illuminated by crimson phoenix flames, glowing orange embers rising into twilight sky, weathered stone mausoleums.",
        "prompt": "Anime visual novel background of an ancient gothic graveyard illuminated by crimson phoenix flames, glowing orange embers rising into a twilight sky, weathered stone mausoleums and dark iron gates, mystical phoenix realm, landscape only, no characters"
    },
    "mei": {
        "name": "Mei",
        "title": "CRIMSON BLADE BUNNY",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_mei.jpg",
        "concept": "Oriental moonlit courtyard under a giant crimson harvest moon, vibrant red Japanese maple trees shedding leaves onto stone veranda.",
        "prompt": "Anime visual novel background of an oriental moonlit courtyard under a giant crimson harvest moon, vibrant red Japanese maple trees shedding leaves onto stone pavement, traditional wooden temple veranda, romantic martial night scene, landscape only, no characters"
    },
    "ninger": {
        "name": "Ning Er",
        "title": "PRINCESS OF A THOUSAND COINS",
        "element": "EARTH",
        "status": "PENDING_QUOTA",
        "file": "bg_ninger.jpg",
        "concept": "Grand imperial prosperity garden, golden ornate pavilions, sparkling gold coins and jade ornaments decorating blooming peach trees.",
        "prompt": "Anime visual novel background of a grand imperial prosperity garden, golden ornate pavilions, sparkling gold coins and jade ornaments decorating blooming peach blossom trees, stone footbridges over tranquil golden koi ponds, opulent oriental palace, landscape only, no characters"
    },
    "spimei": {
        "name": "Spimei",
        "title": "SCARLET SPIDER ENGINE",
        "element": "FIRE",
        "status": "PENDING_QUOTA",
        "file": "bg_spimei.jpg",
        "concept": "High-tech mech hangar and spider drone factory, industrial metal catwalks, crimson holographic diagnostic monitors, laser grids.",
        "prompt": "Anime visual novel background of a high-tech mech hangar and spider drone factory, industrial metal catwalks, crimson holographic diagnostic monitors, robotic assembly arms and red laser warning grids, dark sci-fi military workshop, landscape only, no characters"
    },
    "luby": {
        "name": "Luby",
        "title": "MECHA CAT MISCHIEF",
        "element": "WIND",
        "status": "PENDING_QUOTA",
        "file": "bg_luby.jpg",
        "concept": "Vibrant cyberpunk inventor workshop, glowing neon cat signs, colorful holographic blueprints, gadgets, robot cat toys.",
        "prompt": "Anime visual novel background of a vibrant cyberpunk inventor workshop, glowing neon cat signs, colorful holographic blueprints, gadgets, robot cat toys, cute mechanical tools on workbenches, cozy futuristic anime room, landscape only, no characters"
    },
    "seraph": {
        "name": "Seraph",
        "title": "ARCHANGEL OF A THOUSAND EYES",
        "element": "LIGHT",
        "status": "PENDING_QUOTA",
        "file": "bg_seraph.jpg",
        "concept": "Transcendent cosmic celestial realm, glowing sacred geometry mandalas and golden halo rings floating in an infinite pastel cloudscape.",
        "prompt": "Anime visual novel background of a transcendent cosmic celestial realm, glowing sacred geometry mandalas and golden halo rings floating in an infinite pastel cloudscape, divine radiant illumination, heavenly astral dimension, landscape only, no characters"
    },
    "tamo": {
        "name": "Tamo",
        "title": "NINE-TAILED SWORD QUEEN",
        "element": "EARTH",
        "status": "PENDING_QUOTA",
        "file": "bg_tamo.jpg",
        "concept": "Sacred nine-tailed fox ancient forest shrine, massive cedar tree wrapped in shimenawa ropes, mossy stone fox statues, spirit orbs.",
        "prompt": "Anime visual novel background of a sacred nine-tailed fox ancient forest shrine, massive thousand-year-old sacred cedar tree wrapped in shimenawa ropes, mossy stone fox statues with red bibs, glowing spirit orbs in mystical twilight fog, landscape only, no characters"
    },
    "gravity": {
        "name": "Gravity",
        "title": "GRAVITY BLACK MARKET",
        "element": "SPACE",
        "status": "PENDING_QUOTA",
        "file": "bg_gravity.jpg",
        "concept": "Futuristic underground cyberpunk black market alley, floating antigravity shipping containers, neon signs, holographic vendor stalls.",
        "prompt": "Anime visual novel background of a futuristic underground cyberpunk black market alley, floating antigravity shipping containers, glowing neon signs in magenta and cyan, holographic vendor stalls in a dense rainy cyberpunk city street, landscape only, no characters"
    },
    "tora": {
        "name": "Tora",
        "title": "LIZARD DRAGON WARRIOR",
        "element": "EARTH",
        "status": "PENDING_QUOTA",
        "file": "bg_tora.jpg",
        "concept": "Prehistoric volcanic jungle ravine, giant ancient ferns, glowing geothermal vents and smoking volcano peaks under stormy sky.",
        "prompt": "Anime visual novel background of a prehistoric volcanic jungle ravine, giant ancient ferns, glowing geothermal vents and distant smoking volcano peaks under a stormy primitive sky, rugged tribal stone totems, landscape only, no characters"
    },
    "yumi": {
        "name": "Yumi",
        "title": "RABBIT MARTIAL FIGHTER",
        "element": "WIND",
        "status": "PENDING_QUOTA",
        "file": "bg_yumi.jpg",
        "concept": "Traditional martial arts mountain training dojo courtyard, wooden training posts, falling cherry blossom petals, scenic overlook.",
        "prompt": "Anime visual novel background of a traditional martial arts mountain training dojo courtyard, wooden training posts, falling cherry blossom petals, stone lantern, scenic overlook of rolling green mountain peaks and morning mist, landscape only, no characters"
    }
}
