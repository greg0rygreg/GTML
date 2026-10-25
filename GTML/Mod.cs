using Godot;

// Mod class used for G.T. Greg Modloader
//
// Folder format:
// [codeblock lang=text]
// user://
// └─mods
//   ├─YourMod
//   │ ├─asset1.tscn
//   │ ├─asset1.gd
//   │ ├─asset2.png
//   │ ├─manifest.json
//   │ └─main.gd
//   └─AnotherMod
//     ├─assets.pck
//     ├─manifest.json
//     ├─icon.png
//     └─main.gd
// [/codeblock]
// Clarification: [code]icon.png[/code] and [code]assetX.YZW[/code] are optional (handled by the game and by the mod, respectively), [code]main.gd[/code] and [code]manifest.json[/code] are required (both handled by the modloader)
[GlobalClass]
public partial class Mod : Node
{
  // The manifest of your mod
  public Godot.Collections.Dictionary Manifest = new()
  {
    { "name", "Mod Name Here" },
    { "author", "Author Name(s) Here" },
    { "codename", "ModNameHere-AuthorNamesHere" },
    { "semver", new Godot.Collections.Array<int>{0,0,0} },
    { "description", "Mod Description Here. List what you can do with it" },
    { "conflicts", new Godot.Collections.Array<string>() }
  };
  // Same as [code]GetTree().Root[/code]
  public Window Root;
  // The folder where your mod lives
  public string MyFolder;

  public override void _Ready()
  {
    Root = GetTree().Root;
    MyFolder = ((CSharpScript)GetScript()).ResourcePath.GetBaseDir();
  }
}
