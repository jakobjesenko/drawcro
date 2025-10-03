$$
\begin{align*}
    Svg \to& [Whitespace][LeftA][SvgLit][Params][Whitespace][RightA]\\
    & [Body]\\
    & [Whitespace][Closing][SvgLit][RightA][Whitespace]\\
    LeftA \to & \text{"<"} \\
    RightA \to & \text{">"} \\
    SvgLit \to & \text{"svg"} \\
    Whitespace \to & \epsilon \space | \space [Space][Whitespace] \\
    Space \to & \text{" "} \space | \space "\backslash\text{t}" \space | \space "\backslash\text{n}" \space | \space "\backslash\text{r}\backslash\text{n}" \\
    Params \to & \epsilon \space | \space [Space][Param][Params] \\
    Param \to & [ParamLit]="\text{Expr}" \\
    Body \to &  [InnerText] \space | \space [Whitespace][Tag][Body] \\
    Tag \to & [LeftA][TagLit][Params][Whitespace][RightA]\\
    & [Body]\\
    & [Whitespace][Closing][TagLit][RightA]\\
    & \space | \space [LeftA][TagLit][Params][Whitespace][SelfClosing] \\
    Closing \to & \text{"</"} \\
    SelfClosing \to & \text{"/>"} \\
    InnerText \to & \epsilon \space | \space \text{"content"}
\end{align*}
$$