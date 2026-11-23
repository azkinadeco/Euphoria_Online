extends Node
## Background download of the deferred art packs (web build only; see tools/make_art_packs.py).
##
## The main download leaves evolution art out. After boot this node fetches the small packs one at a time
## (packs with heroes the player owns first), keeps them in user:// (IndexedDB on the web, so the next visit
## does not download again) and mounts them with ProjectSettings.load_resource_pack. Until a pack is mounted,
## DB.tex() shows the Lv1 form (DB.waiting / DB.stand_in).
##
## Desktop test of an exported pck:  ART_PACK_URL=http://127.0.0.1:8765/  Godot --main-pack builds/Euphoria_v2.pck
## Added by Game._ready (not an autoload). No class_name (headless runs before import).

const MANIFEST := "res://data/deferred_art.json"
const RETRY_SECS := 20.0
const MAX_TRIES := 6

var _packs: Array = []
var _queue: Array = []       # pack indexes still to fetch
var _http: HTTPRequest
var _cur := -1
var _tries := 0
var _base_url := ""
var mounted := 0
var started_ms := 0
var last_error := ""        # shown in the HD art download popup
var bytes_done := 0
var bytes_total := 0
var _js_ok: JavaScriptObject
var _js_err: JavaScriptObject
var _use_js := false        # web: download with the browser's fetch() (HTTPRequest stalled on phones)
var _stall_t := 0.0
var _last_bytes := -1
const STALL_SECS := 40.0     # no new bytes for this long = the download hung: cancel and retry

func _ready() -> void:
	if not FileAccess.file_exists(MANIFEST):
		return
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not (m is Dictionary):
		return
	_packs = m["packs"]
	if OS.get_environment("ART_PACK_DEBUG") != "":
		var f0 := str(_packs[0]["files"][0])
		var st: Texture2D = DB.tex(f0)
		print("ARTPACK packs=%d first=%s exists=%s stand-in=%s url=%s" % [_packs.size(), f0, ResourceLoader.exists(f0), st.resource_path if st else "NULL", _find_base_url()])
	# already in this pck (desktop / editor builds): nothing to do
	if _packs.is_empty() or ResourceLoader.exists(str(_packs[0]["files"][0])):
		return
	_base_url = _find_base_url()
	_cleanup_old(str(m["v"]))
	started_ms = Time.get_ticks_msec()
	var owned: Dictionary = Game.s.get("heroes", {})
	var order: Array = range(_packs.size())
	order.sort_custom(func(a, b):
		var oa := (_packs[a]["ids"] as Array).any(func(i): return owned.has(i))
		var ob := (_packs[b]["ids"] as Array).any(func(i): return owned.has(i))
		return oa and not ob if oa != ob else a < b)
	for i in order:
		if _mount_cached(i):
			continue
		_queue.append(i)
	for p in _packs:
		bytes_total += int(p.get("bytes", 0))
	_use_js = OS.has_feature("web")
	if _use_js:
		JavaScriptBridge.eval("""window.__eoFetchPack = function (url, ok, err) {
			fetch(url, {cache: 'force-cache'}).then(function (r) {
				if (!r.ok) { throw new Error('http ' + r.status); }
				return r.arrayBuffer();
			}).then(function (buf) {
				var b = new Uint8Array(buf), s = '', CH = 0x8000;
				for (var i = 0; i < b.length; i += CH) { s += String.fromCharCode.apply(null, b.subarray(i, i + CH)); }
				ok(btoa(s));
			}).catch(function (e) { err(String(e)); });
		};""", true)
		_js_ok = JavaScriptBridge.create_callback(_on_js_ok)
		_js_err = JavaScriptBridge.create_callback(_on_js_err)
		if not _queue.is_empty() and _base_url != "":
			_next.call_deferred()
		return
	if not _queue.is_empty() and _base_url != "":
		_http = HTTPRequest.new()
		# the Web export has thread_support=false: a threaded HTTPRequest never finishes there ("Loading HD" forever)
		_http.use_threads = not OS.has_feature("web")
		_http.timeout = 120.0
		add_child(_http)
		_http.request_completed.connect(_on_done)
		_next.call_deferred()

func _process(delta: float) -> void:
	if _use_js:
		return
	if _http == null or _cur < 0 or _http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		return
	var b := _http.get_downloaded_bytes()
	if b != _last_bytes:
		_last_bytes = b
		_stall_t = 0.0
		return
	_stall_t += delta
	if _stall_t >= STALL_SECS:
		_stall_t = 0.0
		_last_bytes = -1
		_http.cancel_request()
		DirAccess.remove_absolute(_cache_path(_cur) + ".part")
		_retry("stalled")

func _find_base_url() -> String:
	var env := OS.get_environment("ART_PACK_URL")
	if env != "":
		return env if env.ends_with("/") else env + "/"
	if OS.has_feature("web"):
		var href: Variant = JavaScriptBridge.eval("new URL('.', window.location.href).href", true)
		return str(href) if href != null else ""
	return ""

