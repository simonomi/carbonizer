## carbonizer
an all-in-one Fossil Fighters ROM-hacking tool

### download
[click here to download the latest release of carbonizer](https://github.com/simonomi/carbonizer/releases)

### how to use
#### drag-and-drop (Windows only)
drag the `.nds` ROM file onto `carbonizer.exe`. a terminal window should appear while carbonizer runs, then close once it finishes. a folder will be created next to the input file that contains the unpacked ROM files.

carbonizer's output files can be edited using a regular text editor (I recommend [Notepad++](https://notepad-plus-plus.org)). To repack the edited files back into a `.nds` ROM, drag the folder onto carbonizer.

#### command-line
```
OVERVIEW: A Fossil Fighters ROM-hacking tool

By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file
extensions, magic bytes, and metadata

USAGE: carbonizer [--pack] [--unpack] [--auto] [--ask] [<file-paths> ...]

ARGUMENTS:
  <file-paths>            The files to pack/unpack

OPTIONS:
  -p, --pack/-u, --unpack/--auto/--ask
                          Manually specify compression mode (default: --auto)
  -h, --help              Show help information.
```

example:
```sh
carbonizer "Fossil Fighters.nds"
```

### configuration
when carbonizer is run for the first time, it'll create a `config.json` file that configures certain aspects of carbonizer's behavior. it has comments explaining each option, but if anything is still confusing, let me know!

### technical details
see [this wiki](https://github.com/simonomi/FF1_Binary_Formats/wiki) for technical information on Fossil Fighters' proprietary binary formats.
