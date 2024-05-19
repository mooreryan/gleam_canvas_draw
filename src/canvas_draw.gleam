import gleam/int
import gleam/result
import lustre
import lustre/attribute as a
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html as h
import lustre/event as ev

// Uncomment this for debugging.
// import tardis

// Uncomment this for debugging, too.
// pub fn main() {
//   let assert Ok(main) = tardis.single("main")

//   let app = lustre.application(init, update, view)

//   let assert Ok(_) =
//     app
//     |> tardis.wrap(with: main)
//     |> lustre.start("#app", Nil)
//     |> tardis.activate(with: main)

//   Nil
// }

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Ctx {
  CtxReady(CanvasContext)
  CtxNeedsInit
  CtxError(String)
}

type Model {
  Model(
    ctx: Ctx,
    canvas_width: Int,
    canvas_height: Int,
    canvas_id: String,
    mouse_x: Float,
    mouse_y: Float,
    pen_r: Int,
    pen_color: String,
    is_drawing: Bool,
  )
}

fn default_model() -> Model {
  Model(
    CtxNeedsInit,
    canvas_width: 500,
    canvas_height: 500,
    canvas_id: "canvas",
    mouse_x: 250.0,
    mouse_y: 250.0,
    pen_r: 5,
    pen_color: "#333333",
    is_drawing: False,
  )
}

fn init(_: Nil) -> #(Model, Effect(Msg)) {
  #(default_model(), effect.none())
}

type Msg {
  DoNothing
  GetCanvasContext
  SetCanvasContext(Ctx)
  // UserClickedOnCanvas(x: Float, y: Float)
  UserMouseDownInCanvas(x: Float, y: Float)
  UserMouseMoveInCanvas(x: Float, y: Float)
  UserMouseUpInCanvas(x: Float, y: Float)
  Draw
  UserChangedPenColor(String)
  UserChangedPenRadius(Int)
  UserClickedClearCanvas
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    DoNothing -> #(model, effect.none())
    GetCanvasContext -> #(model, get_canvas_context(model.canvas_id))
    SetCanvasContext(ctx) -> {
      #(Model(..model, ctx: ctx), effect.none())
    }

    // UserClickedOnCanvas(x, y) -> {
    //   let model = Model(..model, mouse_x: x, mouse_y: y)
    //   #(model, dispatch_draw())
    // }
    UserMouseDownInCanvas(x, y) -> {
      let model = Model(..model, mouse_x: x, mouse_y: y, is_drawing: True)
      #(model, dispatch_draw())
    }

    UserMouseMoveInCanvas(x, y) -> {
      let model = Model(..model, mouse_x: x, mouse_y: y)
      let eff = case model.is_drawing {
        True -> dispatch_draw()
        False -> effect.none()
      }
      #(model, eff)
    }

    UserMouseUpInCanvas(x, y) -> {
      let model = Model(..model, mouse_x: x, mouse_y: y, is_drawing: False)
      #(model, dispatch_draw())
    }

    Draw -> {
      let assert pen_xy =
        canvas_mouse_position(model.canvas_id, model.mouse_x, model.mouse_y)
      let #(pen_x, pen_y) = pen_xy
      #(
        model,
        fill_circle(
          model.ctx,
          x: pen_x,
          y: pen_y,
          r: model.pen_r,
          color: model.pen_color,
        ),
      )
    }

    UserChangedPenColor(s) -> #(Model(..model, pen_color: s), effect.none())
    UserChangedPenRadius(n) -> #(Model(..model, pen_r: n), effect.none())
    UserClickedClearCanvas -> #(
      model,
      clear_canvas(
        model.ctx,
        canvas_width: model.canvas_width,
        canvas_height: model.canvas_height,
      ),
    )
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let title = h.h1([], [h.text("✨ Draw something... ✨")])

  let canvas =
    h.canvas([
      a.id("canvas"),
      a.width(model.canvas_width),
      a.height(model.canvas_height),
      // ev.on("click", fn(event) {
      //   use xy <- result.map(ev.mouse_position(event))
      //   let #(x, y) = xy
      //   UserClickedOnCanvas(x, y)
      // }),
      ev.on("mousedown", fn(event) {
        use xy <- result.map(ev.mouse_position(event))
        let #(x, y) = xy
        UserMouseDownInCanvas(x, y)
      }),
      ev.on("mousemove", fn(event) {
        use xy <- result.map(ev.mouse_position(event))
        let #(x, y) = xy
        UserMouseMoveInCanvas(x, y)
      }),
      ev.on("mouseup", fn(event) {
        use xy <- result.map(ev.mouse_position(event))
        let #(x, y) = xy
        UserMouseUpInCanvas(x, y)
      }),
    ])

  let pen_options =
    h.div([], [
      h.div([], [
        h.label([a.for("pen_radius_input")], [h.text("Pen size")]),
        h.input([
          ev.on_input(fn(s) {
            let assert Ok(n) = int.parse(s)
            UserChangedPenRadius(n)
          }),
          a.id("pen_radius_input"),
          a.name("pen_radius_input"),
          a.type_("range"),
          a.min("2"),
          a.max("24"),
          a.value(int.to_string(model.pen_r)),
          a.step("2"),
        ]),
      ]),
      h.div([], [
        h.label([a.for("pen_color_input")], [h.text("Pen color")]),
        h.input([
          ev.on_input(fn(s) { UserChangedPenColor(s) }),
          a.id("pen_color_input"),
          a.name("pen_color_input"),
          a.type_("color"),
          a.value(model.pen_color),
        ]),
      ]),
    ])

  let clear_canvas_button =
    h.div([], [
      h.button([ev.on_click(UserClickedClearCanvas)], [h.text("Clear")]),
    ])

  h.div([], [title, canvas, pen_options, clear_canvas_button])
}

