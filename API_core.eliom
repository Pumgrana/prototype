(*
  API Core
  This Module do request to data base and format well to return it in service
 *)

module Yj = Yojson.Safe

(*** Tools *)
let yojson_of_bson bson =
  Yj.from_string (Bson.to_simple_json bson)

let yojson_of_bson_document bson_l =
  let rec aux yojson_l = function
    | []        -> yojson_l
    | h::t      -> aux ((yojson_of_bson h)::yojson_l) t
  in
  `List (List.rev (aux [] bson_l))

(*
** Content
*)

(*** Getters *)
let get_detail content_id =
  let aux () =
    let objectId = Bson.create_objectId content_id in
    let bson_condition = Bson.add_element API_tools.id_field objectId Bson.empty
    in
    let result = Mongo.find_q_s_one API_tools.contents_coll bson_condition
      API_tools.content_format in
    let result_bson = List.hd (MongoReply.get_document_list result) in
    yojson_of_bson result_bson
  in
  API_tools.check_return aux "content"

let get_content_id_from_link link_id =
  let objectId = Bson.create_objectId link_id in
  let bson_condition =
    Bson.add_element API_tools.id_field objectId Bson.empty
  in
  let result = Mongo.find_q_one API_tools.links_coll bson_condition in
  let result_bson = List.hd (MongoReply.get_document_list result) in
  Bson.get_element API_tools.targetid_field result_bson

let get_detail_by_link link_id =
  let aux () =
    let target_id = get_content_id_from_link link_id in
    let bson_condition =
      Bson.add_element API_tools.id_field target_id Bson.empty
    in
    let result = Mongo.find_q_s_one API_tools.contents_coll bson_condition
      API_tools.content_format in
    let result_bson = List.hd (MongoReply.get_document_list result) in
    yojson_of_bson result_bson
  in
  API_tools.check_return aux "content"

(* Currently, filter is not used,
   because we haven't enought informations in the DB *)
let get_contents filter tags_id =
  let aux () =
    let () =
      match filter with
      | None                    -> ()
      | Some "MOST_USED"        -> ()
      | Some "MOST_VIEW"        -> ()
      | Some "MOST_RECENT"      -> ()
      | Some x                  -> failwith "get_contents has a bad value."
    in
    let bson_condition = match tags_id with
      | None    -> Bson.empty
      | Some x  -> Bson.add_element API_tools.tagsid_field
        (Bson.create_doc_element
           (MongoQueryOp.all (List.map Bson.create_objectId x)))
        Bson.empty
    in
    let results = Mongo.find_q_s API_tools.contents_coll bson_condition
      API_tools.content_format in
    let results_bson = MongoReply.get_document_list results in
    yojson_of_bson_document results_bson
  in
  API_tools.check_return aux "contents"


(*
** Tags
*)

(*** Getters *)

let get_tags tags_id =
  let aux () =
    let document_of_tag tag_id =
      (Bson.add_element API_tools.id_field (Bson.create_objectId tag_id) Bson.empty)
    in

    let bson_condition = match tags_id with
      | []      -> Bson.empty
      | id::t	->  (MongoQueryOp.or_op (List.map document_of_tag tags_id))

    in
    let results = Mongo.find_q_s API_tools.tags_coll bson_condition
      API_tools.tag_format in
    let results_bson = MongoReply.get_document_list results in
    yojson_of_bson_document results_bson
  in
  API_tools.check_return aux "tags"


let get_tags_by_type tag_type =
  let aux () =
    let convert_param = API_conf.(if tag_type = link_tag then link_tag_str else content_tag_str)
    in
    let objectId = Bson.create_string convert_param in
    let bson_condition = Bson.add_element API_tools.type_field objectId Bson.empty
    in
    let result = Mongo.find_q_s API_tools.tags_coll bson_condition
      API_tools.tag_format in
    let result_bson = MongoReply.get_document_list result in
    yojson_of_bson_document result_bson
  in
  API_tools.check_return aux "tags"


let get_tags_from_content content_id =
  let aux () =
    (* step 1: request the content *)
    let content_objectId = Bson.create_objectId content_id in
    let content_bson_condition = Bson.add_element API_tools.id_field content_objectId Bson.empty
    in
    let result_content = Mongo.find_q_one API_tools.contents_coll content_bson_condition in
    let content_bson = List.hd(MongoReply.get_document_list result_content) in


    (* step 2: request the associated tags *)
    let tag_id_list = Bson.get_list(Bson.get_element API_tools.tagsid_field content_bson) in
    let document_of_tag_id_list tag_id_list =
      (Bson.add_element API_tools.id_field tag_id_list Bson.empty)
    in
    let tag_bson_condition =
      (MongoQueryOp.or_op
      	 (List.map document_of_tag_id_list tag_id_list))
    in
    let results_tag = Mongo.find_q_s API_tools.tags_coll tag_bson_condition
      API_tools.tag_format in
    let results_bson = MongoReply.get_document_list results_tag in
    yojson_of_bson_document results_bson
  in
  API_tools.check_return aux "tags"

(*
** Links
*)

(*** Getters *)
let get_links_from_content content_id =
  let aux () =
    (* getting every link with 'content_id' as origin *)
    let content_objectId = Bson.create_objectId content_id in
    let document_of_link_id_list field link_id_list =
      (Bson.add_element field link_id_list Bson.empty)
    in
    let result_content = Mongo.find_q_one API_tools.links_coll (document_of_link_id_list API_tools.originid_field content_objectId) in
    (* hd is for testing, later you have to loop *)
    let content_bson = List.hd(MongoReply.get_document_list result_content) in
    let link_id_list = Bson.get_element API_tools.targetid_field content_bson in

    (* getting content to return *)
    let link_query    = document_of_link_id_list API_tools.id_field link_id_list in
    let result_query  = Mongo.find_q_s_one API_tools.contents_coll link_query
      API_tools.content_format
    in
    let mongo_query   = MongoReply.get_document_list result_query in
    yojson_of_bson_document mongo_query
  in
  API_tools.check_return aux "contents"

(*
let get_links_from_content_tags content_id tags_id =
  let aux () =
    (* getting every link with 'content_id' as origin *)
    let content_objectId = Bson.create_objectId content_id in
    let document_of_link_id_list field link_id_list =
      (Bson.add_element field link_id_list Bson.empty)
    in
    let result_content = Mongo.find_q_one API_tools.links_coll (document_of_link_id_list API_tools.originid_field content_objectId) in
    (* hd is for testing, later you have to loop *)
    let content_bson = List.hd(MongoReply.get_document_list result_content) in
    let link_id_list = Bson.get_element API_tools.targetid_field content_bson in

    (* getting content to return *)
    let link_query    = document_of_link_id_list API_tools.id_field link_id_list in
    let link_bson_condition =
      (MongoQueryOp.or_op (List.map (Bson.add_element API_tools.tagsid_field tags_id link_query)))
    in
    let result_query = Mongo.find_q_s API_tools.contents_coll link_bson_condition in
    let mongo_query   = MongoReply.get_document_list result_query in
    yojson_of_bson_document mongo_query
  in
  API_tools.check_return aux "contents"
*)

let get_tags_from_content_link content_id =
  let aux () =
    (* step 1: get links related to the content*)
    let content_objectId = Bson.create_objectId content_id in
    let originid_bson_condition = Bson.add_element API_tools.originid_field content_objectId Bson.empty in
    let result_links = Mongo.find_q API_tools.links_coll originid_bson_condition in
    let links_bson = MongoReply.get_document_list result_links in


    (* step 2: request the related tags *)
    let rec remove_duplicate list =
      let rec aux new_list = function
        | []      -> new_list
        | e::t    ->
          if (List.exists (fun c -> (String.compare c e) = 0) new_list)
          then aux new_list t
          else aux (e::new_list) t
      in
      List.map Bson.create_objectId (aux [] (List.map Bson.get_objectId list))
    in
    let rec create_tag_list list =
      let get_tags current_link = Bson.get_list
        (Bson.get_element API_tools.tags_field current_link)
      in
      let rec aux new_list = function
        | []	-> new_list
        | l::t	-> aux ((get_tags l)@new_list) t
      in
      aux [] list

    in
    let tags_id = remove_duplicate (create_tag_list links_bson) in

    let document_of_tag tag_id =
      Bson.add_element API_tools.id_field tag_id Bson.empty
    in
    let bson_tags_id_list = List.map document_of_tag tags_id in
    let bson_condition = MongoQueryOp.or_op bson_tags_id_list in
    let results = Mongo.find_q_s API_tools.tags_coll bson_condition
      API_tools.tag_format in
    let results_bson = MongoReply.get_document_list results in
    let jresult = yojson_of_bson_document results_bson in
    if bson_tags_id_list != [] then jresult else `Null
  in
  API_tools.check_return aux "tags"
