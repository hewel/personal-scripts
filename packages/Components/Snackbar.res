%%raw("import 'preact/debug'")
%%raw("import 'virtual:windi.css'")
@module("./Snackbar.module.css") external styles: {..} = "default"

open Belt
open CX

external toRafId: 'a => Webapi.rafId = "%identity"

type severity = [
  | #error
  | #info
  | #success
  | #warning
]

type snackContent = {
  id: int,
  title: string,
  message: string,
  severity: severity,
  duration: int,
  closing: bool,
  removing: bool,
}

module Toast = {
  let genToastStyleSeverity = severity => {
    [
      switch severity {
      | #error => "border-rose-300"
      | #info => "border-blue-300"
      | #success => "border-emerald-300"
      | #warning => "border-amber-300"
      },
      switch severity {
      | #error => "bg-rose-50"
      | #info => "bg-blue-50"
      | #success => "bg-emerald-50"
      | #warning => "bg-amber-50"
      },
      switch severity {
      | #error => "shadow-rose-400/10"
      | #info => "shadow-blue-400/10"
      | #success => "shadow-emerald-400/10"
      | #warning => "shadow-amber-400/10"
      },
    ]->CX.join
  }

  let genIconStyle = severity => {
    [
      switch severity {
      | #error => "text-rose-500"
      | #info => "text-blue-500"
      | #success => "text-emerald-500"
      | #warning => "text-amber-500"
      },
    ]->CX.join
  }

  let iconSize = 36
  let baseClasses = "relative rounded-lg shadow-md inline-flex h-max min-h-14 border-2 py-3 pl-3 pr-4 w-80 mb-3 items-center"

  @react.component
  let make = (
    ~id: int,
    ~severity: severity=#info,
    ~title: React.element,
    ~message: option<React.element>=?,
    ~duration: int,
    ~onClosing: int => unit,
    ~onClose: int => unit,
  ) => {
    let timer = React.useRef(Js.Nullable.null->toRafId)
    let (countdown, setCountdown) = React.useState(_ => duration->Int.toFloat)
    let countdownPasused = React.useRef(false)

    let isTimeUp = React.useMemo1(() => countdown == 0.0, [countdown])

    let handleAnimationEnd = React.useCallback2(_ => {
      if isTimeUp {
        onClose(id)
      }
    }, (id, isTimeUp))

    let startCountingDown = React.useCallback(duration => {
      countdownPasused.current = false
      let start = ref(0.0)
      setCountdown(_ => Int.toFloat(duration))
      let rec countingDown = (timestamp: float) => {
        if start.contents == 0.0 {
          start := timestamp
        }
        let newCountdown =
          (Int.toFloat(duration) -. (timestamp -. start.contents))->Js.Math.max_float(0.0)
        setCountdown(_ => newCountdown)
        if newCountdown > 0.0 {
          timer.current = Webapi.requestCancellableAnimationFrame(countingDown)
        }
      }
      timer.current = Webapi.requestCancellableAnimationFrame(countingDown)
    })

    let pauseCountingDown = React.useCallback(() => {
      Webapi.cancelAnimationFrame(timer.current)
      countdownPasused.current = true
    })

    React.useEffect1(() => {
      startCountingDown(duration)
      Some(pauseCountingDown)
    }, [duration])

    React.useEffect2(() => {
      onClosing(id)
      None
    }, (id, isTimeUp))

    let toastIcon = switch severity {
    | #error => <Icon.CircleX size={iconSize} />
    | #info => <Icon.InfoCircle size={iconSize} />
    | #success => <Icon.CircleCheck size={iconSize} />
    | #warning => <Icon.AlertCircle size={iconSize} />
    }

    <div
      className={cx([
        Cs(baseClasses),
        Cs(genToastStyleSeverity(severity)),
        Ce(isTimeUp, styles["fadeOutUp"], styles["bounceIn"]),
      ])}
      onAnimationEnd={handleAnimationEnd}
      onMouseEnter={_ =>
        if !countdownPasused.current {
          pauseCountingDown()
        }}
      onMouseLeave={_ =>
        if countdownPasused.current {
          startCountingDown(Float.toInt(countdown))
        }}>
      <span className={CX.join(["h-9 mr-3 w-9", genIconStyle(severity)])}> {toastIcon} </span>
      <div className="flex-1">
        <strong className="text-xs mb-1 block"> {title} </strong>
        <p className="text-xs"> {Option.getWithDefault(message, React.null)} </p>
      </div>
      <span
        className="rounded-full cursor-pointer flex h-8 ml-2 transition-all text-gray-500 w-8 items-center justify-center hover:(bg-white text-dark-900) "
        onClick={_ => {setCountdown(_ => 0.0)}}>
        <Icon.X size={24} />
      </span>
      <span className="h-2 w-80 " />
    </div>
  }
}

type action =
  | AppendSnack(snackContent)
  | TailSnack
  | SetSnack(snackContent)
  | TurnClosing(int)
  | TurnRemoving(int)
  | RemoveSnack(int)
type list = array<snackContent>

let reducer = (list, action) => {
  switch action {
  | AppendSnack(content) => Array.concat(list, [content])
  | TailSnack => Array.sliceToEnd(list, 1)
  | SetSnack(content) => list->Array.map(item => item.id == content.id ? content : item)
  | TurnClosing(id) => list->Array.map(item => item.id == id ? {...item, closing: true} : item)
  | TurnRemoving(id) => list->Array.map(item => item.id == id ? {...item, removing: true} : item)
  | RemoveSnack(id) => list->Array.keep(item => item.id != id)
  }
}

module Snack = {
  let nextId = ref(0)
  let defaultSnack = {
    id: 0,
    title: "",
    message: "",
    severity: #info,
    duration: 3000,
    closing: false,
    removing: false,
  }

  @react.component
  let make = () => {
    let (list, dispatch) = React.useReducer(reducer, [])

    <div className="flex flex-col h-max w-max inset-0 top-4 left-4 fixed">
      <button
        onClick={_ => {
          let id = nextId.contents
          dispatch(
            AppendSnack({
              ...defaultSnack,
              id: id,
              title: "hi",
              message: "Hi this is a snack",
            }),
          )
          nextId := id + 1
        }}>
        {React.string("add")}
      </button>
      {list
      ->Array.map(({id, title, message, duration}) => {
        <Toast
          key={id->Int.toString}
          id={id}
          title={title->React.string}
          message={message->React.string}
          duration={duration}
          onClose={React.useCallback(id => dispatch(RemoveSnack(id)))}
          onClosing={React.useCallback(id => dispatch(TurnClosing(id)))}
        />
      })
      ->React.array}
    </div>
  }
  let make = React.memo(make)
}

module Provider = {
  @react.component
  let make = (~children: React.element) => <React.Fragment> <Snack /> {children} </React.Fragment>
  let make = React.memo(make)
}
