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

open Omd

let src = Logs.Src.create "irmin.tree" ~doc:"Persistent lazy trees for Irmin"

module Log = (val Logs.src_log src : Logs.LOG)

let pp = Fmt.of_to_string Omd.to_sexp

type token = Toc | Begin | End

(* [toc] is either:
   - empty; in that case it appears as [toc] in the Markdown file
   - expanded: in that case it appears between `[//]: # begin toc` and
     `[//]: # end toc` markers *)
let is_toc = function
  | Concat ([], [ Text ([], "["); Text ([], "toc"); Text ([], "]") ]) ->
      Some Toc
  | Concat ([], [ Text ([], "["); Text ([], "//"); Text ([], "]: # begin toc") ])
    ->
      Some Begin
  | Concat ([], [ Text ([], "["); Text ([], "//"); Text ([], "]: # end toc") ])
    ->
      Some End
  | _ -> None

let rec replace ~toc : doc -> doc = function
  | [] -> []
  | (Paragraph (_, x) as h) :: t -> (
      match is_toc x with
      | None -> h :: replace ~toc t
      | Some Toc -> toc :: replace ~toc t
      | Some Begin -> h :: toc :: skip_to_end ~toc t
      | Some End -> failwith "malformed toc markers")
  | h :: t -> h :: replace ~toc t

and skip_to_end ~toc : doc -> doc = function
  | [] -> []
  | (Paragraph (_, x) as h) :: t -> (
      match is_toc x with
      | Some End -> h :: replace ~toc t
      | _ -> skip_to_end ~toc t)
  | _ :: t -> skip_to_end ~toc t

let toc ?depth doc =
  match Omd.toc ?depth ~start:[ 1 ] doc with
  | [] -> None
  | [ toc ] -> Some toc
  | _ -> assert false (* this is an invariant in Omd.toc *)

let expand ?depth doc =
  match toc ?depth doc with
  | None -> None
  | Some toc ->
      Log.debug (fun l -> l "BEFORE: %a" pp doc);
      let doc = replace ~toc doc in
      Log.debug (fun l -> l "AFTER: %a" pp doc);
      Some doc

let to_string = Pp_markdown.to_string
