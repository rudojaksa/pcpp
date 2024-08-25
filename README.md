# Simple Perl (Python/C/C++) preprocessor

This simple preprocessor handles in-comments include directives.  Such include
statements that are contained inside comments provide an additional level of
code organization, above Perl's `require` and `use`, Python's `import`, or
C/C++ `#include` native mechanisms.  However, both these mechanisms (native and
pcpp) can coexist together.  Or, the pcpp can be used instead of the native
mechanism.

In the following Perl and C examples the "abc" code will be copy-pasted into
the source code by the pcpp, while the "xyz" code will be handled by native
include mechanisms:

``` perl
# Perl usage
# include "abc.pl"
require "xyz.pl";
```

``` python
# Python usage
# include "abc.py"
import xyz
```

``` c
// C/C++ usage
// include "abc.h"
# include "xyz.h";
```

The `pcpp` is a simple tool, although this description seems long, it only
handles:

 * include directives,
 * removal of triple-comments,
 * nothing else.

### Why to "compile" Perl or Python?

To "use" the pcpp pre-processed code it is necessary to run the pcpp first,
like:

``` sh
pcpp abc.in.pl > abc.pl
perl abc.pl
```

This looks as if we first "compile" the bunch of Perl source files into the
"executable" Perl file and only then run it.  Similarly, a C code has to be
compiled before it can be executed.  It is a disadvantage as it requires the
extra step `pcpp abc.in.pl`.  But the following step `perl abc.pl` becomes
simpler:

 * now the abc\.pl doesn't require the dependent .pl files to be installed,
 * the abc\.pl stays an interpreted language code that can be fixed if needed
   (comments stay in as well).

The same holds for Python.  Pcpp-ing is some kind of simple code amalgamation
or a "static linker" for Perl/Python.  In C/C++ the pcpp is useful if you want
to hide something from the cpp preprocessor.

Another reason to use pcpp instead of native require/use/import is that the
pcpp processing logic is simpler.  One more reason is that such include process
cannot be skewed at the use-time and run-time.

### In-comment directives

Hiding the pcpp directives in comments allows to avoid conflicts with the main
language interpreter/compiler/preprocessor, with IDEs or editing modes.
Further, this increases the number of comments ;-)

Multiple filenames in the single include directive line are allowed, quoting is
optional, whitespace between the hash and the "include" word is optional:

```
#include abc.pl xyz.pl "efg.pl"
```

The additional text after the filename(s) is a comment and is ignored,
filenames have to be identified by the .pl (or .py/.h) suffix or have to be
quoted for the parser to find the beginning of the comment:

```
# include abc.pl xyz.pl comment text which is ignored
# include abc.py xyz.py # visualy more noticeable comment
// include abc.h comment in C/C++
```

Multiple hashes (slashes) are not accepted, the following code are just
comments without any effect:

```
## include abc.pl
### include abc.pl
#### include abc.pl
/// include abc.h
//// include abc.h
```

Included content in the pcpp output is "watermarked" by the `# included` and
`# end` comments/directives (in C/C++ `// included` and `// end`):

``` perl
# included "abc.pl"
...
# end "abc.pl"
```

Indentation of the include statement is propagated into output.  For instance a
two-space indentation of the hash of the include statement in perl code:

``` perl
some(code);
  # include abc.pl
```

will lead to adding two spaces to the original indentation in the included
file:

``` perl
some(code);
  # included abc.pl
  originally_unindented_abc_pl(code);
  following_line();
  ...
```

The language is autodetected according to the suffix of the input file: `.pl`,
`.py`, `.c`, or `.c++`.

### Paths resolving

Include paths can be specified as a filename only `# include abc.pl` or
specifying also a part of the path `# include xy/abc.pl` or `# include
yz/abc.pl` to distinguish between equal filenames in different directories.

The path resolving algorithm distinguishes between files included from the
top-level source or from a file which is included.  Path resolving algorithm
considers paths relative to the current working directory (CWD) or to the
directory of the currently parsed file.  The algorithm is:

1. try direct path for the top-level file includes (CWD relative),
2. try path relative to currently active included file (to allow incorporation of whole code trees with relative includes working),
3. try CWD-relative paths even for not-top-level files (to allow programmer to think about files as relative from CWD),
4. try to find files recursively in any subdirectory of the CWD in the depth order (to allow to skip dirnames for unique filenames),
5. strip the directory part from the included file name, and try to find it just by the filename (just a plan-B for wrong dirnames when moving files).

In the case of conflict, i.e. `# include "abc.pl"` where two `abc.pl` files are
available, the first one is chosen: `./abc.pl` is the direct path so it has a
higher priority than the `xy/abc.pl`.

