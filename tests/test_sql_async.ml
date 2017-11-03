(* Copyright (C) 2014--2017  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the OCaml static compilation exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Core
open Async
open Caqti_describe
open Caqti_query
open Testkit

module Q = struct
  let create_tmp = prepare_fun @@ function
    | `Pgsql ->
      "CREATE TEMPORARY TABLE caqti_test \
         (id SERIAL NOT NULL, i INTEGER NOT NULL, s VARCHAR(80) NOT NULL)"
    | `Mysql ->
      "CREATE TEMPORARY TABLE caqti_test \
         (id INTEGER NOT NULL, i INTEGER NOT NULL, s VARCHAR(80) NOT NULL)"
    | `Sqlite ->
      "CREATE TABLE caqti_test \
         (id INTEGER PRIMARY KEY, i INTEGER NOT NULL, s VARCHAR(80) NOT NULL)"
    | _ -> failwith "Unimplemented."
  let drop_tmp = prepare_sql "DROP TABLE caqti_test"
  let insert_into_tmp = prepare_fun @@ function
    | `Pgsql -> "INSERT INTO caqti_test (i, s) VALUES ($1, $2)"
    | `Sqlite | `Mysql -> "INSERT INTO caqti_test (i, s) VALUES (?, ?)"
    | _ -> failwith "Unimplemented."
  let select_from_tmp = prepare_fun @@ function
    | `Pgsql | `Sqlite | `Mysql -> "SELECT i, s FROM caqti_test"
    | _ -> failwith "Unimplemented."
end

let test (module Db : Caqti_async.CONNECTION) =
  let open Deferred.Or_error in

  (* Create, insert, select *)
  Db.exec Q.create_tmp [||] >>= fun () ->
  Db.exec Q.insert_into_tmp Db.Param.([|int 2; string "two"|]) >>= fun () ->
  Db.exec Q.insert_into_tmp Db.Param.([|int 3; string "three"|]) >>= fun () ->
  Db.exec Q.insert_into_tmp Db.Param.([|int 5; string "five"|]) >>= fun () ->
  Db.fold Q.select_from_tmp
    Db.Tuple.(fun t (i_acc, s_acc) -> i_acc + int 0 t, s_acc ^ "+" ^ string 1 t)
    [||] (0, "zero") >>= fun (i_acc, s_acc) ->
  assert (i_acc = 10);
  assert (s_acc = "zero+two+three+five");

  (* Describe *)
  (match Db.describe,
         Caqti_driver_info.describe_has_typed_fields Db.driver_info with
   | None, true -> assert false
   | _, false -> return ()
   | Some describe, true ->
      describe Q.select_from_tmp >>= fun qd ->
      assert (qd.querydesc_params = [||]);
      assert (qd.querydesc_fields = [|"i", `Int; "s", `String|]);
      return ()) >>= fun () ->

  (* Drop *)
  Db.exec Q.drop_tmp [||]

let test_pool = Caqti_async.Pool.use test

let main uri () =
  Shutdown.don't_finish_before begin
    Deferred.Or_error.(
      Caqti_async.connect uri >>= test >>= fun () ->
      test_pool (Caqti_async.connect_pool uri)
    ) >>| Or_error.ok_exn
  end;
  Shutdown.shutdown 0

let () =
  Arg.parse
    common_args
    (fun _ -> raise (Arg.Bad "No positional arguments expected."))
    Sys.argv.(0);
  let uri = common_uri () in
  never_returns (Scheduler.go_main ~main:(main uri) ())
