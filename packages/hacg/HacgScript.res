open Webapi.Dom
open Belt

let magnetHashRe = Js.Re.fromString("[0-9a-fA-F]{40,}")

let inContent = el =>
  el->Element.ofNode->Option.map(Element.className)->Option.eq(Some(""), (a, b) => a == b)

let isMagnetLink = el =>
  el
  ->Element.ofNode
  ->Option.map(Element.innerText)
  ->Option.map(text => Js.Re.test_(magnetHashRe, text))
  ->Option.getWithDefault(false)

let nodeListHasMagnetLink =
  document
  ->Document.querySelectorAll("p")
  ->NodeList.toArray
  ->Array.keep(inContent)
  ->Array.keep(isMagnetLink)

let highlightLink = link => {
  let spanEl = document->Document.createElement("span")
  let linkStyle = "color:#1982d1;"
  spanEl->Element.setInnerHTML(link)
  spanEl->Element.setAttribute("style", linkStyle)
  spanEl->Element.outerHTML
}

let replaceMagnetHash = node => {
  let el = node->Element.ofNode
  let innerHtml = el->Option.map(Element.innerHTML)->Option.getWithDefault("")
  let magnetLink =
    innerHtml
    ->Js.String.match_(magnetHashRe, _)
    ->Option.flatMap(Array.get(_, 0))
    ->Option.map(hash => "magnet:?xt=urn:btih:" ++ hash)
    ->Option.map(highlightLink)

  el->Option.map(
    Element.setInnerHTML(
      _,
      magnetLink
      ->Option.map(Js.String.replaceByRe(magnetHashRe, _, innerHtml))
      ->Option.getWithDefault(innerHtml),
    ),
  )
}

let _ = nodeListHasMagnetLink->Array.map(replaceMagnetHash)
