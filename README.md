## carbonizer
A pure swift, easy-to-use Fossil Fighters ROM-hacking tool.

### How it works
Point carbonizer towards a file or folder, and it'll automatically pack or unpack whatever input it receives.
It determines whether to pack or unpack based on the file extensions and binary magic ids it sees, and if it doesn't recognize any, asks what to do.

### Supported file types
- `.nds` - Nintendo DS ROM files
- `3CL`/`.3cl.json` - vivosaur 3D models
- `BBG`/`.bbg.json` - [kasekiums](https://github.com/simonomi/ff1-binary-formats/wiki/BBG)
- `CHR`/`.chr.json` - characters
- `DBS`/`.dbs.json` - [battles](https://github.com/simonomi/ff1-binary-formats/wiki/DBS)
- `DEP`/`.dep.txt` - [cutscene coordination](https://github.com/simonomi/ff1-binary-formats/wiki/DEP)
- `DEX`/`.dex.txt` - [cutscenes](https://github.com/simonomi/ff1-binary-formats/wiki/DEX)
- `DMG`/`.dmg.json` - [dialog](https://github.com/simonomi/ff1-binary-formats/wiki/DMG)
- `DMS`/`.dms.json` - [config values](https://github.com/simonomi/ff1-binary-formats/wiki/DMS)
- `DTX`/`.dtx.json` - [text](https://github.com/simonomi/ff1-binary-formats/wiki/DTX)
- `ECS`/`.ecs.json` - excavate defs
- `HML`/`.hml.json` - [masks](https://github.com/simonomi/ff1-binary-formats/wiki/HML)
- `MAR`/`.mar` - [archives](https://github.com/simonomi/ff1-binary-formats/wiki/MAR,-MCM)
- `MM3`/`.mm3.json` - [3D models](https://github.com/simonomi/ff1-binary-formats/wiki/MM3)
- `MMS`/`.mms.json` - sprites
- `MPM`/`.mpm.json` - [images](https://github.com/simonomi/ff1-binary-formats/wiki/MPM)
- `RLS`/`.rls.json` - [fossils](https://github.com/simonomi/ff1-binary-formats/wiki/RLS)
- `SHP`/`.shp.json` - shop files

See [this wiki](https://github.com/simonomi/FF1_Binary_Formats/wiki) for specific information on Fossil Fighters' proprietary binary formats.

### How to use
#### Drag-and-drop (Windows only)
Simply drag the file or folder you want to pack/unpack onto the executable.

Then, edit the files within using a text editor (I recommend [Notepad++](https://notepad-plus-plus.org))

#### Commandline
```
OVERVIEW: A Fossil Fighters ROM-hacking tool

By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions,
magic bytes, and metadata

USAGE: carbonizer [--pack] [--unpack] [--auto] [--ask] [<file-paths> ...]

ARGUMENTS:
  <file-paths>            The files to pack/unpack

OPTIONS:
  -p, --pack/-u, --unpack/--auto/--ask
                          Manually specify compression mode (default: --auto)
  -h, --help              Show help information.
```

### Usage notes
The easiest way to use carbonizer is to unpack an entire `.nds` file into a folder in the same directory, then modifying the contents of that directory and repacking it back into an `.nds` file.
