import drawcro/element
import drawcro/parser
import drawcro/token
import gleam/dict

import gleam/yielder
import stdin

pub fn main() -> Nil {
  let _syntax_tree =
    stdin.read_lines()
    |> yielder.fold("", fn(a, b) { a <> b })
    |> parser.parse(element.Element("", dict.new(), []), [token.Svg])
    |> echo

  Nil
}
