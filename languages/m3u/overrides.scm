; Scopes referenced by config.toml. Zed uses the smallest one containing the
; cursor (Enter) or the start of the line (cmd-/).

(quoted_string) @string
(comment) @comment.inclusive

; Whole directive lines, inclusive so that both column 0 and end of line
; count as inside.
[
  (header)
  (tag)
  (extinf)
] @directive.inclusive
