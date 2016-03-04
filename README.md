# nix-http-serve

Very rough script to serve the result of a nix expression as http files.

The nice thing is that it re-runs the nix-expression on each reload (> `cachingSeconds`),
and since that is O(1) if the nix expression didn’t change it’s very convenient.

4 environment variables need to be set so the script knows what to do where.

* `port`: port to serve on
* `varfolder`: the folder which will receive the updated results
* `root`: the path *inside* the result that should be served as root (use a folder, not a file, otherwise the fileserver won’t know the mimetype)
* `nixfile`: the file (or folder) that `nix-build` should evaluate

Example invocation to show the most recent nixpkgs docs:

```bash
env port=8085 \
    nixfile=\<nixpkgs/doc\> \
    root=/share/doc/nixpkgs/ \
    varfolder=./test \
      ./nix-http-serve
```

```bash
# to build
nix-build -E 'with import <nixpkgs> {}; pkgs.callPackage ./default.nix {}
# to install into local env
nix-env -i $( <previous command> )
```

Have fun!