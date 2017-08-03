(* Copyright (C) 2017  Petter A. Urkedal <paurkedal@gmail.com>
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

(** Request specification. *)

module Mult : sig
  type +'m t constraint 'm = [< `Zero | `One | `Many]

  val zero : [> `Zero] t
  val one : [> `One] t
  val zero_or_one : [> `Zero | `One] t
  val many : ([> `Zero | `One | `Many] as 'a) t

  val only_zero : [< `Zero] t -> unit
  val only_one : [< `One] t -> unit
  val only_zero_or_one : [< `Zero | `One] t -> unit
end

type ('a, 'b, +'m) t constraint 'm = [< `Zero | `One | `Many]

val create :
  ?oneshot: bool ->
  'a Caqti_type.t -> 'b Caqti_type.t -> 'm Mult.t ->
  (Caqti_driver_info.t -> string) -> ('a, 'b, 'm) t

val params_type : ('a, _, _) t -> 'a Caqti_type.t
val row_type : (_, 'b, _) t -> 'b Caqti_type.t
val row_mult : (_, _, 'm) t -> 'm Mult.t

val query_id : ('a, 'b, 'm) t -> int option
val query_string : ('a, 'b, 'm) t -> Caqti_driver_info.t -> string
