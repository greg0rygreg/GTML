extends Node2D

func _input(event: InputEvent) -> void:
  if event.as_text() == "K" and event.is_released():
    get_tree().change_scene_to_file("res://second.tscn")
