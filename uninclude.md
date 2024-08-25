### NAME
uninclude - remove included parts from pcpp generated files

### USAGE
     uninclude [OPTIONS] file

### DESCRIPTION
Removes all included parts from a pcpp generated file.  Depends
on pcpp watermarking.  Can return back the #include statements,
but they are flattened to a single level direct includes.

### OPTIONS
     -h  This help.
     -v  Verbose.
     -l  Just list all includes, indentation by the include level.
    -ni  Don't return back #include statements.

### VERSION
pcpp-0.10 R.Jaksa 2008,2024 GPLv3 built 2024-08-13

