# Simple Perl (Python/C/C++) preprocessor

This simple preprocessor handles in-comments include directive.  Such include
statements that are contained inside comments provide additional level of code
organization, above the Perl's `require` and `use`, or Python's `import`, or
C/C++ `#include` native mechanisms.  However, these both mechanisms (native and
pcpp) can coexist together.  Or, the pcpp can be used instead of the native
mechanism.

In following Perl and C examples the "abc" code will be copy-pasted into source
code by the pcpp, while the "xyz" code will be handled be native include
mechanisms:

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

```
pcpp abc.in.pl > abc.pl
perl abc.pl
```

This looks as if we first "compile" the bunch of Perl source files into the
"executable" Perl file and only then run it.  Similarly to a c code, which has
to be compiled before it can be executed.  It is a disadvantage as it requires
the extra step `pcpp abc.in.pl`.  But the following step `perl abc.pl` becomes
actually simpler:

 * now the abc\.pl doesn't require the dependent .pl files to be installed,
 * the abc\.pl stays a interpreted language code which can be fixed if needed
   (comments stay in as well).

The same holds for Python.  Pcpp-ing is some kind of simple code amalgamation,
or a "static linker" for Perl/Python.  In C/C++ the pcpp is useful if you want
to hide something from the cpp preprocessor.

Other reason to use pcpp instead of native require/use/import is that the pcpp
processing logic is simpler.  And one more reason is that such include process
cannot be skewed at the use-time, run-time.

### In-comment directives

Hidding the pcpp directives in comments allows to avoid conflicts with the main
language interpreter/compiler/preprocessor, with IDEs or editing modes.
Further, this increases the number of comments ;-)

Multiple filenames in the single include directive line are allowed, quoting is
optional, whitespace between the hash and the "include" word is optional:

```
#include abc.pl xyz.pl "efg.pl"
```

The additional text after the filename(s) is a comment and is ignored,
filenames have to be identified by the .pl (or .py/.h) suffix or have to be
quoted for the parser to find the begin of comment:

```
# include abc.pl xyz.pl comment text which is ignored
# include abc.py xyz.py # visualy more noticeable comment
// include abc.h comment in C/C++
```

Multiple hashes (slashes) are not accepted, thus following code are just
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

```
# included "abc.pl"
...
# end "abc.pl"
```

Indentation of the include statement is propagated into output.  For instance
a two-spaces indentation of the hash of include statement in perl code:

```
some(code);
  # include abc.pl
```

will lead to added two spaces to the original indentation in included file:

```
some(code);
  # included abc.pl
  originally_unindented_abc_pl(code);
  following_line();
  ...
```

The language is autodetected according to the suffix of the input file: `.pl`,
`.py`, `.c` or `.c++`.

### Paths resolving

Include paths can be spcified as a filename only `# include abc.pl` or
specifying also a part of the path `# include xy/abc.pl` or `# include
yz/abc.pl` to distinguish between equal filenames in different directories.
The resolving algorithm is:

1. trying direct path from current working directory,
2. trying path from directory of file from which the include is called,
3. try to find file recursively in any subdirectory of current working directory (in the depth order),
4. strip the directory part from include file name, and try to find it just by the filename.

In the case of conflict, i.e. `# include "abc.pl"` where two `abc.pl` are
available, the first one is chosen: `./abc.pl` is direct path so has higher
priority than the `xy/abc.pl`.

Double includes are avoided, so the file from given path is copy-pasted to the
output only once, on the place of the firste appearance of the include
statement.

Missing include files are by default silently ignored, or reported in the
verbose mode (-v switch).

### Triple comments

Pcpp preserves comments to allow the Perl or Python output code to be readable
as best as possible in order to allow the output to be hacked/fixed.

However, to allow programmer to request the removal of comments from the
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

Watermarked pcpp output allows to remove included parts and return to the
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

will be flattend by uninclude to:

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

### Use in Makefile

Follows a Makefile rule example to create the perl executable `xyz` from its source
`xyz.pl` and two included files.  First the #! interpreter identifier is generated,
then any initialization content added and then pcpp is called:

``` makefile
xyz: xyz.pl inc1.pl inc2.pl
	echo '#!/usr/bin/perl' > $@
	pcpp $< >> $@
	@chmod 755 $@
	@sync
```

The `sync` is needed only if the xyz will be used in another rule in Makefile.
This will ensure that the pcpp output is realy saved before the use, otherwise
it might fail randomly.  Or with the header comment and `$SIGN` variable to be
used inside the script:

``` makefile
SIGN := "$(PKGNAME) $(AUTHOR)"
DATE := $(shell date '+%Y-%m-%d')

xyz: %: %.pl $(DEPENDENCIES) Makefile
	echo -e '#!/usr/bin/perl' > $@
	echo -e "# $@ generated from $(PKGNAME)/$< $(DATE)\n" >> $@
	echo -e '$$SIGN = $(SIGN);\n' >> $@
	pcpp $< >> $@
	@chmod 755 $@
	@sync # to ensure the result is saved before used in the next rule
```

To obtain dependencies of pcpp-ed file, the `pcpp -lp` can be used, like in
this example for the xyz perl script: (dependencies are a list of files to be
included)

``` makefile
BIN := xyz
DEP := $(shell pcpp -lp $(BIN:%=%.pl))
```

### Dependency files

The `pcpp -d target_name` can be used to generate a dependency file for
Makefile.  Compared to the `-lp` option, the `-d` and `-dd` options also
include the input file into the list.  The `pcpp -lp input | xargs` will list
only included files.  The usage in the Makefile is:

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

### See also

&nbsp;&nbsp; [pcpp -h](doc/pcpp.md)  
&nbsp;&nbsp; [uninclude -h](doc/uninclude.md)  

### Installation

Files `pcpp` and `uninclude` are standalone Perl scripts, which can be copied
to any `/bin` directory for a system-wide installation.

### Under the hood

The pcpp itself is processed by the pcpp, so its source code is example how to
use the pcpp.

<br><div align=right><i>R.Jaksa 2008,2024</i></div>
