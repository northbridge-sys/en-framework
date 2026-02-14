<h1 align="center"> En Framework </h1> <br>

<p align="center">
  Libraries and utilities for Second Life scripters.
</p>

## Introduction

**En is under active and ongoing development; many functions have not been fully tested. Do not use this framework in your projects until this message is removed! It is experimental and highly unstable!**

An unofficial framework for the [Linden Scripting Language](https://wiki.secondlife.com/wiki/LSL_Portal) and [SLua](https://create.secondlife.com/script/) in [Second Life](https://secondlife.com/).

*"Second Life®" is a trademark of Linden Research, Inc., d/b/a Linden Lab. Northbridge Business Systems and the En framework are are not affiliated with or sponsored by Linden Research.*

LSL and SLua are the native scripting languages used to control Second Life objects. Certain third-party viewers incorporate an [LSL preprocessor](https://wiki.firestormviewer.org/fs_preprocessor) that provides C-style preprocessor macros via the built-in script editor. The En Framework leverages the `#include` and `#define` macros, along with the built-in script optimizer, to make dozens of helper functions available to LSL scripts. It can also be used with the [official Second Life VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin) to provide similar support in SLua using `require()`.

**SLua support is currently incomplete and untested until SLua is available on a Linux-compatible viewer.**

## Key Features

Some of the useful features En provides:

- enLog - a standardized logging interface that can be configured for "in-the-field" debugging
- enRPC - heavily extended `llMessageLinked` and `llListen`-like functions
- enLNX - functions to safely write, read, and manipulate key-value pairs in the `llLinksetData*` store
- enKVS - simple in-memory key-value store, particularly useful for backing up critical linkset data
- enTimer - `llSetTimerEvent` with string callbacks, multiple concurrent timers, and one-shot timers
- Helper libraries for integers (including hex & bitwise), floats, vectors, rotations, strings, lists, and keys
- Miscellaneous additional libraries for avatars, environments, inventory, object parameters, and time/dates
- Complete utility scripts

## Installation

If you haven't, enable the LSL preprocessor in your viewer and set the directory where the LSL preprocessor will check for include files. This can be any directory, as long as the Second Life viewer can read from it, though we recommend placing it somewhere you won't accidentally delete it, such as a folder in your user directory.

For the latest **development** release:
- Create a directory called `northbridge-sys` in your LSL preprocessor include directory, if you haven't already.
- Inside the `northbridge-sys` directory, clone the repository into your preprocessor include directory using the command `git clone https://github.com/northbridge-sys/en-framework.git`. This will create the `en-framework` directory and clone the latest commit into it.

Or, for the current **stable** release, or if you don't want to use git:
- Create a directory called `northbridge-sys` in your LSL preprocessor include directory, if you haven't already.
- Create a directory called `en-framework` in the `northbridge-sys` directory.
- [Download](https://github.com/northbridge-sys/en-framework/archive/main.zip) and unpack the repository into the `en-framework` directory, so that `README.md` is located in `[preprocessor directory]/northbridge-sys/en-framework/README.md` (or with backslashes - \ - for Windows users). **Make sure you don't name the folder "en-framework-main", or the framework won't load correctly!**

Note that you'll need to repeat this process for each update; there is no auto-updater.

## Usage

**The complete reference guide for En is located on the [NBS Documentation portal](https://docs.northbridgesys.com/en-framework).**

### Overview

Include the framework libraries by placing the following line at the top of your script:

```
#include "northbridge-sys/en-framework/lsl/libraries.lsl"
```

Then, in the script body, include the framework event handlers in each state

```
default
{
    #include "northbridge-sys/en-framework/lsl/event-handlers.lsl"
}
```

To run your own code on an event, most events can be forwarded to user-defined functions upon request:

```
#define EVENT_EN_STATE_ENTRY
#define EVENT_EN_ON_REZ

#include "northbridge-sys/en-framework/lsl/libraries.lsl"

en_state_entry()
{
    // runs on state_entry if EVENT_EN_STATE_ENTRY has been defined
}

en_on_rez( integer param )
{
    // runs on on_rez if EVENT_EN_ON_REZ has been defined
}

// ...
```

You can also #define additional options for library features and override default constants; see the documentation for details.

No matter what, if you need to define any preprocessor values, make sure you do so *above* `#include "northbridge-sys/en-framework/lsl/libraries.lsl"`.

## Frequently Asked Questions

### Why?

LSL is over twenty years old and still has no function that returns a random integer. While it's still fun, coding in any other language makes LSL feel barbaric.

While LSL does enjoy occasional improvements, a lot of code snippets end up copied and pasted across multiple projects, each with its own tweaks and bugs. Most LSL code is, as a result, ugly, incomprehensible, and unmaintainable.

Many Second Life viewers provide the ability to use an external LSL editor, and some also include the LSL preprocessor, a tool that allows developers to use a limited set of C preprocessor directives to manipulate LSL source code.

We develop a lot of different projects at the same time that share the same code or need to take advantage of the same tricks (or avoid the same pitfalls), so the preprocessor lets us call functions out of shared LSL libraries. If we need to add or change something in a library, all it takes is recompiling all the scripts that use that library instead of manually copying and pasting the code to each script. This simplifies development across multiple product lines and facilitates rapid prototyping and development of complex LSL scripts.

The overarching strategy of En is to focus on the code, not the infrastructure. Thanks to the LSL preprocessor, these additional functions and background routines just work.

### How does it work?

The LSL preprocessor makes all of the helper functions defined in the En libraries available within LSL scripts. Since the LSL preprocessor can automatically remove functions that aren't referenced in the final script, these functions are only compiled into the script if they are called; otherwise, they don't take any script memory.

Additionally, the En framework creates and redirects event handlers (`state_entry`, `link_message`, etc.) dynamically based on the functionality you enable to optimize script performance. If you need to handle certain events yourself, En can do so by passing them through to user-defined functions. If an event handler isn't needed for an En feature and you don't specifically request it, it won't be added to the compiled script.

Certain En features require that you define certain flags or variables before they work to minimize unnecessary memory usage and script time; see [the documentation](https://docs.northbridgesys.com/en-framework) for more information.

### Why "En"?

"En" is a reference to the Sumerian cuneiform of the same name, particularly the term's thematic presence throughout *Snow Crash*, the novel that directly inspired the creation of Second Life.

>" . . . Primitive societies were controlled by verbal rules called *me*. The *me* were like little programs for humans. They were a necessary part of the transition from caveman society to an organized, agricultural society. For example, there was a program for plowing a furrow in the ground and planting grain. There was a program for baking bread and another one for making a house. There were also *me* for higher-level functions such as war, diplomacy, and religious ritual. All the skills required to operate a self-sustaining culture were contained in these *me*, which were written down on tablets or passed around in an oral tradition. In any case, the repository for the *me* was the local temple, which was a database of *me*, controlled by a priest/king called an *en*. When someone needed bread, they would go to the *en* or one of his underlings and download the bread-making *me* from the temple. Then they would carry out the instructions -- run the program -- and when they were finished, they'd have a loaf of bread.
>
>"A central database was necessary, among other reasons, because some of the *me* had to be properly timed. If people carried out the plowing-and-planting *me* at the wrong time of year, the harvest would fail and everyone would starve. The only way to make sure that the *me* were properly timed was to build astronomical observatories to watch the skies for the changes of season. So the Sumerians built towers 'with their tops with the heavens' -- topped with astronomical diagrams. The *en* would watch the skies and dispense the agricultural *me* at the proper times of year to keep the economy running."

- Neal Stephenson, *Snow Crash* (1992).

The En framework provides a "central database" of "little programs" for all sorts of "functions" in the "society" of LSL, of which many need to be "properly timed" to run on certain events... so the name just made sense.

### Why use En compared to raw LSL?

En is intended for complex projects, especially "networked" scripts - that is, one or more objects with multiple scripts that need a standardized and efficient way to communicate with each other. The performance impact of multiple scripts in an object is trivial, but LSL is not designed to handle these sorts of scenarios well at runtime.

For example, if an object has multiple scripts in a prim and you need to use `llMessageLinked` to send a message to one of them, there is simply no way to do that without triggering `link_message` in every single script in the prim. enLEP, therefore, includes a filter to optionally target a specific script, so if/when a different script receives that message, the enLEP handler in the other script will drop the event as quickly as possible to reduce script time instead of wasting time processing the message further.

While we use En for most of our projects, there are still some limited circumstances where raw LSL is good enough or provides a slight edge in performance. Generally, En is designed for scaling at the expense of script memory and some limited performance in certain scenarios in simple scripts. It is primarily efficient in a code-factoring sense - that is, by using En functions, En scripts do not unnecessarily duplicate code that could be consolidated into a single function.

### Why use En/LSL compared to Lua/Luau/"SLuau"?

Several reasons:
- LSL scripts often do not justify being rewritten entirely in Lua. We have over 20 years of products and services built in LSL in varying states of completion and support; many En concepts are formalizations of unwritten standards and practices that can be easily "transposed" into En to improve maintainability of existing scripts without needing to completely rewrite them in Luau.
- En development began before Luau implementation was announced. For most of En's development, "SLua" had no preprocessing or `require`s, making it impossible to implement En in anything other than LSL. With the release of the official [SL VSCode Plugin](https://github.com/secondlife/sl-vscode-plugin), these features now exist for SLua.
- Luau support is currently in open beta and is limited to specific Luau-enabled regions. When Luau is released to production regions and is editable in a Linux viewer, we will port En to it, because key Luau features happen to be the core purpose of the En framework anyway (data structures, dynamic event subscription, multiple event handlers, coroutines, multiple timers), so a lot of the extant En superstructure can be simplified in Luau.

### Don't the additional function definitions increase script memory?

En dynamically generates event handlers depending on the flags you define in the script. For example, defining `EVENT_ENCLEP_RPC_REQUEST` creates a `listen` event handler, passing CLEP requests to `enclep_rpc_request()` and any other messages to `en_listen()`.

Since LSL does not support dynamic event subscription or multiple event handlers, the only way to accomplish this is to have En generate event handlers itself and pass events to En-defined and user-defined functions depending on which features are enabled.

Passing events to user-defined functions only adds a trivial amount of memory usage. (Functions have not implicitly allocated 512 bytes in Mono since at least 2013.)

### If I don't need any of the En functions, why use En at all?

You don't have to! But En also provides a limited set of basic functionality that is always enabled unless specifically disabled via flags. For example, if the `"stop"` linkset data pair contains a truthy value, En will automatically stop the script on `state_entry`. This can be used for, e.g., updater and script distribution tools that have scripts inside them that must never run until added to another object.

## License

The En Framework is licensed under the GNU Lesser General Public License v3.0. In short, you (yes, you!) may use the En Framework in any LSL scripts - whether commercial or non-commercial - but you may not redistribute the En Framework itself, in whole or in part, as a derivative work under any other license. Northbridge Business Systems and contributors to the En Framework cannot be held liable for legal issues or damages due to its use.
