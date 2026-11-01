extends Node
## UTC offline growth, monotonic foreground elapsed, injectable deterministic clock.
var _anchor_utc: int = 0
var _anchor_ticks: int = 0
var _last_utc: int = 0
var _mock_enabled: bool = false
var _mock_wall: int = 0

func _ready() -> void:
	observe_floor(int(Time.get_unix_time_from_system()))

func now_utc() -> int:
	if _mock_enabled:
		_last_utc = maxi(_last_utc, _mock_wall)
		return _last_utc
	var ticks: int = Time.get_ticks_msec()
	var estimated: int = _anchor_utc + int((ticks - _anchor_ticks) / 1000)
	var wall: int = int(Time.get_unix_time_from_system())
	if wall > estimated:
		_anchor_utc = wall
		_anchor_ticks = ticks
		estimated = wall
	_last_utc = maxi(_last_utc, estimated)
	return _last_utc

func observe_floor(minimum_utc: int) -> void:
	_last_utc = maxi(maxi(_last_utc, minimum_utc), _mock_wall if _mock_enabled else int(Time.get_unix_time_from_system()))
	_anchor_utc = _last_utc
	_anchor_ticks = Time.get_ticks_msec()

func begin_mock(value: int) -> void:
	_mock_enabled = true
	_mock_wall = value
	_last_utc = value
	_anchor_utc = value
	_anchor_ticks = Time.get_ticks_msec()

func set_mock_wall(value: int) -> void:
	assert(_mock_enabled)
	_mock_wall = value

func advance_mock(seconds: int) -> void:
	assert(_mock_enabled)
	_mock_wall += seconds

func use_real_clock() -> void:
	_mock_enabled = false
	_last_utc = 0
	_anchor_utc = 0
	observe_floor(int(Time.get_unix_time_from_system()))
