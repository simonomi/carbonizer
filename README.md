## carbonizer
A pure swift, easy-to-use Fossil Fighters ROM-hacking tool.

### How it works
Point carbonizer towards a file or folder, and it'll automatically pack or unpack whatever input it receives.
It determines whether to pack or unpack based on the file extensions and binary magic ids it sees, and if it doesn't recognize any, asks what to do.

### Supported file types
- `.nds` - Nintendo DS ROM files
- `MAR`/`.mar` - [archives](https://github.com/simonomi/ff1-binary-formats/wiki/MAR,-MCM)
- `DTX`/`.dtx.json` - [text](https://github.com/simonomi/ff1-binary-formats/wiki/DTX)
- `DMG`/`.dmg.json` - [dialog](https://github.com/simonomi/ff1-binary-formats/wiki/DMG)
- `DEX`/`.dex.txt` - [cutscenes](https://github.com/simonomi/ff1-binary-formats/wiki/DEX)
- `DMS`/`.dms.json` - [config values](https://github.com/simonomi/ff1-binary-formats/wiki/DMS)
- `MM3`/`.mm3.json` - [3D models](https://github.com/simonomi/ff1-binary-formats/wiki/MM3)
- `MPM`/`.mpm.json` - [images](https://github.com/simonomi/ff1-binary-formats/wiki/MPM)
- `RLS`/`.rls.json` - [fossils](https://github.com/simonomi/ff1-binary-formats/wiki/RLS)

See [this wiki](https://github.com/simonomi/FF1_Binary_Formats/wiki) for specific information on Fossil Fighters' proprietary binary formats.

### How to use
#### Drag-and-drop (Windows only)
Simply drag the file or folder you want to pack/unpack onto the executable.

Then, edit the files within using a text editor (I recommend [Notepad++](https://notepad-plus-plus.org))

#### Commandline
```
OVERVIEW: A Fossil Fighters ROM-hacking tool.

By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file
extensions, magic bytes, and metadata

USAGE: carbonizer [--pack] [--unpack] [--extract-mars <extract-mars>] [<file-paths> ...]

ARGUMENTS:
  <file-paths>            The files to pack/unpack

OPTIONS:
  -p, --pack/-u, --unpack Manually specify compression mode
  -e, --extract-mars <extract-mars>
                          Whether to extract MAR files. Options are always, never, auto (default: auto)
  -h, --help              Show help information.
```

### Usage notes
The easiest way to use carbonizer is to unpack an entire `.nds` file into a folder in the same directory,
then modifying the contents of that directory and repacking it back into an `.nds` file. This usage is encouraged, but keep in mind that it will output an `.nds` file with the same name as the input directory, so consider renaming it after initially unpacking.
