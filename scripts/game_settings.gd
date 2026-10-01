extends Node

## Kept outside the menu scene so the selected look survives scene changes.
var bean_color := Color("6fe4ff")
var eye_style := 0
var launch_mode := "host"
var join_code := ""

const BEAN_COLORS := [
	Color("6fe4ff"), Color("ff7aa8"), Color("b6f36b"), Color("a987ff"), Color("ffbe4d")
]

const EYE_STYLES := ["Classic", "Googly", "Sleepy"]
