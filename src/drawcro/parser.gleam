import drawcro/element
import drawcro/token.{type TokenType}
import gleam/dict
import gleam/io
import gleam/list
import gleam/string

pub type Parser {
  Parser
}

/// for string \f$c_0c_1c_2...c_n\f$ find substring \f$c_ic_{i+1}c_{i+2}...c_n\f$ where  
/// \f$ decider(c_ic_{i+1}c_{i+2}...c_n) = True \f$
fn find(str: String, decider: fn(String) -> Bool) -> String {
  case str {
    "" -> ""
    _ ->
      case decider(str) {
        True -> str
        False -> find(string.drop_start(str, 1), decider)
      }
  }
}

/// for string \f$c_0c_1c_2...c_n\f$ find substring \f$c_0c_1c_2...c_{i-1}\f$ where  
/// \f$ decider(c_ic_{i+1}c_{i+2}...c_n) = True \f$
fn before(str: String, decider: fn(String) -> Bool) -> String {
  case str {
    "" -> ""
    _ ->
      case decider(str) {
        True -> ""
        False ->
          string.slice(str, 0, 1) <> before(string.drop_start(str, 1), decider)
      }
  }
}

pub fn parse(
  source: String,
  syntax_tree: element.Element,
  grammar_stack: List(TokenType),
) -> #(element.Element, String) {
  let _ingore = syntax_tree |> echo
  io.println("\n\u{00001b}[36m" <> source <> "\u{00001b}[0m")
  case grammar_stack |> echo {
    [] -> #(syntax_tree, source)
    [token.Svg] ->
      parse(source, element.Element("svg", dict.new(), []), [
        token.Whitespace,
        token.LeftA,
        token.SvgLit,
        token.Params,
        token.Whitespace,
        token.RightA,
        token.Body,
        token.Whitespace,
        token.Closing,
        token.SvgLit,
        token.RightA,
        token.Whitespace,
      ])
    [token.LeftA, ..] ->
      case source {
        "<" <> tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.SvgLit, ..] ->
      case source {
        "svg" <> tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.Params, ..] ->
      case source {
        ">" <> _ | " />" <> _ ->
          parse(source, syntax_tree, list.drop(grammar_stack, 1))
        _ ->
          parse(source, syntax_tree, [token.Space, token.Param, ..grammar_stack])
      }
    [token.Whitespace, ..] ->
      case source {
        " " <> _ | "\t" <> _ | "\n" <> _ | "\r\n" <> _ ->
          parse(source, syntax_tree, list.prepend(grammar_stack, token.Space))
        tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
      }
    [token.Space, ..] ->
      case source {
        " " <> tail | "\t" <> tail | "\n" <> tail | "\r\n" <> tail ->
          parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.RightA, ..] ->
      case source {
        ">" <> tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.Body, ..] ->
      case source {
        "</" <> _ -> {
          parse(source, syntax_tree, list.drop(grammar_stack, 1))
        }
        _ ->
          case
            find(source, fn(str) {
              case str {
                " " <> _ | "\t" <> _ | "\n" <> _ | "\r\n" <> _ -> False
                _ -> True
              }
            })
          {
            "</" <> _ -> {
              parse(source, syntax_tree, [
                token.Whitespace,
                ..list.drop(grammar_stack, 1)
              ])
            }
            "<" <> _ ->
              parse(source, syntax_tree, [
                token.Whitespace,
                token.Tag,
                ..grammar_stack
              ])
            _ -> parse(source, syntax_tree, [token.InnerText, ..grammar_stack])
          }
      }
    [token.Closing, ..] ->
      case source {
        "</" <> tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.SelfClosing, ..] ->
      case source {
        "/>" <> tail -> parse(tail, syntax_tree, list.drop(grammar_stack, 1))
        _ -> panic
      }
    [token.Tag, ..] -> {
      let child = case
        find(source, fn(str) {
          case str {
            "/>" <> _ | ">" <> _ -> True
            _ -> False
          }
        })
      {
        "/>" <> _ ->
          parse(source, element.new(), [
            token.LeftA,
            token.TagLit,
            token.Params,
            token.Whitespace,
            token.SelfClosing,
          ])
        ">" <> _ ->
          parse(source, element.new(), [
            token.LeftA,
            token.TagLit,
            token.Params,
            token.Whitespace,
            token.RightA,
            token.Body,
            token.Whitespace,
            token.Closing,
            token.TagLit,
            token.RightA,
          ])
        _ -> panic
      }
      parse(
        child.1,
        element.add_child(syntax_tree, child.0),
        list.drop(grammar_stack, 1),
      )
    }
    [token.Param, ..] ->
      before(source, fn(str) {
        case str {
          " " <> _ | "\t" <> _ | "\n" <> _ | "\r\n" <> _ | ">" <> _ | "/>" <> _ ->
            True
          _ -> False
        }
      })
      |> fn(str) {
        case string.split_once(str, "=") |> echo {
          Ok(par) ->
            parse(
              find(source, fn(str) {
                case str {
                  " " <> _
                  | "\t" <> _
                  | "\n" <> _
                  | "\r\n" <> _
                  | ">" <> _
                  | "/>" <> _ -> True
                  _ -> False
                }
              }),
              element.add_parameter(syntax_tree, par.0, par.1),
              list.drop(grammar_stack, 1),
            )
          Error(_) ->
            parse(string.drop_start(source, 1), syntax_tree, grammar_stack)
        }
      }
    [token.TagLit, ..] ->
      case source {
        "circle" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "circle"),
            list.drop(grammar_stack, 1),
          )
        "rect" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "rect"),
            list.drop(grammar_stack, 1),
          )
        "elipse" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "elipse"),
            list.drop(grammar_stack, 1),
          )
        "image" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "image"),
            list.drop(grammar_stack, 1),
          )
        "path" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "path"),
            list.drop(grammar_stack, 1),
          )
        "text" <> tail ->
          parse(
            tail,
            element.set_name(syntax_tree, "text"),
            list.drop(grammar_stack, 1),
          )
        _ -> panic
      }
    [token.InnerText, ..] -> {
      let substring =
        before(source, fn(str) {
          case str {
            "</" <> _ -> True
            _ -> False
          }
        })
        |> echo
      let full_length = string.length(source)
      let sub_length = string.length(substring)
      parse(
        string.slice(source, sub_length, full_length),
        element.add_child(
          syntax_tree,
          element.Element(substring, dict.new(), []),
        ),
        list.drop(grammar_stack, 1),
      )
    }
    _ -> panic
  }
}
