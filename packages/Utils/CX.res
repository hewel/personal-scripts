open Belt

type className = Cs(string) | Co(option<string>) | Cb(bool, string) | Ce(bool, string, string)
let join: array<string> => string = Js.Array.joinWith(" ")

let cx: array<className> => string = classNames =>
  classNames
  ->Array.keepMap(className => {
    switch className {
    | Cs(s) => Some(s)
    | Co(o) => o
    | Cb(b, s) => b ? Some(s) : None
    | Ce(b, l, r) => b ? Some(l) : Some(r)
    }
  })
  ->join
