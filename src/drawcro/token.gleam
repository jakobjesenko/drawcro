import gleam/int

pub type TokenType {
  Fluff
  Whitespace
  Control
  Char
  Parameter
}

pub fn tt_to_string(t: TokenType) {
  case t {
    Fluff -> "fluff"
    Whitespace -> "whitespace"
    Control -> "control"
    Char -> "char"
    Parameter -> "Parameter"
  }
}

pub fn to_string(token: Token) -> String {
  "Token["
  <> token.str
  <> ", "
  <> tt_to_string(token.token_type)
  <> ", "
  <> int.to_string(token.row)
  <> ", "
  <> int.to_string(token.col)
  <> "]"
}

pub type Token {
  Token(str: String, token_type: TokenType, row: Int, col: Int)
}
