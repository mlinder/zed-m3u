; Scopes referenced by config.toml.

(quoted_string) @string
(comment) @comment.inclusive

; '#' starts both comments and directives; this scope removes line_comments
; so Enter after a directive doesn't prefill "# ". It covers end of line
; (newline's lookup point) but not column 0 (toggle-comment's), except on
; bare directives, which have no later node to capture.
(tag_name) @directive
(extinf "#EXTINF" @directive)
(tag [":" (tag_content)] @directive.inclusive)
(extinf [":" "," (duration) (attribute) (tag_word) (title)] @directive.inclusive)
(tag (tag_name) @directive.inclusive .)
(header) @directive.inclusive
