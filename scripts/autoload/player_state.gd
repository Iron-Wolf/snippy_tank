extends Node

enum Scheme {BASIC, ARCADE, SIMULATION}
var control_scheme: Scheme = Scheme.BASIC

var last_aim_scheme: bool = false
var slingshot_scheme: bool = false
