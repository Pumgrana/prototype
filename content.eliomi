(** [make elements]
    Generate the content html with given elements *)
val make :
  [< Html5_types.div_content_fun ] Eliom_content.Html5.F.elt list
  Eliom_content.Html5.F.wrap ->
  Html5_types.div Eliom_content.Html5.F.elt

(** [get_data content_uri]
    return data of the given content (title, html_body) *)
val get_data : Rdf_store.uri ->
  (string * Html5_types.div Eliom_content.Html5.F.elt) Lwt.t
