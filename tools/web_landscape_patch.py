#!/usr/bin/env python3
"""Teaches the exported Godot web engine (web/Euphoria_v2.js) about the turned page.

The shell (web_shell/euphoria_shell.html) turns the canvas 90 degrees when a phone is held upright, so the
game is always landscape. The engine must then (1) size the canvas to the LANDSCAPE frame and (2) map taps
and drags back through the rotation. window.__eoRot() (defined by the shell) says whether the page is turned.
Run by tools/publish_web.sh after every export. Fails loudly if the engine code changed shape.
"""
import sys

P = sys.argv[1] if len(sys.argv) > 1 else 'web/Euphoria_v2.js'
ROT = '(window.__eoRot&&window.__eoRot())'

PATCHES = [
    # pointer / touch position: canvas x runs down the screen, canvas y runs right-to-left
    ('computePosition:function(evt,rect){const canvas=GodotConfig.canvas;const rw=canvas.width/rect.width;'
     'const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;const y=(evt.clientY-rect.y)*rh;return[x,y]}',
     'computePosition:function(evt,rect){const canvas=GodotConfig.canvas;if' + ROT + '{'
     'return[(evt.clientY-rect.y)*(canvas.width/rect.height),(rect.x+rect.width-evt.clientX)*(canvas.height/rect.width)]}'
     'const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;'
     'const y=(evt.clientY-rect.y)*rh;return[x,y]}'),
    # relative mouse motion (drags)
    ('const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const rel_pos_x=evt.movementX*rw;'
     'const rel_pos_y=evt.movementY*rh;',
     'const turned=' + ROT + ';const rw=turned?canvas.width/rect.height:canvas.width/rect.width;'
     'const rh=turned?canvas.height/rect.width:canvas.height/rect.height;'
     'const rel_pos_x=(turned?evt.movementY:evt.movementX)*rw;const rel_pos_y=(turned?-evt.movementX:evt.movementY)*rh;'),
    # canvas size: the landscape frame
    ('if(isFullscreen||wantsFullWindow){width=Math.floor(window.innerWidth*scale);height=Math.floor(window.innerHeight*scale)}',
     'if(isFullscreen||wantsFullWindow){const turned=' + ROT + ';'
     'width=Math.floor((turned?window.innerHeight:window.innerWidth)*scale);'
     'height=Math.floor((turned?window.innerWidth:window.innerHeight)*scale)}'),
]


def main():
    s = open(P, encoding='utf-8').read()
    if '__eoRot' in s:
        print('landscape patch: already applied')
        return
    for old, new in PATCHES:
        n = s.count(old)
        if n != 1:
            sys.exit('landscape patch: engine code not found (%d matches): %s...' % (n, old[:60]))
        s = s.replace(old, new)
    open(P, 'w', encoding='utf-8').write(s)
    print('landscape patch: %d engine spots patched' % len(PATCHES))


if __name__ == '__main__':
    main()
