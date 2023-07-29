## carbonizer
A pure swift, easy-to-use Fossil Fighters ROM-hacking tool.

### How it works
Point carbonizer towards a file or folder, and it'll automatically pack or unpack whatever input it receives.
It determines whether to pack or unpack based on the file extensions and binary magic ids it sees, and if it doesn't recognize any, defaults to packing.

### Supported file types
- `.nds` - Nintendo DS ROM file
- `MAR`/`.mar` - archive
- `DTX`/`.dtx` - text
- `DMG`/`.dmg` - dialog

See [this wiki](https://github.com/simonomi/FF1_Binary_Formats/wiki) for specific information on Fossil Fighters' proprietary binary formats.

### How to use
#### Drag-and-drop (Windows only)
Simply drag the file or folder you want to pack/unpack onto the executable.

#### Commandline
`carbonizer <file> [more files]`

### Usage notes
The easiest way to use carbonizer is to unpack an entire `.nds` file into a folder in the same directory,
then modifying the contents of that directory and repacking it back into an `.nds` file.
This usage is encouraged, but there are some caveats:
- Unpacking an entire `.nds` file, decompressing its contents, and saving that to disk **will probably take a while**.
On my (very powerful) machine, it takes at least 20 seconds, so be patient!
- Re-packing is much faster, but keep in mind that it will output an `.nds` file with the same name as the input directory, 
so consider renaming it after initially unpacking.
