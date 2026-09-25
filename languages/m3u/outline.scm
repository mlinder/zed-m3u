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

; Variant stream (#EXT-X-STREAM-INF and its URI line):
; "BANDWIDTH=6100000 dv/index.m3u8", with children that tell SDR, HDR10,
; HLG and Dolby Vision variants apart, and the rendition groups the
; variant uses.
((variant_stream
   (tag
     (tag_content
       (attribute name: (tag_word) @_name) @context))
   uri: (uri) @name) @item
 (#eq? @_name "BANDWIDTH"))

((variant_stream
   (tag
     (tag_content
       (attribute name: (tag_word) @_name) @name))
   !uri) @item
 (#eq? @_name "BANDWIDTH"))

((variant_stream
   (tag
     (tag_content
       (attribute name: (tag_word) @_name) @name @item)))
 (#any-of? @_name
   "CODECS" "SUPPLEMENTAL-CODECS" "RESOLUTION" "VIDEO-RANGE"
   "AUDIO" "SUBTITLES"))

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

; Media segment (#EXTINF, its segment tags and URI line).
; Titled (music, IPTV channel) -> "Example Artist - Track"
(media_segment
  (extinf
    title: (title) @name)) @item

; Untitled -> "6.006 segment-001.ts"
(media_segment
  (extinf
    duration: (duration) @context
    !title)
  uri: (uri) @name) @item

(media_segment
  (extinf
    duration: (duration) @name
    !title)
  !uri) @item

; Plain M3U entry: a URI without #EXTINF
(playlist
  (uri) @name @item)

; --- IPTV sections ---

; -> "#PLAYLIST Example Channels", "#EXTGRP News"
((tag
   (tag_name) @context
   (tag_content) @name) @item
 (#any-of? @context "#PLAYLIST" "#EXTGRP"))
