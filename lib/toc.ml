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
let html t = Html_block ([], t)
let concat ts = Concat ([], List.map text ts)
let toc = concat [ "["; "toc"; "]" ]
let begin_toc = "<div class=\"toc\">"
let end_toc = "</div>"

(* [toc] is either:
   - empty; in that case it appears as [toc] in the Markdown file
   - expanded: in that case it appears between `[//]: # begin toc` and
     `[//]: # end toc` markers *)
let is_toc = function
  | Paragraph (_, x) when x = toc -> Some Toc
  | Html_block (_, x) when x = begin_toc -> Some Begin
  | Html_block (_, x) when x = end_toc -> Some End
  | Html_block (_, x) when x = begin_toc ^ "\n" -> Some Begin
  | Html_block (_, x) when x = end_toc ^ "\n" -> Some End
  | _ -> None

let rec replace ~toc : doc -> doc = function
  | [] -> []
  | h :: t -> (
      match is_toc h with
      | None -> h :: replace ~toc t
      | Some Toc -> html begin_toc :: toc :: html end_toc :: replace ~toc t
      | Some Begin -> h :: toc :: skip_to_end ~toc t
      | Some End -> failwith "malformed toc markers")

and skip_to_end ~toc : doc -> doc = function
  | [] -> []
  | h :: t -> (
      match is_toc h with
      | Some End -> h :: replace ~toc t
      | _ -> skip_to_end ~toc t)

module Linkify = struct
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

type t = attributes block option

let v ?(depth = 10) ?(add_links = true) doc : t =
  match Omd.toc ~depth ~start:[ 1 ] doc with
  | [] -> None
  | [ toc ] ->
      let toc = if add_links then Linkify.block toc else toc in
      Some toc
  | _ -> assert false (* this is an invariant in Omd.toc *)

let expand ?depth doc =
  match v ?depth doc with
  | None -> None
  | Some toc ->
      Log.info (fun l -> l "TOC=%a" pp [ toc ]);
      Log.debug (fun l -> l "BEFORE: %a" pp doc);
      let doc = replace ~toc doc in
      Log.debug (fun l -> l "AFTER: %a" pp doc);
      Some doc

let to_string = Pp_markdown.to_string

let pp ppf (t : t) =
  match t with
  | None -> Fmt.pf ppf "No sections."
  | Some t -> Fmt.of_to_string to_string ppf [ t ]
