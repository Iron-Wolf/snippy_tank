extends AudioStreamPlayer

@export var mute:bool = false

@onready var audio_stream: AudioStreamSynchronized = stream
@onready var time_in_fight: Timer = $time_in_fight
@onready var intro_audio: AudioStreamPlayer = $intro_audio
@onready var master_bus_idx = AudioServer.get_bus_index("Master")

# constants
enum AudioIdx {CHILL = 0, FIGHT = 1}
const MAX_TIME_IN_FIGHT: int = 4 # time (seconds) before music chilling again
const SPEED_TRANSITION: float = 0.4

func _ready() -> void:
	if mute:
		return
	
	time_in_fight.wait_time = MAX_TIME_IN_FIGHT
	time_in_fight.one_shot = true
	# "0" is the base volume
	set_volume(AudioIdx.CHILL, 0)
	intro_audio.play()

func _process(_delta: float) -> void:
	if mute:
		return
	
	# NOTE : maybe add effects ?
	var _disto: AudioEffectDistortion = AudioServer.get_bus_effect(master_bus_idx, 0)
	
	if intro_audio.playing:
		# wait intro to finish
		return
	elif not playing:
		# start main loop
		play()
		
	var volume_chill: float = audio_stream.get_sync_stream_volume(AudioIdx.CHILL)
	var volume_fight: float = audio_stream.get_sync_stream_volume(AudioIdx.FIGHT)
	#print(round(time_in_fight.time_left), "/", 
	#	round(volume_chill), "/", 
	#	round(volume_fight))
	if time_in_fight.time_left == 0:
		# slowly back to chill business,
		# because we don't want to loose the action !
		set_volume(AudioIdx.CHILL, volume_chill + SPEED_TRANSITION/2)
		if volume_chill > -20:
			set_volume(AudioIdx.FIGHT, volume_fight - SPEED_TRANSITION/2)
	else:
		# quiclky jump into the absolute mayhem !
		set_volume(AudioIdx.FIGHT, volume_fight + SPEED_TRANSITION)
		if volume_fight > -20:
			set_volume(AudioIdx.CHILL, volume_chill - SPEED_TRANSITION)

func set_volume(idx: int, volume: float) -> void:
	var v = clamp(volume, -60, 0)
	audio_stream.set_sync_stream_volume(idx, v)

func on_fight_started() -> void:
	time_in_fight.start(MAX_TIME_IN_FIGHT)

func on_round_started() -> void:
	$NewRoundAudio.play()
