# Colour Unicode block or braille art with the Omarchy gradient, column by
# column, so the wordmark carries the gradient rather than one flat colour.
#
#   -v tc=1   emit 24-bit truecolor; anything else uses the 256-colour cube
#   -v pad=N  pad every line out to N columns (for side-by-side layouts)
#
# Each block glyph is three bytes in UTF-8. gawk under a UTF-8 locale counts
# characters, BSD awk counts bytes, so measure one glyph up front and step by
# that width. Without this, substr() slices a glyph into thirds and the art
# comes out as mojibake, and a width check over-reports by 3x.
function lerp(a, b, t) { return int(a + (b-a)*t + 0.5) }
function q(v)          { return int(v*5/255 + 0.5) }
function paint(t,   u, r, g, b) {
  if (t > 1) t = 1; if (t < 0) t = 0
  if (t < 0.5) { u = t/0.5;       r=lerp(255,199,u); g=lerp( 95,125,u); b=lerp(191,245,u) }
  else         { u = (t-0.5)/0.5; r=lerp(199,127,u); g=lerp(125,184,u); b=lerp(245,255,u) }
  if (tc == "1") return sprintf("\033[38;2;%d;%d;%dm", r, g, b)
  return sprintf("\033[38;5;%dm", 16 + 36*q(r) + 6*q(g) + q(b))
}
BEGIN { gw = length("█") }
{
  line[NR] = $0
  n = length($0); i = 1; col = 0
  while (i <= n) { if (substr($0, i, 1) == " ") i += 1; else i += gw; col++ }
  cols[NR] = col
  if (col > w) w = col
}
END {
  for (ln = 1; ln <= NR; ln++) {
    s = line[ln]; n = length(s); i = 1; col = 0; out = ""
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == " ") { out = out c; i += 1; col++; continue }
      g = substr(s, i, gw); i += gw
      out = out paint((w > 1) ? col/(w-1) : 0) g
      col++
    }
    out = out "\033[0m"
    if (pad > 0) { for (k = cols[ln]; k < pad; k++) out = out " " }
    print out
  }
}
