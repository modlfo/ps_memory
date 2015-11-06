# ps_memory
Runs a process and calls ps to get the memory usage

### Build

```
$ ocamlbuild -use-ocamlfind -pkg unix ps_memory.native
```

### Usage

```
$ ps_memory.native cmd arg1 ... argn
```
