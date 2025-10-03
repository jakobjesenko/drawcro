import drawcro/element
import drawcro/parser
import drawcro/token
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

const example_svg = "<svg xmlns=\"http://www.w3.org/2000/svg\">
    <rect width=\"100\" height=\"100\" stroke=\"orange\" />
    <text x=\"30\" y=\"40\" fill=\"red\">
        abc
    </text>
</svg>"

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  parser.parse(example_svg, element.new(), [token.Svg]).1
  |> should.equal("")
}
