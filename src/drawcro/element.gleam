import gleam/dict
import gleam/list

pub type ElementType {
  Svg
  Params
  Param
  Body
  Tag
  LeftA
  RightA
  SvgLit
  ClosingTag
  TagLit
  SelfClose
}

pub type Element {
  Element(
    tag_name: String,
    parameters: dict.Dict(String, String),
    children: List(Element),
  )
}

pub fn new() -> Element {
  Element("", dict.new(), [])
}

pub fn set_name(element: Element, name: String) {
  Element(name, element.parameters, element.children)
}

pub fn add_parameter(element: Element, key: String, value: String) -> Element {
  Element(
    element.tag_name,
    dict.insert(element.parameters, key, value),
    element.children,
  )
}

pub fn add_child(element: Element, child: Element) -> Element {
  Element(
    element.tag_name,
    element.parameters,
    list.append(element.children, [child]),
  )
}
