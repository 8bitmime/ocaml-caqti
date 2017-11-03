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

(** Semi-internal: Signature for driver implementation.

    This interface is unstable. *)

open Caqti_sigs

(** The part of {!CAQTI} which is implemented by backends. *)
module type S = sig
  type 'a io
  module type CONNECTION = CONNECTION with type 'a io = 'a io
  val connect : Uri.t -> (module CONNECTION) io
end

(** Abstraction of the connect function over the concurrency monad. *)
module type F =
  functor (System : Caqti_system_sig.S) -> S with type 'a io := 'a System.io
