import drawcro/lexer
import drawcro/token.{type Token}
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder
import stdin

pub fn main() -> Nil {
  let tokens =
    stdin.read_lines()
    |> yielder.fold("", fn(a, b) { a <> b })
    |> lexer.new
    |> lexer.lex

  tokens
  |> list.fold("", fn(a, b) { a <> token.to_string(b) <> "\n" })
  |> io.println

  tokens |> reasemble |> io.println
}

fn reasemble(tokens: List(Token)) -> String {
  string.join(list.map(tokens, fn(t) { t.str }), "")
}