func _cache_path(i: int) -> String:
	return "user://art_packs/" + str(_packs[i]["file"])

## Packs from older builds (different version hash) are deleted so they don't fill the browser storage.
func _cleanup_old(v: String) -> void:
	var dir := "user://art_packs"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		if not f.contains(v):
			DirAccess.remove_absolute(dir.path_join(f))

func _mount_cached(i: int) -> bool:
	var p := _cache_path(i)
	if not FileAccess.file_exists(p):
		return false
	if FileAccess.get_size(p) <= 0 or not ProjectSettings.load_resource_pack(p, true):
		DirAccess.remove_absolute(p)   # damaged: fetch it again
		return false
	_mounted(i, "cache")
	return true

func _next() -> void:
	if _queue.is_empty():
		Game.tele("artpack", {"done": mounted, "of": _packs.size(), "sec": (Time.get_ticks_msec() - started_ms) / 1000})
		return
	_cur = int(_queue[0])
	_stall_t = 0.0
	_last_bytes = -1
	if _use_js:
		var win := JavaScriptBridge.get_interface("window")
		win.__eoFetchPack(_base_url + str(_packs[_cur]["file"]), _js_ok, _js_err)
		return
	_http.download_file = _cache_path(_cur) + ".part"
	var err := _http.request(_base_url + str(_packs[_cur]["file"]))
	if err != OK:
		_retry("request %d" % err)

func _on_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var part := _cache_path(_cur) + ".part"
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		DirAccess.remove_absolute(part)
		_retry("result %d http %d" % [result, code])
		return
	var dst := _cache_path(_cur)
	DirAccess.rename_absolute(part, dst)
	if not ProjectSettings.load_resource_pack(dst, true):
		DirAccess.remove_absolute(dst)
		_retry("mount failed")
		return
	_queue.pop_front()
	_tries = 0
	_mounted(_cur, "net")
	_next()

## Web: fetch() finished, args[0] = the pack as base64.
func _on_js_ok(args: Array) -> void:
	var raw := Marshalls.base64_to_raw(str(args[0]))
	var dst := _cache_path(_cur)
	var f := FileAccess.open(dst, FileAccess.WRITE)
	if f == null:
		_retry("write %d" % FileAccess.get_open_error())
		return
	f.store_buffer(raw)
	f = null
	if not ProjectSettings.load_resource_pack(dst, true):
		DirAccess.remove_absolute(dst)
		_retry("mount failed")
		return
	_queue.pop_front()
	_tries = 0
	_mounted(_cur, "net")
	_next()

func _on_js_err(args: Array) -> void:
	_retry("fetch: " + str(args[0] if args.size() > 0 else "?"))

## Download popup: start again now (after errors or a give-up).
func restart() -> void:
	if _packs.is_empty():
		return
	_tries = 0
	last_error = ""
	if _queue.is_empty():
		for i in _packs.size():
			if not ResourceLoader.exists(str(_packs[i]["files"][0])):
				_queue.append(i)
	if _queue.is_empty():
		return
	if not _use_js and _http == null:
		_http = HTTPRequest.new()
		_http.use_threads = false
		_http.timeout = 120.0
		add_child(_http)
		_http.request_completed.connect(_on_done)
	if not _use_js and _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_next()

func _retry(why: String) -> void:
	last_error = why
	_tries += 1
	Game.tele("artpack_err", {"p": _cur, "why": why, "n": _tries})
	if _tries >= MAX_TRIES:
		_queue.pop_front()   # give up on this one for this session; the Lv1 stand-in stays
		_tries = 0
		_next.call_deferred()
		return
	get_tree().create_timer(RETRY_SECS * _tries).timeout.connect(_next)

func _mounted(i: int, how: String) -> void:
	mounted += 1
	bytes_done += int(_packs[i].get("bytes", 0))
	DB.deferred_loaded(_packs[i]["files"])
	if OS.get_environment("ART_PACK_DEBUG") != "" and mounted == 1:
		var f := str(_packs[i]["files"][0])
		print("ARTPACK mounted %s via %s -> tex=%s" % [f, how, DB.tex(f).resource_path])
	if how == "net":
		Game.changed.emit()   # open screens rebuild with the real art

## The player is looking at `path` (an outfit that is still downloading): fetch its pack next.
func want(path: String) -> void:
	for qi in _queue.size():
		var i := int(_queue[qi])
		if (_packs[i]["files"] as Array).has(path):
			if qi > 1 or (qi == 1 and i != _cur):
				_queue.remove_at(qi)
				_queue.insert(1 if not _queue.is_empty() and int(_queue[0]) == _cur else 0, i)
			return

## For Settings: "HD art 7 / 12".
func progress() -> Vector2i:
	return Vector2i(mounted, _packs.size())
