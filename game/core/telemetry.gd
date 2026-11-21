extends RefCounted
## Playtest log: anonymous gameplay events, kept ON THIS DEVICE ONLY. Nothing is sent anywhere.
## A playtester exports it from Settings > PLAYTEST DATA (download / copy) and sends the file to the dev;
## `python3 tools/playtest_report.py <files or folder>` merges many exports into retention and funnel numbers.
##
## Privacy: a random id (not tied to the device, account or name), coarse platform info, timestamps and
## game actions. No player name, no save contents, no IP.
##
## Only records in exported builds (the editor binary, flow_test, smoke and audit runs are skipped).
## Set env PLAYTEST=1 to record while running from source.
## Used through `Game.tele(...)`; preloaded, no class_name (a new class_name breaks headless runs before import).

const LOG_PATH := "user://playtest_log.json"
const FORMAT := 1
const MAX_EVENTS := 5000
const NEW_SESSION_GAP := 1800   # seconds without any event = the player left; the next event starts a new session
const BEAT_SECS := 120          # heartbeat while the game is open, so session length is known even without a quit event
const FLUSH_SECS := 15

static var _data: Dictionary = {}
static var _loaded := false
static var _sess := 0
static var _sess_t := 0
static var _last_t := 0
static var _dirty := false
static var _flush_acc := 0.0
static var _beat_acc := 0.0

static func _now() -> int:
	return int(Time.get_unix_time_from_system())

static func available() -> bool:
	if not Game.persist:
		return false
	return not OS.has_feature("editor") or OS.get_environment("PLAYTEST") == "1"

static func enabled() -> bool:
	if Game.s.is_empty() or not Game.s.has("player"):   # save not loaded yet (early window notifications)
		return false
	return available() and bool(Game.s.get("settings", {}).get("playtest_log", true))

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if FileAccess.file_exists(LOG_PATH):
		var f := FileAccess.open(LOG_PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and int((parsed as Dictionary).get("format", 0)) == FORMAT:
				_data = parsed
	if _data.is_empty():
		_data = {"format": FORMAT, "id": _new_id(), "install": _now(), "sessions": 0, "events": []}
		_dirty = true

static func _new_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var out := ""
	for i in 12:
		out += "%x" % rng.randi_range(0, 15)
	return out

static func _platform() -> String:
	if OS.has_feature("web_ios"):
		return "web_ios"
	if OS.has_feature("web_android"):
		return "web_android"
	if OS.has_feature("web"):
		return "web_desktop"
	return OS.get_name().to_lower()

## Called once when the game boots (after the save is loaded).
static func begin() -> void:
	if not enabled():
		return
	_load()
	_start_session()

static func _start_session() -> void:
	_data["sessions"] = int(_data.get("sessions", 0)) + 1
	_sess = int(_data["sessions"])
	_sess_t = _now()
	_last_t = _sess_t
	var sz := DisplayServer.window_get_size()
	_push({"e": "start", "plat": _platform(), "w": sz.x, "h": sz.y,
		"lvl": int(Game.s["player"]["level"]), "stages": Game.stages_cleared(),
		"day": (_sess_t - int(_data["install"])) / 86400})

## Records one event. `fields` uses short keys; keep values small (numbers / short strings).
static func log_event(name: String, fields: Dictionary = {}) -> void:
	if not enabled():
		return
	_load()
	if _sess == 0 or _now() - _last_t > NEW_SESSION_GAP:
		_start_session()
	var ev := fields.duplicate()
	ev["e"] = name
	_push(ev)

static func _push(ev: Dictionary) -> void:
	var t := _now()
	ev["t"] = t
	ev["s"] = _sess
	_last_t = t
	var evs: Array = _data["events"]
	evs.append(ev)
	if evs.size() > MAX_EVENTS:
		# keep every session start (retention needs them), drop the oldest other events
		for i in evs.size():
			if str((evs[i] as Dictionary).get("e", "")) != "start":
				evs.remove_at(i)
				break
	_dirty = true

## Called every second by Game._process.
static func tick(delta: float) -> void:
	if not _loaded or not enabled():
		return
	_beat_acc += delta
	if _beat_acc >= BEAT_SECS:
		_beat_acc = 0.0
		log_event("beat")
	_flush_acc += delta
	if _flush_acc >= FLUSH_SECS:
		_flush_acc = 0.0
		flush()

static func flush() -> void:
	if not _dirty or not _loaded or not available():
		return
	_dirty = false
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data))

## The whole log as text (what the playtester sends).
static func export_text() -> String:
	_load()
	var out := _data.duplicate()
	out["exported"] = _now()
	out["version"] = "v2.1"
	return JSON.stringify(out)

static func file_name() -> String:
	_load()
	return "euphoria_playtest_%s.json" % str(_data["id"])

static func clear() -> void:
	_data = {}
	_loaded = false
	_sess = 0
	if FileAccess.file_exists(LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
	_load()
	_start_session()
	flush()

## Small numbers for the Settings card, so the tester sees what is recorded.
static func summary() -> Dictionary:
	_load()
	var evs: Array = _data["events"]
	var days := {}
	for ev in evs:
		days[(int(ev["t"]) - int(_data["install"])) / 86400] = true
	return {"id": str(_data["id"]), "events": evs.size(), "sessions": int(_data.get("sessions", 0)), "days": days.size()}

## The newest events as readable lines (Send Log popup preview: the tester sees exactly what is in the file).
static func preview(lines: int = 40) -> String:
	_load()
	var evs: Array = _data["events"]
	var out: PackedStringArray = []
	for i in range(maxi(0, evs.size() - lines), evs.size()):
		var ev: Dictionary = evs[i]
		var parts: PackedStringArray = []
		for k in ev.keys():
			if k not in ["t", "e", "s"]:
				parts.append("%s=%s" % [k, str(ev[k])])
		var dt := Time.get_datetime_dict_from_unix_time(int(ev["t"]))
		out.append("%02d/%02d %02d:%02d  #%d  %-6s %s" % [dt["day"], dt["month"], dt["hour"], dt["minute"], int(ev["s"]), str(ev["e"]), " ".join(parts)])
	out.reverse()
	return "\n".join(out)
