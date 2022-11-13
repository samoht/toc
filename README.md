# TOC - Manage Tables of Contents in Markdown Files

This repository contains a simple utility to manage tables of contents for
Github Markdown files.

<div class="toc">

*  [Usage](#Usage)
   *  [First Use](#First-Use)
   *  [Regenerate TOC](#Regenerate-TOC)
   *  [Options](#Options)
   *  [Multiple TOC](#Multiple-TOC)
*  [License](#License)

</div>

## Usage

### First Use

Run:

```
$ toc README.md
README.md has been updated.
```

This will replace any `[toc]` tokens by the file's table of contents instead.

```diff
-[toc]
+<div class="toc">
+
+*  [Usage](#Usage)
+   *  [First Use](#First-Use)
+   *  [Regenerate TOC](#Regenerate-TOC)
+   *  [Options](#Options)
+   *  [Multiple TOC](#Multiple-TOC)
+*  [License](#License)
+
+</div>
```

### Regenerate TOC

`toc` adds transparent `<div>` markers around the generated table of
contents. Hence, the next call to `toc` will update the table
correctly.

To regenerate the TOC, run:

```
$ toc README.md
README.md has been updated.
```

### Options

```
$ toc README.md -p
*  [Usage](#Usage)
   *  [First Use](#First-Use)
   *  [Regenerate TOC](#Regenerate-TOC)
   *  [Options](#Options)
   *  [Multiple TOC](#Multiple-TOC)
*  [License](#License)
```

Use `toc --help` to see all the options.

### Multiple TOC

Use as many `[toc]` as you like to define multiple table of contents
the same file.

## License

MIT. See the [LICENSE file](./LICENSE.md).
