extends Node

# movement
enum Scheme {BASIC, ARCADE, SIMU}
var control_scheme: Scheme = Scheme.BASIC

# aim
var last_aim_scheme: bool = false
var slingshot_scheme: bool = false
