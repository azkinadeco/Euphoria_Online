"""Loading-screen slideshow = in-game maps only (owner, 20 Nov 2026: no heroes on the download screen).
Writes web_shell/loading/map_<key>.jpg and removes the old hero_*.webp / bg_<hero>.jpg slides.
Run: python3 tools/make_maps_loading.py   (then publish_web.sh copies web_shell/loading)"""
import glob, os
from PIL import Image
OUT = 'web_shell/loading'
MAPS = [  # key, file under 'backround image'
    ('forest', 'maps forest.jpg'), ('aqua', 'maps aqua.jpg'), ('dragonfire', 'new backround maps/dragon fire maps.jpg'),
    ('asgard', 'maps assgard.jpg'), ('frost', 'maps es.jpg'), ('bigtree', 'maps big tree world.jpg'),
    ('necro', 'new backround maps/necro maps.jpg'), ('galaxy', 'maps galaxy.jpg'), ('dino', 'new backround maps/dino maps.jpg'),
    ('outland', 'new backround maps/outland maps.jpg'),
]
for f in glob.glob(os.path.join(OUT, 'hero_*.webp')) + glob.glob(os.path.join(OUT, 'bg_*.jpg')):
    os.remove(f)
for key, src in MAPS:
    im = Image.open(os.path.join('backround image', src)).convert('RGB')
    im = im.resize((1280, round(im.height * 1280 / im.width)), Image.Resampling.LANCZOS)
    im.save(os.path.join(OUT, 'map_%s.jpg' % key), quality=74, optimize=True, progressive=True)
print('const SLIDES = [' + ', '.join("'%s'" % k for k, _ in MAPS) + '];')
print('%d files, %.0f KB' % (len(os.listdir(OUT)), sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT)) / 1024))
