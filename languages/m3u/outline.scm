; Each outline entry comes from one match: its `@context` and `@name`
; captures, joined in document order. Entries nest when one `@item` range
; contains another. Zed highlights the entry whose `@item` spans the
; cursor's line, which is why variants and segments use the grammar's
; variant_stream and media_segment nodes (tag through URI line).
;
; Zed stops tracking matches after 64 in progress, which a pattern with
; three or more attribute steps exceeds on real-world lines, dropping the
; entry silently. So every pattern here matches at most one attribute, and
; multivariant tags are shown as a parent entry with one child per
; attribute. Patterns must not overlap, or an entry is listed twice.

; --- Multivariant playlists ---

; Variant stream (#EXT-X-STREAM-INF and its URI line): "BANDWIDTH=6100000",
; with children that tell SDR, HDR10, HLG and Dolby Vision variants apart,
; the rendition groups it uses, and its URI.
;
; The URI is a child rather than part of the label because Zed's outline
; panel only highlights a parent when all its children start after the
; cursor. With the attribute children on the line above, a cursor on the
; URI line needs an entry of its own.
((variant_stream
   (tag
     (tag_content
       (attribute name: (tag_word) @_name) @name))) @item
 (#eq? @_name "BANDWIDTH"))

((variant_stream
   (tag
     (tag_content
       (attribute name: (tag_word) @_name) @name @item)))
 (#any-of? @_name
   "CODECS" "SUPPLEMENTAL-CODECS" "RESOLUTION" "VIDEO-RANGE"
   "AUDIO" "SUBTITLES"))

(variant_stream
  uri: (uri) @name @item)

; I-frame stream, which carries its URI as an attribute:
; "#EXT-X-I-FRAME-STREAM-INF URI="iframe.m3u8"", with the same children
; plus BANDWIDTH.
((tag
   (tag_name) @context
   (tag_content
     (attribute name: (tag_word) @_name) @name)) @item
 (#eq? @context "#EXT-X-I-FRAME-STREAM-INF")
 (#eq? @_name "URI"))

((tag
   (tag_name) @_tag
   (tag_content
     (attribute name: (tag_word) @_name) @name @item))
 (#eq? @_tag "#EXT-X-I-FRAME-STREAM-INF")
 (#any-of? @_name
   "BANDWIDTH" "CODECS" "SUPPLEMENTAL-CODECS" "RESOLUTION" "VIDEO-RANGE"))

; Date range (ad breaks, program boundaries, interstitials):
; "#EXT-X-DATERANGE ID="ad-1"", with CLASS, dates and durations as children.
((tag
   (tag_name) @context
   (tag_content
     (attribute name: (tag_word) @_name) @name)) @item
 (#eq? @context "#EXT-X-DATERANGE")
 (#eq? @_name "ID"))

((tag
   (tag_name) @_tag
   (tag_content
     (attribute name: (tag_word) @_name) @name @item))
 (#eq? @_tag "#EXT-X-DATERANGE")
 (#any-of? @_name
   "CLASS" "START-DATE" "END-DATE" "DURATION" "PLANNED-DURATION"))

; Rendition: "TYPE=AUDIO", with its GROUP-ID and NAME as children.
; Packagers repeat the same NAME in every group, so both are needed.
((tag
   (tag_name) @_tag
   (tag_content
     (attribute name: (tag_word) @_name) @name)) @item
 (#eq? @_tag "#EXT-X-MEDIA")
 (#eq? @_name "TYPE"))

((tag
   (tag_name) @_tag
   (tag_content
     (attribute name: (tag_word) @_name) @name @item))
 (#eq? @_tag "#EXT-X-MEDIA")
 (#any-of? @_name "GROUP-ID" "NAME"))

; --- Media playlists and plain M3U ---

; Media segment (its segment tags, #EXTINF and URI line).
; Titled (music, IPTV channel) -> "Example Artist - Track"
(media_segment
  (extinf
    title: (title) @name)) @item

; Live, with a date and time -> "2026-10-01T17:52:12.8Z segment-1141087.mp4".
; Children match in order, so one pattern per side of the #EXTINF.
(media_segment
  program_date_time: (tag
    (tag_content) @context)
  (extinf
    !title)
  uri: (uri) @name) @item

(media_segment
  (extinf
    !title)
  program_date_time: (tag
    (tag_content) @context)
  uri: (uri) @name) @item

; Untitled -> "6.006 segment-001.ts"
(media_segment
  !program_date_time
  (extinf
    duration: (duration) @context
    !title)
  uri: (uri) @name) @item

(media_segment
  (extinf
    duration: (duration) @name
    !title)
  !uri) @item

; Where the key or init section changes, or a discontinuity starts. They
; apply to the following segments too, which the tree can't show, so they
; are marked where they appear, nested in the segment they open:
; "#EXT-X-KEY METHOD=AES-128", "#EXT-X-MAP URI="init.mp4"",
; "#EXT-X-DISCONTINUITY"
((tag
   (tag_name) @context
   (tag_content
     (attribute name: (tag_word) @_name) @name)) @item
 (#eq? @context "#EXT-X-KEY")
 (#eq? @_name "METHOD"))

((tag
   (tag_name) @context
   (tag_content
     (attribute name: (tag_word) @_name) @name)) @item
 (#eq? @context "#EXT-X-MAP")
 (#eq? @_name "URI"))

((tag
   (tag_name) @name) @item
 (#eq? @name "#EXT-X-DISCONTINUITY"))

; Plain M3U entry: a URI without #EXTINF
(playlist
  (uri) @name @item)

; --- IPTV sections ---

; -> "#PLAYLIST Example Channels", "#EXTGRP News"
((tag
   (tag_name) @context
   (tag_content) @name) @item
 (#any-of? @context "#PLAYLIST" "#EXTGRP"))
