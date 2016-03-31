# nix-http-serve

Very rough script to serve the result of a nix expression as http files.

The nice thing is that it re-runs the nix-expression on each reload (> `cachingSeconds`),
and since that is O(1) if the nix expression didn’t change it’s very convenient.

4 environment variables need to be set so the script knows what to do where.

* `port`: port to serve on
* `varfolder`: the folder which will receive the updated results
* `root`: the path *inside* the result that should be served as root (use a folder, not a file, otherwise the fileserver won’t know the mimetype)
* `nixfile`: the file (or folder) that `nix-build` should evaluate
* `attribute` (optional): the attribute that produces the output

## Run

Most recent nixpkgs docs:

```bash
env port=8085 \
    nixfile=\<nixpkgs/doc\> \
    root=/share/doc/nixpkgs/ \
    varfolder=./test \
      ./nix-http-serve
```

For the nixos (x86) documentation:
```bash
env port=8085 \
    nixfile=\<nixpkgs/nixos/release.nix\> \
    root=/share/doc/nixos/ \
    varfolder=./test \
    attribute="manual.x86_64-linux" \
      ./nix-http-serve
```

## Build

```bash
# to build
nix-build -p '(callPackage ./. {}).nix-http-serve'
# to install into local env
nix-env -i $( <previous command> )
```

## Hack

```bash
nix-shell -E "with import <nixpkgs> {}; (callPackage ./. {}).nix-http-serve"
```


Have fun!