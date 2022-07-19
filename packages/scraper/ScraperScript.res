open Webapi.Dom
open Belt

let keyfieldList =
  document
  ->Document.querySelectorAll(".keyfield-value")
  ->NodeList.toArray
  ->Array.map(field => field->Node.textContent->Js.String.trim)

Js.log2("keys:\n", keyfieldList->Js.Array.joinWith("\n", _))
