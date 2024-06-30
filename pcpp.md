### NAME
pcpp - simple Perl/Python/C/C++ preprocessor

### USAGE
       pcpp [OPTIONS] file file ...

### DESCRIPTION
Simple Perl/Python/C/C++ preprocessor for in-comment directives.
* process include directives,
* removes triple-comments.

### OPTIONS
        -h  This help.
        -v  Verbose, -vv for more verbose.
        -l  List all files to be used, without producing actual output.
       -ln  Plain list of files to be included, -l1/lp for level1 or paths.
       -dd  Print a list of dependencies (input file plus included ones).
    -d TGT  Generate dependencies list for Makefile for the TGT target.
    -e DIR  Exclude directory from a search, multiple -e possible.
       -nt  No triple comments removal.
       -nw  No watermarking of included parts (by #included).
       -ni  No indentation propagation.

### INCLUDE DIRECTIVE
       Only lines with the "include" directive are recognized.
       Whitespace after the hash is optional, quotes optional.
       Whitespace before the hash is used to indent the included content.
   
       Include files can be defined by the filename, by the path, or by
       a partial incomplete path.  The path resolving procedure is:
   
       1. look for direct path from CWD,
       2. look for relative path from file to which we include,
       3. find filename recursively in the depth order from CWD,
       4. strip directory part from include and serch by filename.
       
       Double includes are avoided.  Missing includes are ignored.
       Any text after include files is a comment.
   
       # include "abc.pl"     # Perl, Python
       // include "abc.h"     // C, C++
       #include abc.pl xyz.pl # multiple files in one include possible
       ## include abc.pl      # not an include due to two hashes
         # include abc.pl     # indented include of abc.pl
       # include "abc.pl" # comment
       # include abc.pl xyz.pl comment

### TRIPLE COMMENTS
       Triple comments are removed, together with preceding empty lines.
       All other comments are propagated to the output.
   
       ### this line will be removed from the Perl/Python code by pcpp
       /// this line will be removed from the C/C++ code by pcpp
       #### but this will be kept

### EXAMPLES
       pcpp -v pcpp.pl > pcpp
       pcpp -d pcpp pcpp.pl > .pcpp.d

### VERSION
pcpp-0.8b R.Jaksa 2008,2024 GPLv3 built 2024-06-30

