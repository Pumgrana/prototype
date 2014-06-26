
(*
  GUI Tools
  This module help GUI_html to make the html.
*)

{shared{


open Eliom_lib
open Eliom_content
open Eliom_content.Html5
open Eliom_content.Html5.F

(*** Build tools  *)

let build_header elt_list =
  div ~a:[a_class["header"]]
    ([span ~a:[a_class["pumgrana"]]
         [a ~service:%GUI_services.starting_service
             [img ~a:[a_class ["pumgrana_logo"]]
                 ~alt:("Pumgrana Logo")
                 ~src:(make_uri
                         ~service:(Eliom_service.static_dir ())
                         ["images"; "LOGO_Pumgrana.png"]) ()] ()]]@elt_list)

let build_header_back_forward elt_list =
  let back_button = D.raw_input ~input_type:`Submit ~value:"Back" () in
  let forward_button = D.raw_input ~input_type:`Submit ~value:"Forward" () in
  let header_elt = build_header ([back_button; forward_button]@elt_list) in
  back_button, forward_button, header_elt

let build_contents_header () =
  let insert_button =
    D.raw_input ~input_type:`Submit ~value:"Add new content" ()
  in
  let back_button, forward_button, header_elt =
    build_header_back_forward [insert_button]
  in
  insert_button, back_button, forward_button, header_elt

let build_detail_content_header () =
  let update_button = D.raw_input ~input_type:`Submit ~value:"Update" () in
  let delete_button = D.raw_input ~input_type:`Submit ~value:"Delete" () in
  let back_button, forward_button, header_elt =
    build_header_back_forward [update_button; delete_button]
  in
  back_button, forward_button, update_button, delete_button, header_elt

let build_update_content_header () =
  let cancel_button = D.raw_input ~input_type:`Submit ~value:"Cancel" () in
  let save_button = D.raw_input ~input_type:`Submit ~value:"Save" () in
  let header_elt = build_header [cancel_button; save_button] in
  cancel_button, save_button, header_elt

(** Build tags list with checkbox *)
let build_ck_tags_list tags =
  let rec aux inputs full_html = function
    | []                -> inputs, List.rev full_html
    | (uri, subject)::t  ->
      let str_uri = Rdf_store.string_of_uri uri in
      let input = D.raw_input ~input_type:`Checkbox ~name:str_uri () in
      let html = div [input; pcdata subject] in
      aux (input::inputs) (html::full_html) t
  in
  aux [] [] tags

(** Build the tags html formular from tag list *)
let build_tags_form tags =
  let tags_inputs, tags_html_0 = build_ck_tags_list tags in
  let submit = D.raw_input ~input_type:`Submit ~value:"Submit" () in
  submit, tags_inputs, List.rev ((div [submit])::(List.rev tags_html_0))

(** Build a simple tags list html *)
let build_tags_list tags =
  let aux (uri, subject) = div [pcdata subject] in
  List.map aux tags

(** Build the links list with checkbox *)
let build_ck_links_list links =
  let rec aux inputs full_html = function
    | [] -> inputs, List.rev full_html
    | (link_id, content_id, title, summary)::t ->
      let str_link_id = Rdf_store.string_of_link_id link_id in
      let input = D.raw_input ~input_type:`Checkbox ~name:str_link_id () in
      let html = div [input; pcdata title; br (); pcdata summary] in
      aux (input::inputs) (html::full_html) t
  in
  aux [] [] links

(** Build a links list html *)
let build_links_list links =
  let aux (link_id, content_id, title, summary) =
    let content_str_id = GUI_deserialize.string_of_id content_id in
    div [a ~service:%GUI_services.content_detail_service
            [pcdata title] content_str_id;
         br (); pcdata summary]
  in
  List.map aux links

let build_contents_list contents =
  let aux (id, title, summary) =
    let str_id = GUI_deserialize.string_of_id id in
    div ~a:[a_class ["content"]]
      [a ~service:%GUI_services.content_detail_service [pcdata title] str_id;
       br ();
       span [pcdata summary]]
  in
  List.map aux contents

let build_add_tag () =
  let input = D.raw_input ~input_type:`Text () in
  let add = D.raw_input ~input_type:`Submit ~value:"Add" () in
  input, add, ref [], [input; add]

}}
