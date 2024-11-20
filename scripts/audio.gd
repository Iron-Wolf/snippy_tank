extends AudioStreamPlayer

@onready var s: AudioStreamSynchronized = stream

const AUDIO_CHILL: int = 0
const AUDIO_FIGHT: int = 1

func _ready() -> void:
	play()
	#var s1: AudioStreamMP3 = s.get_sync_stream(0)
	#var p:AudioStreamPlayback = s1.instantiate_playback()

func _process(delta: float) -> void:
	var v = s.get_sync_stream_volume(AUDIO_CHILL)
	set_chill_volume(v + 0.2)

func _switch_audio() -> void:
	print("OMG")

func set_chill_volume(volume_db: float) -> void:
	if volume_db >= 0:
		s.set_sync_stream_volume(AUDIO_CHILL, 0)
	else:
		s.set_sync_stream_volume(AUDIO_CHILL, volume_db)

func set_fight_volume(volume_db: float) -> void:
	if volume_db >= 0:
		s.set_sync_stream_volume(AUDIO_FIGHT, 0)
	else:
		s.set_sync_stream_volume(AUDIO_FIGHT, volume_db)

signal switch_audio()
