run:
  gleam run -m lustre/dev start

build:
  watchexec gleam build

build_production:
  gleam run -m lustre/dev build

build_site: build_production
  mkdir -p ./docs/priv/static
  cp ./index.html ./docs
  cp ./priv/static/canvas_draw.mjs ./docs/priv/static
