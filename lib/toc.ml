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
open Astring

let src = Logs.Src.create "irmin.tree" ~doc:"Persistent lazy trees for Irmin"

module Log = (val Logs.src_log src : Logs.LOG)

let pp = Fmt.of_to_string Omd.to_sexp

type token = Toc | Begin | End

let text t = Text ([], t)
let concat ts = Concat ([], List.map text ts)
let toc = concat [ "["; "toc"; "]" ]
let begin_toc = concat [ "["; "//"; "]: # (begin toc)" ]
let end_toc = concat [ "["; "//"; "]: # (end toc)" ]

(* [toc] is either:
   - empty; in that case it appears as [toc] in the Markdown file
   - expanded: in that case it appears between `[//]: # begin toc` and
     `[//]: # end toc` markers *)
let is_toc s =
  if s = toc then Some Toc
  else if s = begin_toc then Some Begin
  else if s = end_toc then Some End
  else None

let para t = Paragraph ([], t)

let rec replace ~toc : doc -> doc = function
  | [] -> []
  | (Paragraph (_, x) as h) :: t -> (
      match is_toc x with
      | None -> h :: replace ~toc t
      | Some Toc -> para begin_toc :: toc :: para end_toc :: replace ~toc t
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

module Id = struct
  (* Convert section title to a valid HTML ID. *)
  let title_to_id s =
    String.filter (fun c -> Char.Ascii.is_alphanum c || c = ' ') s
    |> String.map (function ' ' -> '-' | c -> c)

  let inline : 'attr inline -> 'attr inline =
   fun label ->
    let id = Pp_markdown.to_string [ Paragraph ([], label) ] in
    Link ([], { label; destination = "#" ^ title_to_id id; title = None })

  let rec block : 'attr block -> 'attr block = function
    | Paragraph (attr, x) -> Paragraph (attr, inline x)
    | List (attr, ty, sp, bl) ->
        List (attr, ty, sp, List.map (List.map block) bl)
    | _ -> failwith "invalid mardkown in TOC"
end

let toc ?depth doc =
  match Omd.toc ?depth ~start:[ 1 ] doc with
  | [] -> None
  | [ toc ] -> Some (Id.block toc)
  | _ -> assert false (* this is an invariant in Omd.toc *)

let expand ?depth doc =
  match toc ?depth doc with
  | None -> None
  | Some toc ->
      Log.info (fun l -> l "TOC=%a" pp [ toc ]);
      Log.debug (fun l -> l "BEFORE: %a" pp doc);
      let doc = replace ~toc doc in
      Log.debug (fun l -> l "AFTER: %a" pp doc);
      Some doc

let to_string = Pp_markdown.to_string
