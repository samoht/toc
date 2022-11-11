# TOC - Manage table of contents in Github Markdown files

This repository contains a simple utility to manage tables of contents for
Github Markdown files.

[//]: # (begin toc)

*  [Usage](#Usage)
   *  [First Use](#First-Use)
   *  [Regenerate TOC](#Regenerate-TOC)
   *  [Options](#Options)
   *  [Multiple TOC](#Multiple-TOC)
*  [License](#License)

[//]: # (end toc)

## Usage

### First Use

```
$ toc README.md
README.md has been updated.
```

This will replace any `[toc]` tokens automatically to include the
file's table of contents instead.

```diff
-[toc]
+[//]: # (begin toc)
+
+*  Usage
+   *  First Use
+   *  Regenerate TOC
+   *  Options
+   *  Multiple TOC
+*  License
+
+[//]: # (end toc)
```

### Regenerate TOC

`toc` adds transparent markers at the beginning and end of the generated
table of contents. The next call to `toc` will regenerate the table of
contents from scratch.

### Options

None at the moment. It's easy to add a way to control the start and depth for
instance.

### Multiple TOC

It is possible to define multiple table of contents the same file.

## License

MIT
