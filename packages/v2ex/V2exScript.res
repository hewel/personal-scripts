%%raw("import 'virtual:windi.css'")

open Webapi.Dom
open Belt

module App = {
  @react.component
  let make = () =>
    <Snackbar.Provider>
      <div> {React.string("hi")} </div>
    </Snackbar.Provider>
}

let _ =
  document
  ->Document.createElement("div")
  ->(app => {
    Element.setClassName(app, "scriptApp")
    ReactDOM.render(<App />, app)
    app
  })
  ->Element.asNode
  ->(
    app =>
      document
      ->Document.asHtmlDocument
      ->Option.flatMap(HtmlDocument.body)
      ->Option.map(body => body->Element.appendChild(~child=app))
  )
