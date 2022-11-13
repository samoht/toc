(*
 * Copyright (c) 2022 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

let main () file depth print =
  let ic = open_in file in
  let md = Omd.of_channel ic in
  match print with
  | true ->
      let toc = Toc.v ~add_links:false md in
      Fmt.pr "%a%!" Toc.pp toc;
      close_in ic
  | false -> (
      let doc = Toc.expand ?depth md in
      close_in ic;
      match doc with
      | None -> Fmt.pr "No changes.\n%!"
      | Some doc ->
          let oc = open_out file in
          output_string oc (Toc.to_string doc);
          close_out oc;
          Fmt.pr "%s has been updated.\n%!" file)

let setup style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

open Cmdliner

let input_file =
  let doc = Arg.info ~doc:"Markdown file to expand." ~docv:"FILE" [] in
  Arg.(required @@ pos 0 (some file) None doc)

let depth =
  let doc = Arg.info ~doc:"The table of contents' depth." [ "depth"; "d" ] in
  Arg.(value @@ opt (some int) None doc)

let print =
  let doc =
    Arg.info ~doc:"Print the table of contents and exit." [ "print"; "p" ]
  in
  Arg.(value @@ flag doc)

let setup_log =
  Term.(const setup $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let () =
  let man = [ `S "DESCRIPTION"; `P "TODO" ] in
  let info =
    Cmd.info "toc" ~man
      ~doc:"Replace [toc] annotations in Markdown files with actual contents."
  in
  let cmd =
    Cmd.v info Term.(const main $ setup_log $ input_file $ depth $ print)
  in
  exit (Cmd.eval cmd)
