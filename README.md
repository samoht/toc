# TOC - Manage tables of contents in Markdown files

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

This will replace any `[toc]` tokens automatically to include the
file's table of contents instead.

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

`toc` adds transparent markers at the beginning and end of the generated
table of contents. The next call to `toc` will regenerate the table of
contents from scratch.

To regenerate the TOC, run:

```
$ toc README.md
README.md has been updated.
```

### Options

None at the moment. It's easy to add a way to control the start and depth for
instance.

### Multiple TOC

It is possible to define multiple table of contents the same file.

## License

MIT
