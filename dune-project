(lang dune 3.5)
(name toc)

(generate_opam_files true)

(source (github samoht/toc))
(license ISC)
(authors "Thomas Gazagnaire")
(maintainers "Thomas Gazagnaire")

(package
 (name toc)
 (synopsis "A generator of table of contents for Github Markdown files")
 (depends
  (alcotest :with-test)
  ocaml
  dune
  (omd (>= 2.0.0~alpha2))
  (cmdliner (>= 1.1.0))
  logs
  fmt
  astring))