fn dispatch_draw() -> Effect(Msg) {
  use dispatch <- effect.from()
  dispatch(Draw)
}

fn get_canvas_context(id: String) -> Effect(Msg) {
  use dispatch <- effect.from()

  let ctx = {
    use canvas <- result.try(document_get_element_by_id(id))
    use ctx <- result.map(canvas_get_context_2d(canvas))
    ctx
  }

  case ctx {
    Ok(ctx) -> CtxReady(ctx)
    Error(msg) -> CtxError(msg)
  }
  |> SetCanvasContext
  |> dispatch
}

fn clear_canvas(
  ctx: Ctx,
  canvas_width canvas_width: Int,
  canvas_height canvas_height: Int,
) -> Effect(Msg) {
  case ctx {
    CtxReady(ctx) -> {
      use dispatch <- effect.from()

      let _ = context_clear_rect(ctx, 0, 0, canvas_width, canvas_height)

      dispatch(DoNothing)
    }
    _ -> {
      use dispatch <- effect.from()
      dispatch(DoNothing)
    }
  }
}

fn draw(ctx: Ctx, f: fn(CanvasContext) -> a) -> Effect(Msg) {
  use dispatch <- effect.from()

  case ctx {
    CtxReady(ctx) -> {
      ignore(f(ctx))

      dispatch(DoNothing)
    }
    CtxNeedsInit -> {
      dispatch(GetCanvasContext)
      // TODO this should maybe take the thing you were trying to do as an
      // argument
      dispatch(Draw)
    }
    CtxError(error) -> {
      window_alert(error)
      dispatch(DoNothing)
    }
  }
}

// fn fill_rect(
//   ctx: Ctx,
//   x x: Int,
//   y y: Int,
//   width width: Int,
//   height height: Int,
// ) -> Effect(Msg) {
//   use ctx <- draw(ctx)
//   context_fill_rect(ctx, x: x, y: y, width: width, height: height)
// }

// fn stroke_rect(
//   ctx: Ctx,
//   x x: Int,
//   y y: Int,
//   width width: Int,
//   height height: Int,
// ) -> Effect(Msg) {
//   use ctx <- draw(ctx)
//   context_stroke_rect(ctx, x: x, y: y, width: width, height: height)
// }

// fn clear_rect(
//   ctx: Ctx,
//   x x: Int,
//   y y: Int,
//   width width: Int,
//   height height: Int,
// ) -> Effect(Msg) {
//   use ctx <- draw(ctx)
//   context_clear_rect(ctx, x: x, y: y, width: width, height: height)
// }

fn pi() -> Float {
  3.14159265359
}

fn fill_circle(
  ctx: Ctx,
  x x: Float,
  y y: Float,
  r r: Int,
  color color: String,
) -> Effect(Msg) {
  use ctx <- draw(ctx)
  context_fill_style(ctx, color)
  context_begin_path(ctx)
  context_arc(ctx, x, y, r, 0.0, 2.0 *. pi(), False)
  context_fill(ctx)
}

// FFI
// 
// 

type BrowserElement

type CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "documentGetElementById")
fn document_get_element_by_id(id: String) -> Result(BrowserElement, String)

@external(javascript, "./canvas_draw_ffi.mjs", "canvasGetContext2d")
fn canvas_get_context_2d(
  canvas: BrowserElement,
) -> Result(CanvasContext, String)

fn ignore(_) -> Nil {
  Nil
}

// @external(javascript, "./canvas_draw_ffi.mjs", "contextFillRect")
// fn context_fill_rect(
//   ctx: CanvasContext,
//   x x: Int,
//   y y: Int,
//   width width: Int,
//   height height: Int,
// ) -> CanvasContext

// @external(javascript, "./canvas_draw_ffi.mjs", "contextStrokeRect")
// fn context_stroke_rect(
//   ctx: CanvasContext,
//   x x: Int,
//   y y: Int,
//   width width: Int,
//   height height: Int,
// ) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "contextClearRect")
fn context_clear_rect(
  ctx: CanvasContext,
  x x: Int,
  y y: Int,
  width width: Int,
  height height: Int,
) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "contextBeginPath")
fn context_begin_path(ctx: CanvasContext) -> CanvasContext

// @external(javascript, "./canvas_draw_ffi.mjs", "contextClosePath")
// fn context_close_path(ctx: CanvasContext) -> CanvasContext

// @external(javascript, "./canvas_draw_ffi.mjs", "contextStroke")
// fn context_stroke(ctx: CanvasContext) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "contextFill")
fn context_fill(ctx: CanvasContext) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "contextArc")
fn context_arc(
  ctx: CanvasContext,
  x: Float,
  y: Float,
  radius: Int,
  start_angle: Float,
  end_angle: Float,
  counterclockwise: Bool,
) -> CanvasContext

// @external(javascript, "./canvas_draw_ffi.mjs", "contextStrokeStyle")
// fn context_stroke_style(ctx: CanvasContext, color: String) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "contextFillStyle")
fn context_fill_style(ctx: CanvasContext, color: String) -> CanvasContext

@external(javascript, "./canvas_draw_ffi.mjs", "windowAlert")
fn window_alert(msg: String) -> Nil

@external(javascript, "./canvas_draw_ffi.mjs", "canvasMousePosition")
fn do_canvas_mouse_position(
  canvas_id: String,
  mouse_x: Float,
  mouse_y: Float,
) -> #(Float, Float)

fn canvas_mouse_position(
  canvas_id: String,
  mouse_x: Float,
  mouse_y: Float,
) -> #(Float, Float) {
  let xy = do_canvas_mouse_position(canvas_id, mouse_x, mouse_y)

  #(xy.0, xy.1)
}
