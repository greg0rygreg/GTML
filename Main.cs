using Godot;

public partial class Main : Node2D
{
  public override void _Input(InputEvent @event)
  {
    if (@event.AsText() == "K" && @event.IsReleased())
      GetTree().ChangeSceneToFile("res://second.tscn");
  }
}
