using Godot;
using System;

public partial class Spinner : Sprite2D
{
  public override void _Process(double delta)
  {
    RotationDegrees += Convert.ToSingle(144.0 * delta);
  }
}
