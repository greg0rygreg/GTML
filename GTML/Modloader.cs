using Godot;
using System;
using System.Linq;

public partial class Modloader : Node
{
  // configurables
  // Mods folder location[br]
  // Default: [code]user://mods_cs[/code]
  public const string MODS_DIR = "user://mods_cs";


  // code
  // this manifest doesn't need a conflicts key
  public Godot.Collections.Dictionary Manifest = new()
  {
    {"name", "G.T. Greg Modloader (C# version)"},
    {"author", "greg0rygreg"},
    {"codename", "greg0rygreg-GTML_CSharp"},
    {"semver", new Godot.Collections.Array<int>{0,5,0}},
    {"description", "GTML for C# enthusiasts"}
  };
  public Godot.Collections.Dictionary<string, Mod> loadedmods = new();
  private DirAccess modsfolder = DirAccess.Open(MODS_DIR);
  // _modsfolder

  [Signal] public delegate void AllDoneEventHandler();
  [Signal] public delegate void ModLoadedEventHandler(Mod mod);
  [Signal] public delegate void ModUnloadedEventHandler(Mod mod);

  // Logging class used for logging things to the console
  public class Logging
  {
    // Logging levels: information, debug info, warnings and errors
    public enum Levels
    {
      INFO,
      DEBUG,
      WARNING,
      ERROR
    }

    // Logs to console
    public static void Write(string what, Godot.Collections.Dictionary manifest, Levels level = Levels.INFO)
    {
      string colorstart;
      string levelF;
      switch (level)
      {
        default:
          colorstart = "";
          levelF = "INFO";
          break;
        case Levels.DEBUG:
          colorstart = "[color=cyan]";
          levelF = "DEBUG";
          break;
        case Levels.WARNING:
          colorstart = "[color=yellow]";
          levelF = "WARN";
          break;
        case Levels.ERROR:
          colorstart = "[color=red]";
          levelF = "ERROR";
          break;
      }
      GD.PrintRich(
        "{colorstart}[b]{level}[/b] | {modname} ({codename}) :: {what}{colorend}"
        .Replace("{colorstart}", colorstart)
        .Replace("{level}", levelF)
        .Replace("{modname}", (string)manifest["name"])
        .Replace("{codename}", (string)manifest["codename"])
        .Replace("{what}", what)
        .Replace("{colorend}", (level == Levels.INFO ? "" : "[/color]"))
      );
    }
  }


  public async override void _Ready()
  {
    // make the manifest read only because Godot.Collections.Dictionary isn't constant-friendly apparently
    Manifest.MakeReadOnly();
    ((Godot.Collections.Array)Manifest["semver"]).MakeReadOnly();

    // wait for every node in root to get ready
    await ToSignal(GetTree().Root, Window.SignalName.Ready);

    // check for no mods mode
    if (OS.GetCmdlineUserArgs().Contains("--no-mods"))
    {
      Logging.Write("No Mods is enabled; initialization skipped", Manifest, Logging.Levels.WARNING);
      return;
    }

    Logging.Write("Started reading directory: {modsdir}".Replace("{modsdir}", MODS_DIR), Manifest, Logging.Levels.DEBUG);

    // signal shenanigans
    ModLoaded += mod => loadedmods[(string)mod.Manifest["codename"]] = mod;
    ModUnloaded += mod => mod.QueueFree();
    AllDone += loadedmods.MakeReadOnly;

    // check for null mods folder
    if (modsfolder == null)
    {
      DirAccess.MakeDirAbsolute(MODS_DIR);
      modsfolder = DirAccess.Open(MODS_DIR);
    }

    // get every mod in MODS_DIR
    string[] mods = modsfolder.GetDirectories();
    foreach (string modfolder in mods)
    {
      // check for disabled mods
      if (modfolder.StartsWith("_"))
      {
        Logging.Write("{modfolder} starts with underscore; skipped".Replace("{modfolder}", MODS_DIR.PathJoin(modfolder)), Manifest, Logging.Levels.DEBUG);
        continue;
      }

      DirAccess mod = DirAccess.Open(MODS_DIR.PathJoin(modfolder));

      // check for manifest.json
      if (!mod.FileExists("manifest.json"))
      {
        Logging.Write("{modfolder} doesn't have a manifest.json; skipped".Replace("{modfolder}", MODS_DIR.PathJoin(modfolder)), Manifest, Logging.Levels.DEBUG);
        continue;
      }

      // check for mods with no mods
      if (!mod.FileExists("Main.cs"))
      {
        Logging.Write("{modfolder} doesn't have a Main.cs; skipped".Replace("{modfolder}", MODS_DIR.PathJoin(modfolder)), Manifest, Logging.Levels.DEBUG);
        continue;
      }

      // load mod
      CSharpScript mod_script = GD.Load<CSharpScript>(MODS_DIR.PathJoin(modfolder).PathJoin("Main.cs"));
      Mod mod_instance = (Mod)mod_script.New();

      // inject some variables into the mod's code
      FileAccess manifest = FileAccess.Open(MODS_DIR.PathJoin(modfolder).PathJoin("manifest.json"), FileAccess.ModeFlags.Read);
      mod_instance.Manifest = (Godot.Collections.Dictionary)Godot.Json.ParseString(manifest.GetAsText());
      // yeah, even in C#....
      for (int i = 0; i < ((Godot.Collections.Array)mod_instance.Manifest["semver"]).Count; i++)
        ((Godot.Collections.Array)mod_instance.Manifest["semver"])[i] = Convert.ToInt32(((Godot.Collections.Array)mod_instance.Manifest["semver"])[i]);
      manifest.Close();
      mod_instance.Manifest.MakeReadOnly();

      // tell everyone a mod has LOADED, not INSTANTIATED
      EmitSignal(SignalName.ModLoaded, mod_instance);
      Logging.Write("Loaded {codename}".Replace("{codename}", (string)mod_instance.Manifest["codename"]), Manifest);
    }

    // check for conflicts
    Godot.Collections.Array<string> toUnload = new();
    foreach (Mod mod in loadedmods.Values)
    {
      foreach (string conflict in (Godot.Collections.Array<string>)mod.Manifest["conflicts"])
      {
        if (loadedmods.ContainsKey(conflict))
        {
          Logging.Write(
            "{conflict} conflicts with {warner}; first removed"
            .Replace("{conflict}", conflict)
            .Replace("{warner}", (string)mod.Manifest["codename"]),
            Manifest,
            Logging.Levels.ERROR
          );
          toUnload.Append((string)loadedmods[conflict].Manifest["codename"]);
        }
      }
    }
    foreach (string mod in toUnload)
    {
      EmitSignal(SignalName.ModUnloaded, loadedmods[mod]);
      loadedmods.Remove(mod);
    }

    // tell everyone a mod has instantiated
    foreach (Mod mod in loadedmods.Values)
    {
      Logging.Write("Instantiated {codename}".Replace("{codename}", (string)mod.Manifest["codename"]), Manifest);
      GetTree().Root.AddChild(mod);
    }

    EmitSignal(SignalName.AllDone);
  }
}
