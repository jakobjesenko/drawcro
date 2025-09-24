import drawcro/token.{type Token}
import gleam/list
import gleam/string

pub type LexerState {
  Idle
  TagHead
  TagTail
  Body
  StagHead
  Utag
}

pub type Lexer {
  Lexer(
    source: String,
    tail: String,
    row: Int,
    col: Int,
    pt: Int,
    keyword_pt: Int,
    state: LexerState,
  )
}

pub fn new(source: String) -> Lexer {
  Lexer(source, source, 0, 0, 0, 0, Idle)
}

pub fn lex(lexer: Lexer) -> List(Token) {
  case lexer.tail {
    "" -> []
    _ -> {
      let temp = next(lexer)
      list.append([temp.0], lex(temp.1))
    }
  }
}

fn whitesepace_token(
  lexer: Lexer,
  next_lexer_state: LexerState,
  tail: String,
) -> #(Token, Lexer) {
  #(
    token.Token(" ", token.Whitespace, lexer.row, lexer.col),
    Lexer(
      lexer.source,
      tail,
      lexer.row,
      lexer.col + 1,
      lexer.pt + 1,
      lexer.pt + 1,
      next_lexer_state,
    ),
  )
}

fn linefeed_token(
  lexer: Lexer,
  next_lexer_state: LexerState,
  tail: String,
) -> #(Token, Lexer) {
  #(
    token.Token("\n", token.Whitespace, lexer.row, lexer.col),
    Lexer(
      lexer.source,
      tail,
      lexer.row + 1,
      0,
      lexer.pt + 1,
      lexer.pt + 1,
      next_lexer_state,
    ),
  )
}

fn next(lexer: Lexer) -> #(Token, Lexer) {
  case lexer.state {
    Idle -> {
      case lexer.tail {
        "" -> {
          #(token.Token("END", token.Control, lexer.row, lexer.col), lexer)
        }
        "<@def" <> tail -> {
          #(
            token.Token("<@def", token.Control, lexer.row, lexer.col),
            Lexer(
              lexer.source,
              tail,
              lexer.row,
              lexer.col + 5,
              lexer.pt + 5,
              lexer.pt + 5,
              StagHead,
            ),
          )
        }
        "<@" <> tail -> {
          #(
            token.Token("<@", token.Control, lexer.row, lexer.col),
            Lexer(
              lexer.source,
              tail,
              lexer.row,
              lexer.col + 2,
              lexer.pt + 2,
              lexer.pt + 2,
              Utag,
            ),
          )
        }
        "<" <> tail -> {
          #(
            token.Token("<", token.Control, lexer.row, lexer.col),
            Lexer(
              lexer.source,
              tail,
              lexer.row,
              lexer.col + 1,
              lexer.pt + 1,
              lexer.pt + 1,
              TagHead,
            ),
          )
        }
        "\n" <> tail -> linefeed_token(lexer, Idle, tail)
        _ -> {
          #(token.Token("ERROR", token.Control, lexer.row, lexer.col), lexer)
        }
      }
    }
    TagHead -> {
      case lexer.tail {
        " " <> tail | "\r" <> tail | "\t" <> tail ->
          whitesepace_token(lexer, TagHead, tail)
        "\n" <> tail -> linefeed_token(lexer, TagHead, tail)
        ">" <> tail -> #(
          token.Token(">", token.Control, lexer.row, lexer.col),
          Lexer(
            lexer.source,
            tail,
            lexer.row,
            lexer.col + 1,
            lexer.pt + 1,
            lexer.pt + 1,
            Body,
          ),
        )
        _ -> {
          case string.slice(lexer.tail, 1, 1) {
            " " | "\r" | "\t" | ">" | "\n" -> #(
              token.Token(
                string.slice(
                  lexer.source,
                  lexer.keyword_pt,
                  lexer.pt - lexer.keyword_pt + 1,
                ),
                token.Parameter,
                lexer.row,
                lexer.col - lexer.pt + lexer.keyword_pt,
              ),
              Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.pt + 1,
                TagHead,
              ),
            )
            _ ->
              next(Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.keyword_pt,
                TagHead,
              ))
          }
        }
      }
    }
    TagTail -> {
      case lexer.tail {
        ">" <> tail -> #(
          token.Token(">", token.Control, lexer.row, lexer.col),
          Lexer(
            lexer.source,
            tail,
            lexer.row,
            lexer.col + 1,
            lexer.pt + 1,
            lexer.pt + 1,
            Idle,
          ),
        )
        _ -> {
          case string.slice(lexer.tail, 1, 1) {
            ">" -> #(
              token.Token(
                string.slice(
                  lexer.source,
                  lexer.keyword_pt,
                  lexer.pt - lexer.keyword_pt + 1,
                ),
                token.Parameter,
                lexer.row,
                lexer.col - lexer.pt + lexer.keyword_pt,
              ),
              Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.pt + 1,
                TagHead,
              ),
            )
            _ ->
              next(Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.keyword_pt,
                TagHead,
              ))
          }
        }
      }
    }
    Body -> {
      case lexer.tail {
        "\n" <> tail -> linefeed_token(lexer, Body, tail)
        "</@def>" <> tail -> #(
          token.Token("</@def>", token.Control, lexer.row, lexer.col),
          Lexer(
            lexer.source,
            tail,
            lexer.row,
            lexer.col + 7,
            lexer.pt + 7,
            lexer.pt + 7,
            Idle,
          ),
        )
        "</" <> tail -> #(
          token.Token("</", token.Control, lexer.row, lexer.col),
          Lexer(
            lexer.source,
            tail,
            lexer.row,
            lexer.col + 2,
            lexer.pt + 2,
            lexer.pt + 2,
            TagTail,
          ),
        )
        _ -> {
          case string.pop_grapheme(lexer.tail) {
            Ok(c) -> #(
              token.Token(c.0, token.Char, lexer.row, lexer.col),
              Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.pt + 1,
                Body,
              ),
            )
            Error(Nil) -> #(
              token.Token("END", token.Control, lexer.row, lexer.col),
              lexer,
            )
          }
        }
      }
    }
    StagHead -> {
      case lexer.tail {
        " " <> tail | "\r" <> tail | "\t" <> tail ->
          whitesepace_token(lexer, StagHead, tail)
        "\n" <> tail -> linefeed_token(lexer, StagHead, tail)
        ">" <> tail -> #(
          token.Token(">", token.Control, lexer.row, lexer.col),
          Lexer(
            lexer.source,
            tail,
            lexer.row,
            lexer.col + 1,
            lexer.pt + 1,
            lexer.pt + 1,
            Body,
          ),
        )
        _ -> {
          case string.slice(lexer.tail, 1, 1) {
            " " | "\r" | "\t" | ">" | "\n" -> #(
              token.Token(
                string.slice(
                  lexer.source,
                  lexer.keyword_pt,
                  lexer.pt - lexer.keyword_pt + 1,
                ),
                token.Parameter,
                lexer.row,
                lexer.col - lexer.pt + lexer.keyword_pt,
              ),
              Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.pt + 1,
                StagHead,
              ),
            )
            _ ->
              next(Lexer(
                lexer.source,
                string.drop_start(lexer.tail, 1),
                lexer.row,
                lexer.col + 1,
                lexer.pt + 1,
                lexer.keyword_pt,
                TagHead,
              ))
          }
        }
      }
    }
    Utag -> {
      todo
    }
  }
}
