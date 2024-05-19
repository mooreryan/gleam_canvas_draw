import { Ok, Error } from "./gleam.mjs";

export function documentGetElementById(id) {
  let el = document.getElementById(id);

  return el === null ? new Error(`no element with id ${id}`) : new Ok(el);
}

export function canvasGetContext2d(canvas) {
  if (canvas.getContext) {
    let ctx = canvas.getContext("2d");
    return new Ok(ctx);
  } else {
    return new Error("canvas is not supported");
  }
}

export function contextFillRect(ctx, x, y, width, height) {
  requestAnimationFrame(() => {
    ctx.fillRect(x, y, width, height);
  })

  return ctx;
}

export function contextStrokeRect(ctx, x, y, width, height) {
  requestAnimationFrame(() => {
    ctx.strokeRect(x, y, width, height);
  });

  return ctx;
}

export function contextClearRect(ctx, x, y, width, height) {
  requestAnimationFrame(() => {
    ctx.clearRect(x, y, width, height);
  });

  return ctx;
}

export function windowAlert(msg) {
  window.alert(msg)
}

export function contextBeginPath(ctx) {
  requestAnimationFrame(() => {
    ctx.beginPath();
  });

  return ctx;
}

export function contextClosePath(ctx) {
  requestAnimationFrame(() => {
    ctx.closePath();
  });

  return ctx;
}

export function contextStroke(ctx) {
  requestAnimationFrame(() => {
    ctx.stroke();
  });

  return ctx;
}

export function contextFill(ctx) {
  requestAnimationFrame(() => {
    ctx.fill();
  });

  return ctx;
}


export function contextArc(ctx, x, y, radius, startAngle, endAngle, counterclockwise) {
  requestAnimationFrame(() => {
    ctx.arc(x, y, radius, startAngle, endAngle, counterclockwise);
  });

  return ctx;
}

export function contextStrokeStyle(ctx, color) {
  requestAnimationFrame(() => {
    ctx.strokeStyle = color;
  })

  return ctx;
}

export function contextFillStyle(ctx, color) {
  requestAnimationFrame(() => {
    ctx.fillStyle = color;
  })

  return ctx;
}

function canvasScale(canvasWidth, canvasHeight, rectWidth, rectHeight) {
  let scaleX = canvasWidth / rectWidth;
  let scaleY = canvasHeight / rectHeight;

  return { scaleX, scaleY };
}

export function canvasMousePosition(canvasId, mouseX, mouseY) {
  let canvas = document.getElementById(canvasId);
  let rect = canvas.getBoundingClientRect();
  let scale = canvasScale(canvas.width, canvas.height, rect.width, rect.height);

  let x = (mouseX - rect.x) * scale.scaleX;
  let y = (mouseY - rect.y) * scale.scaleY;

  return [x, y];
}

