<h1 align="center"> En Framework </h1> <br>

<p align="center">
  Libraries and utilities for Second Life scripters.
</p>

## Introduction

**En is under active and ongoing development; many functions have not been fully tested. Do not use this framework in your projects until this message is removed! It is experimental and highly unstable!**

An unofficial framework for the [Linden Scripting Language](https://wiki.secondlife.com/wiki/LSL_Portal) and [SLua](https://create.secondlife.com/script/) in [Second Life](https://secondlife.com/).

*"Second Life®" is a trademark of Linden Research, Inc., d/b/a Linden Lab. Northbridge Business Systems and the En framework are are not affiliated with or sponsored by Linden Research.*

LSL and SLua are the native scripting languages used to control Second Life objects. Certain third-party viewers incorporate an [LSL preprocessor](https://wiki.firestormviewer.org/fs_preprocessor) that provides C-style preprocessor macros via the built-in script editor. The En Framework leverages the `#include` and `#define` macros, along with the built-in script optimizer, to make dozens of helper functions available to LSL scripts. It can also be used with the [official Second Life VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin) to provide similar support in SLua using `require()`.

## Key Features

Some of the useful features En provides:

- enConsole - a standardized logging interface that can be configured for "in-the-field" debugging
- enCLEP - heavily extended `llMessageLinked` and `llListen`-like functions
- enLNX - functions to safely write, read, and manipulate key-value pairs in the `llLinksetData*` store
- enKVS - simple in-memory key-value store (LSL only)
- enTimers - `LLTimers` simulacrum for LSL, allowing string callbacks, multiple concurrent timers, and one-shot timers
- Helper libraries for integers (including hex & bitwise), floats, vectors, rotations, strings, lists, and keys
- Miscellaneous additional libraries for avatars, environments, inventory, object parameters, and time/dates
- Complete utility scripts

## Installation

You'll need to set up an include directory somewhere on your local computer that stores all scripts you want to use in Second Life. For more information on how to do this, see **Include/Require Instructions**.

For the latest **development** release:
- Create a directory called `northbridge-sys` in your include directory if it doesn't exist.
- Inside the `northbridge-sys` directory, clone the repository into your preprocessor include directory using the command `git clone https://github.com/northbridge-sys/en-framework.git`. This will create the `en-framework` directory and clone the latest commit into it.

Or, for the current **stable** release, or if you don't want to use git (you should, especially for your own code!):
- Create a directory called `northbridge-sys` in your include directory if it doesn't exist.
- Create a directory called `en-framework` in the `northbridge-sys` directory.
- [Download](https://github.com/northbridge-sys/en-framework/archive/main.zip) and unpack the repository into the `en-framework` directory, so that `README.md` is located in `[include directory]/northbridge-sys/en-framework/README.md` (or with backslashes - \ - for Windows users). **Make sure you don't name the folder "en-framework-main", or the framework won't load correctly!**

Note that you'll need to repeat this process for each update; there is no auto-updater.

Depending on if you want LSL or SLua support, follow one or both of the following sections:

### LSL Configuration

*If you're only interested in SLua, you can skip this section.*

LSL requires the LSL Preprocessor. If you have not used it before, there are several methods:
- Preprocessing automatically in [Visual Studio Code](https://code.visualstudio.com/) using the [official Second Life VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin) to connect to a running Second Life viewer to upload preprocessed scripts
- Writing directly in any editor you want, and `#include` entire LSL scripts at compile time using a third-party viewer with a built-in LSL Preprocessor, such as [Firestorm Viewer](https://www.firestormviewer.org/)
- Both of the above combined (the official plugin also checks for errors as you type, and VSCode is better than the built-in editor)

If you install the official VSCode plugin, make sure to install the additional recommended plugins.

For the viewer and/or VSCode to know where the En Framework (and your other scripts) are loaded, you will need to set the preprocessor include path in both your viewer and the VSCode plugin's configurations; see their respective instructions.

Make sure to enable the "script optimizer" option in your preprocessor(s); En libraries are all loaded together and will crash your compiler if it is not enabled.

**Note that there is currently a bug in the VSCode preprocessor that causes it to break on certain libraries; this causes spurious error underlining, but the script can still compile and run.**

### SLua Configuration

*If you're only interested in LSL, you can skip this section.*

SLua currently requires [Visual Studio Code](https://code.visualstudio.com/) and the [official Second Life VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin). Make sure to install the additional recommended plugins. No viewers have built-in support for SLua `require()` processing as of this version.

The general process for setting up script association in VSCode is as follows:

1. If you expect to use `@file` (recommended), open the settings for the extension and enable the following (and any other options you want):
    1. *Include File Meta In Output*
    1. *Use File Meta For Matching*
1. Create a project folder (see **Include/Require Instructions** below).
1. In VSCode, create a new workspace by opening that folder in a new window. You can open the folder in an existing workspace, but in-world scripts will only associate to master scripts in the first folder you open in the workspace (you can require ModuleScripts from other folders).
1. Add any additional folders (typically libraries containing one or more ModuleScripts) into the workspace.
1. In the original folder, create a file ending in “.luau”. It can be in a subdirectory, like “subdirectory/example.luau”. This will be the master script, where you do all editing.
1. In SL, create a script in an object. There are two ways to associate this script to a master script in VSCode, use only one:
    1. The safest method is to add the line (adapt to your needs): `--@file New Script.luau`  to the top of the script before editing it. This must point to the master file in relation to the original folder and can include subdirectories of your project directory. Don’t include the name of the original folder.
    1. If there is no `--@file` directive, you must name the script the same name as a file in the original folder (with or without “.luau”), like “New Script” or “New Script.luau”.
        1. Don’t include any folder names; this will search through the entire original folder and all subdirectories for a name match. If there are multiple matches, the first is used (this appears alphabetical, but this use case should be avoided in general, so it wasn’t tested).
        1. Note that the script name as shown in the built-in editor is sent to VSCode for association when you click [Edit…]. In the vanilla viewer, the script name does not update in the built-in editor if it is open while you rename the script in the object’s inventory - it must be closed and reopened.
        1. Be careful - if you have *Include File Meta In Output* enabled, a `--@file` directive is added to the finished file and will be used whenever re-editing this script from the viewer, overriding the script name. You’ll need to change the `--@file` directive instead of renaming the script if you change the name of the master script on your PC.
1. Open the script (if it is not yet open) and click [Edit…] in the lower right. This will open VSCode and attempt to associate the script with a master script in the original folder of the active workspace using one of the above methods. If an association is made, VSCode will also open the master script in another tab, leaving the preprocessed source tab in the background.
1. Perform all edits in the master script. When you save it, VSCode will preprocess it, send it back to your Second Life viewer, and Second Life will save it and start running it.
    1. This preprocessing is only performed if the temporary script is open in VSCode, so keep both tabs open until you’re finished.
1. When finished, close both tabs. To reopen the script in VSCode, just open it and click [Edit…] again.

SLua does not currently support tree-shaking; all code you write or require counts against memory, and duplicate requires cost memory. Therefore, SLua modules must be required manually.

## Include/Require Instructions

Unless you have a reason not to, you should store all of your LSL and SLua files somewhere within a unified "include directory" for Second Life scripts on your PC; typically in your Documents or home directory. Your include directory should be set wherever you need an LSL preprocessor include path. (To make it easier to load third-party libraries, we recommend doing this even for SLua, which does not currently support a predefined include path.)

Ideally, your include directory should look like this:

```
. (include directory)
├── my-organization
│   └── my-project
│       ├── .luaurc
│       └── New Script.luau
└── northbridge-sys
    └── en-framework
        ├── lsl
        │   ├── event-handlers
        │   │   └── ...
        │   ├── libraries
        │   │   └── ...
        │   ├── utilities
        │   │   └── ...
        │   ├── \_functions.lsl
        │   ├── \_macros.lsl
        │   ├── event-handlers.lsl
        │   └── libraries.lsl
        ├── slua
        │   ├── modules
        │   │   └── ...
        │   └── tests
        │       └── ...
        ├── LICENSE
        └── README.md
```

### #include (LSL)

En LSL scripts must be written in the following order, top to bottom:

First, `#define` any needed `EVENT_`, `FEATURE_`, `OVERRIDE_`, and `TRACE_` flags:

```
// for example:
#define EVENT_EN_STATE_ENTRY
#define OVERRIDE_ENLOG_DEFAULT_LOGLEVEL 6
```

Then, include all LSL libraries (unused code gets removed by the "script optimizer" option):

```
#include "northbridge-sys/en-framework/lsl/libraries.lsl"
```

Then, write En event passthrough handlers and any other script code:

```
touched_by(key avatar)
{
    enLog_SuccessTo(avatar, "Touched.")
}

en_state_entry()
{
    enLog_Info("Hello, Avatar!")
}

en_touch_start(integer num)
{
    touched_by(llDetectedKey(num))
}
```

Then, include the event handlers as the entire `default` state:

```
default
{
    #include "northbridge-sys/en-framework/lsl/event-handlers.lsl"
}
```

Compile and run. If your preprocessor include path is set correctly, it should run!

### require() (SLua)

If you followed the recommended include directory layout, copy the `.luaurc` file from the `en-framework/slua` directory into the root of your project; it should create a link back through your include directory. If not, you may need to correct the path in `.luaurc` depending on your file layout.

Libraries (modules or ModuleScripts) can then be loaded individually using `require()` at the top of any script in that project:

```
local enConsole = require("@en-framework/enConsole")
```

We recommend requiring each module into its own table so that its function names match the documentation.

Note that you should not `require()` more than the modules you need for your script; SLua does no optimization of unused code.

## Reference Guide

The complete reference guide for En is located on the [NBS Documentation portal](https://docs.northbridgesys.com/en-framework).

## Frequently Asked Questions

### Why?

LSL kind of sucks. A lot of code snippets end up copied and pasted across multiple projects, each with its own tweaks and bugs. Most LSL code is ugly, incomprehensible, and unmaintainable.

Many Second Life viewers provide the ability to use an external LSL editor, and some also include the LSL preprocessor, a tool that allows developers to use a limited set of C preprocessor directives to manipulate LSL source code. Additionally, En began development a few years before the release of SLua, which incidentally provides a lot of similar functionality.

We (well, I) developed the En Framework to accomplish three things:
- I develop a lot of different projects at the same time that share the same code or need to take advantage of the same tricks (or avoid the same pitfalls). Saving all of these tricks into a shared library makes it possible to push fixes and other improvements automatically when compiling any script. Eventually, since LSL does not support runtime event subscription, this necessitated a framework to automatically build event handlers to catch certain events when hooked by preprocessor definitions or other library functions.
- The built-in functions for inter-script data storage and transfer essentially only store and send raw strings; any protocols necessary to send anything more must be implemented manually. Defining standard methods for communicating with scripts and storing data ensures long-term cross-product compatibility, and doing it with a framework allows scripts to be high-level, cleaner, and easier to maintain. We strive to make it easy to mod our products, so offering the underlying framework helps interested scripters be familiar with many products by learning only a few library functions.
- En LSL scripts are naturally compatible with En SLua scripts; for example, regardless of which language you use, enLNX implements the same open [LNX](https://gsi.sh/rec/lnx) datastore namespace standard, and enCLEP/enSNEP implement the same open [CLEP](https://gsi.sh/rec/clep) protocol and [SNEP](https://gsi.sh/rec/snep) signatures. This is important because LSO2-compiled LSL scripts, while slow, cross between regions very quickly, so still have some utility.

The overarching strategy of En is to let scripters focus on the code, not the infrastructure.

### How does it work?

For LSL, the LSL Preprocessor makes all of the helper functions defined in the En libraries available within LSL scripts. Since the LSL Preprocessor can automatically remove functions that aren't referenced in the final script, these functions are only compiled into the script if they are called; otherwise, they don't take any script memory. Additionally, the En framework creates and redirects event handlers (`state_entry`, `link_message`, etc.) dynamically based on the functionality you enable to optimize script performance. If you need to handle certain events yourself, En can do so by passing them through to user-defined functions. If an event handler isn't needed for an En feature and you don't specifically request it, it won't be added to the compiled script.

For SLua, the En framework is only a set of modules; SLua's LLEvents library allows modules to independently hook into events, so no preprocessor is required except to resolve `require()`s.

Certain En features require that you define certain flags or variables before they work to minimize unnecessary memory usage and script time; see [the documentation](https://docs.northbridgesys.com/en-framework) for more information.

### Why "En"?

"En" is a reference to the Sumerian cuneiform of the same name, particularly the term's thematic presence throughout *Snow Crash*, the novel that directly inspired the creation of Second Life.

>" . . . Primitive societies were controlled by verbal rules called *me*. The *me* were like little programs for humans. They were a necessary part of the transition from caveman society to an organized, agricultural society. For example, there was a program for plowing a furrow in the ground and planting grain. There was a program for baking bread and another one for making a house. There were also *me* for higher-level functions such as war, diplomacy, and religious ritual. All the skills required to operate a self-sustaining culture were contained in these *me*, which were written down on tablets or passed around in an oral tradition. In any case, the repository for the *me* was the local temple, which was a database of *me*, controlled by a priest/king called an *en*. When someone needed bread, they would go to the *en* or one of his underlings and download the bread-making *me* from the temple. Then they would carry out the instructions -- run the program -- and when they were finished, they'd have a loaf of bread.
>
>"A central database was necessary, among other reasons, because some of the *me* had to be properly timed. If people carried out the plowing-and-planting *me* at the wrong time of year, the harvest would fail and everyone would starve. The only way to make sure that the *me* were properly timed was to build astronomical observatories to watch the skies for the changes of season. So the Sumerians built towers 'with their tops with the heavens' -- topped with astronomical diagrams. The *en* would watch the skies and dispense the agricultural *me* at the proper times of year to keep the economy running."

- Neal Stephenson, *Snow Crash* (1992).

The En framework provides a "central database" of "little programs" for all sorts of "functions" in the "society" of scripting, of which many need to be "properly timed" to run on certain events... so the name just made sense.

### Why use En/LSL compared to raw LSL?

En is intended for complex projects, especially "networked" scripts - that is, one or more objects with multiple scripts that need a standardized and efficient way to communicate with each other. The performance impact of multiple scripts in an object is trivial, but LSL is not designed to handle these sorts of scenarios well at runtime.

For example, if an object has multiple scripts in a prim and you need to use `llMessageLinked` to send a message to one of them, there is simply no way to do that without triggering `link_message` in every single script in the prim. enCLEP, therefore, includes a filter to optionally target a specific script, so if/when a different script receives that message, the enCLEP handler in the other script will drop the event as quickly as possible to reduce script time instead of wasting time processing the message further.

While we use En for most of our projects, there are still some limited circumstances where raw LSL is good enough or provides a slight edge in performance. Generally, En is designed for scaling at the expense of script memory and some limited performance in certain scenarios in simple scripts. It is primarily efficient in a code-factoring sense - that is, by using En functions, En scripts do not unnecessarily duplicate code that could be consolidated into a single function.

### Why use En/LSL compared to SLua in general?

Several reasons:
- LSO2-compiled scripts cross region borders quicker than any other scripts; this is useful for, e.g., vehicles with small scripts that cannot be consolidated due to technical limitations.
- LSL scripts often do not justify being rewritten entirely in Lua. We have over 20 years of products and services built in LSL in varying states of completion and support; many En concepts are formalizations of unwritten standards and practices that can be easily "transposed" into En to improve maintainability of existing scripts without needing to completely rewrite them in Luau.
- En development began before Luau implementation was announced. For most of En's development, "SLua" had no preprocessing or `require()`s, making it impossible to implement En in anything other than LSL. With the release of the official [SL VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin), these features now exist for SLua.
- Luau support is currently in open beta and is limited to specific Luau-enabled regions. When Luau is released to production regions and is editable in a Linux viewer, we will port En to it, because key Luau features happen to be the core purpose of the En framework anyway (data structures, dynamic event subscription, multiple event handlers, coroutines, multiple timers), so a lot of the extant En superstructure can be simplified in Luau.

### Don't the additional function definitions increase script memory?

En dynamically generates event handlers depending on the flags you define in the script. For example, defining `FEATURE_ENCLEP_USE_CHAT` creates a `listen` event handler, passing CLEP requests to `enCLEP_messages()` and any other messages to `en_listen()` if `EVENT_EN_LISTEN` is defined.

Since LSL does not support dynamic event subscription or multiple event handlers, the only way to accomplish this is to have En generate event handlers itself and pass events to En-defined and user-defined functions depending on which features are enabled.

Passing events to user-defined functions only adds a trivial amount of memory usage. (Functions have not implicitly allocated 512 bytes in Mono since at least 2013.)

### If I don't need any of the En functions, why use En at all?

En also provides a limited set of basic functionality that is always enabled unless specifically disabled via flags. For example, if the `"stop"` linkset data pair contains a truthy value, En will automatically stop the script on `state_entry`. This can be used for, e.g., updater and script distribution tools that have scripts inside them that must never run until added to another object.

## License

The En Framework is licensed under the GNU Lesser General Public License v3.0. In short, you (yes, you!) may use the En Framework in any scripts - whether commercial or non-commercial - but you may not redistribute the En Framework itself, in whole or in part, as a derivative work under any other license. Northbridge Business Systems and contributors to the En Framework cannot be held liable for legal issues or damages due to its use.