Double includes are automatically avoided by the `pcpp`.  Any included file is
copy-pasted to the output only once, on the place of the first appearance of
its include statement.

Missing include files are silently ignored (by default), or reported in the
verbose mode (-v switch).

### Triple comments

Pcpp preserves comments to allow the Perl or Python output code to be readable
as best as possible to allow the output to be hacked/fixed.

However, to allow the programmer to request the removal of comments from the
output, we introduce the "triple comments":

```
### this line will be removed from the Perl/Python code by pcpp
/// this line will be removed from the C/C++ code by pcpp
#### but this will be kept
## this will be kept too
```

Triple comments are removed together with preceding empty lines by pcpp.

### Debugger problem

Unfortunately, Perl or Python don't know how to translate line numbers from
pcpp processed code back to the original code.  So debugging requires checking
the pcpp processed code, not the code you wrote.

### Uninclude

Watermarked pcpp output allows the removal of included parts and return to the
original source code using the `uninclude` tool.  This can be useful when
building "libraries" which can recursively pack all dependencies, which can be
stripped off when not needed (when already provided by another "library").

Uninclude of multi-level included files is flattened to a single level, for
instance the following included content:

```
# included abc.pl
  xyz
  # included def.pl
    uid
  # end def.pl
  hjk
# end abc.pl
```

will be flattened by uninclude to:

```
# include abc.pl
# include def.pl
```

which when included back will become:

```
# included abc.pl
  xyz
  hjk
# end abc.pl
# included def.pl
  uid
# end def.pl
```

### Pcpp in Makefile

Example to make `xyz` from its source `xyz.pl` and two included files:

``` makefile
xyz: xyz.pl inc1.pl inc2.pl
	echo '#!/usr/bin/perl' > $@
	pcpp $< >> $@
	@chmod 755 $@
	@sync # to ensure the result is saved before being used in the next rule
```

 1. generate #! interpreter identifier
 2. build `xyz` from `xyz.pl`
 3. make it executable
 4. sync the result before it is used by another makefile rule (otherwise it can be incomplete)

More complex example:

``` makefile
OUTPUT := xyz
DEPENDENCIES := $(shell pcpp -lp $(OUTPUT:%=%.pl))
SIGN := "$(PKGNAME) $(AUTHOR)"
DATE := $(shell date '+%Y-%m-%d')

$(OUTPUT): %: %.pl $(DEPENDENCIES) Makefile
	echo -e '#!/usr/bin/perl' > $@
	echo -e "# $@ generated from $(PKGNAME)/$< $(DATE)\n" >> $@
	echo -e '$$SIGN = $(SIGN);\n' >> $@
	pcpp $< >> $@
	@chmod 755 $@
	@sync
```

 * `DEPENDENCIES` are a list of files to be included obtained by `pcpp -lp`
 * `SIGN` is a variable made available from Makefile into the script

### Dependency files

The `pcpp -d target_name` can be used to generate a dependency file for
Makefile.  Compared to the `-lp` option, the `-d` and `-dd` options also add
the input file into the list and nonexistent files too.  Nonexistent include
files are files that will be generated by the Makefile.  A full path is
required for them to work properly (relative path is ok if it is complete).
Example Makefile:

``` makefile
# require rebuild of the dependencies file .abc.d when processing abc.pl
%: %.pl .%.d
	echo -e '#!/usr/bin/perl' > $@
	pcpp -v $< >> $@

# save dependencies into .abc.d for the abc.pl source of the abc target
.%.d: %.pl
	pcpp -d $(<:%.pl=%) $< > $@

# include generated dependencies but don't fail if they are missing
-include .abc.d
```

Next table lists `pcpp` reporting options, and which files they report.  Direct
files are these loaded according to the command-line request, not by the
include directive.  Missing files are those not found, by requested by the
include directive.

```
          | where  | direct | found | missing | redundant
----------------------------------------------------------
  -v/vv/l | stderr |  yes   |  yes  |  yes X    |   yes
-ln/l1/lp | stdout |   no   |  yes  |  no   X  |   no
   -d/-dd | stdout |  yes   |  yes  |  yes X   |   no X
```

### See also

&nbsp;&nbsp; [pcpp -h](pcpp.md)  
&nbsp;&nbsp; [uninclude -h](uninclude.md)  

### Installation

Files `pcpp` and `uninclude` are standalone Perl scripts, which can be copied
to any `/bin` directory for a system-wide installation.

### Example

The pcpp itself is processed by the pcpp, so its source code is an example of
how to use the pcpp.

<br><div align=right><i>R.Jaksa 2008,2024</i></div>
