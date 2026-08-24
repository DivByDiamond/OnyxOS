#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/docs"
TITLE="SlipperOS Documentation"

CSS=$(cat <<'CSS'
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d1117;color:#e6edf3;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;display:flex;min-height:100vh}
nav{width:260px;min-width:260px;background:#161b22;padding:16px;overflow-y:auto;border-right:1px solid #30363d;height:100vh;position:sticky;top:0}
nav h2{font-size:14px;color:#8b949e;text-transform:uppercase;letter-spacing:1px;margin-bottom:12px}
nav ul{list-style:none;margin:0;padding:0}
nav li{margin:0}
nav a{color:#58a6ff;text-decoration:none;font-size:13px;display:block;padding:3px 8px;border-radius:6px;line-height:1.6}
nav a:hover{background:#1f2937;color:#f0f6fc}
nav a.active{background:#1f6feb33;color:#f0f6fc;font-weight:600}
nav .dir{color:#8b949e;font-size:11px;padding:8px 8px 2px;font-weight:700;text-transform:uppercase;letter-spacing:0.8px;margin-top:4px}
nav .dir:first-child{margin-top:0}
nav .home{margin-bottom:8px;border-bottom:1px solid #30363d;padding-bottom:6px}
nav .home a{font-weight:600;font-size:14px}
nav .home a::before{content:"\2302  ";color:#8b949e}
.lang-switch{text-align:center;margin:12px 0;padding:8px;border-top:1px solid #30363d;border-bottom:1px solid #30363d}
.lang-switch a{display:inline-block;padding:4px 12px;border-radius:6px;font-size:13px;font-weight:600;text-decoration:none;color:#8b949e;border:1px solid #30363d}
.lang-switch a:hover{background:#1f6feb33;color:#f0f6fc;border-color:#58a6ff}
.lang-switch a.active{background:#1f6feb33;color:#f0f6fc;border-color:#58a6ff}
main{flex:1;padding:40px;max-width:960px;line-height:1.7;overflow-y:auto}
main h1{font-size:32px;border-bottom:1px solid #30363d;padding-bottom:8px;margin-bottom:16px}
main h2{font-size:24px;margin-top:24px;margin-bottom:8px}
main h3{font-size:20px;margin-top:20px;margin-bottom:6px}
main h4{font-size:16px;margin-top:16px;margin-bottom:6px}
main p,main li{font-size:16px;color:#e6edf3;margin-bottom:8px}
main a{color:#58a6ff}
main code{background:#161b22;padding:2px 6px;border-radius:4px;font-size:14px;font-family:"JetBrains Mono","Fira Code",monospace;color:#f0f6fc}
main pre{background:#161b22;padding:16px;border-radius:8px;overflow-x:auto;margin:16px 0;border:1px solid #30363d}
main pre code{background:none;padding:0;font-size:13px;line-height:1.5}
main hr{border:none;border-top:1px solid #30363d;margin:24px 0}
main blockquote{border-left:4px solid #30363d;padding-left:16px;color:#8b949e;margin:16px 0}
main table{border-collapse:collapse;margin:16px 0;width:100%}
main th,main td{border:1px solid #30363d;padding:8px 12px;text-align:left;font-size:14px}
main th{background:#161b22;color:#8b949e;font-weight:600;text-transform:uppercase;letter-spacing:0.5px}
main tr:nth-child(even){background:#161b22}
main ul,main ol{padding-left:24px;margin-bottom:8px}
main li{margin-bottom:4px}
.breadcrumb{font-size:14px;color:#8b949e;margin-bottom:24px;padding:8px 12px;background:#161b22;border-radius:8px;border:1px solid #30363d}
.breadcrumb a{color:#58a6ff;text-decoration:none}
.breadcrumb span{color:#8b949e}
::-webkit-scrollbar{width:8px}::-webkit-scrollbar-track{background:#0d1117}::-webkit-scrollbar-thumb{background:#30363d;border-radius:4px}
CSS
)

label_of() {
  local name="$1"
  name="${name##*/}"; name="${name%.md}"
  name="${name%.en}"
  name="$(echo "$name" | sed 's/_/ /g; s/-/ /g; s/\b\(.\)/\u\1/g')"
  echo "$name"
}

relpath() {
  local src="${1%.md}" tgt="${2%.md}"
  local src_dir="${src%/*}"; [[ "$src_dir" == "$src" ]] && src_dir=""
  local OIFS="$IFS"; IFS=/; set -- $src_dir; local sa=("$@")
  set -- $tgt; local ta=("$@"); IFS="$OIFS"
  local i=0
  while [[ $i -lt ${#sa[@]} && $i -lt ${#ta[@]} && "${sa[$i]}" == "${ta[$i]}" ]]; do
    ((i++))
  done
  local result=""
  for ((j=i; j<${#sa[@]}; j++)); do result="../${result}"; done
  for ((j=i; j<${#ta[@]}; j++)); do
    result="${result}${ta[$j]}"
    [[ $j -lt $(( ${#ta[@]} - 1 )) ]] && result="${result}/"
  done
  echo "${result:-.}"
}

md_to_html() {
  local file="$1"
  sed 's/—/-/g' "$file" | awk '
    function md_inline(s) {
      gsub(/`[^`]+`/, "<code>&</code>", s)
      gsub(/\*\*[^*]+\*\*/, "<strong>&</strong>", s)
      gsub(/\*[^*]+\*/, "<em>&</em>", s)
      while (match(s, /\[[^\]]+\]\([^)]+\)/)) {
        m = substr(s, RSTART, RLENGTH)
        split(m, a, /\]\(/)
        text = substr(a[1], 2)
        url = substr(a[2], 1, length(a[2]) - 1)
        t = "<a href=\"" url "\">" text "</a>"
        s = substr(s, 1, RSTART - 1) t substr(s, RSTART + RLENGTH)
      }
      return s
    }
    function cl(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

    /^\|/ {
      line = $0
      gsub(/^[ \t]*\|[ \t]*|[ \t]*\|[ \t]*$/, "", line)
      n = split(line, c, "|")
      for (i = 1; i <= n; i++) c[i] = md_inline(cl(c[i]))

      sep = 1
      for (i = 1; i <= n; i++) if (c[i] !~ /^[-: ]+$/) { sep = 0; break }

      if (!in_tbl) {
        if (sep) { print; next }
        in_tbl = 1; phase = 0
        for (i = 1; i <= n; i++) h[i] = c[i]; hn = n
        next
      }

      if (sep) {
        phase = 1
        printf "<table><thead><tr>"
        for (i = 1; i <= hn; i++) printf "<th>%s</th>", h[i]
        print "</tr></thead><tbody>"
        next
      }

      printf "<tr>"
      for (i = 1; i <= n; i++) printf "<td>%s</td>", c[i]
      print "</tr>"
      next
    }

    {
      if (in_tbl) {
        if (phase < 1) {
          printf "<table><tr>"
          for (i = 1; i <= hn; i++) printf "<td>%s</td>", h[i]
          print "</tr>"
        }
        print "</tbody></table>"
        in_tbl = 0
      }
      print
    }

    END { if (in_tbl) {
      if (phase < 1) {
        printf "<table><tr>"
        for (i = 1; i <= hn; i++) printf "<td>%s</td>", h[i]
        print "</tr>"
      }
      print "</tbody></table>"
    } }
  ' | cmark --unsafe
}

build_sidebar() {
  local active_base="$1"
  local lang="$2"

  local suffix="" find_pat="*.md" exclude="*.en.md" out_ext=".html"
  local home_href="$(relpath "$active_base" "")"
  [[ "$home_href" == "." ]] && home_href="."
  local home_cls=""
  [[ -z "$active_base" || "$active_base" == "README" ]] && home_cls=' class="active"'
  local result="<li class=\"home\"><a href=\"${home_href}\"${home_cls}>Home</a></li>"

  if [[ "$lang" == "en" ]]; then
    suffix=".en"
    find_pat="*.en.md"
    out_ext=".en.html"
  fi

  local current_tld="" current_sub=""
  while IFS= read -r -d '' f; do
    local rel="${f#$ROOT/}"
    local base="${rel%.md}"
    if [[ "$lang" == "ru" ]]; then
      base="${base}"  # strip .md already
    else
      base="${base%.en}"  # strip .en suffix
    fi
    [[ "$base" == "README" ]] && continue

    local parts="${rel%/*}"
    [[ "$parts" == "$rel" ]] && parts=""

    local tld="${parts%%/*}"
    local sub="${parts#*/}"
    [[ "$sub" == "$tld" ]] && sub=""

    if [[ "$tld" != "$current_tld" ]]; then
      current_tld="$tld"; current_sub=""
      local dir_label="$(label_of "$tld")"
      result="$result<div class=\"dir\">${dir_label}</div>"
    fi

    local indent=""
    if [[ -n "$sub" ]]; then
      current_sub="$sub"
      indent="&nbsp;&nbsp;"
    fi
    if [[ "$rel" =~ / && -n "${rel%/*}" ]]; then
      local depth="${rel//[^\/]}"
      indent=""
      for ((i=0; i<${#depth}; i++)); do indent="${indent}&nbsp;&nbsp;"; done
    fi

    local name="$(label_of "$base")"
    local href="$(relpath "$active_base" "$base")${out_ext}"
    local cls=""
    [[ "$base" == "$active_base" ]] && cls=' class="active"'
    result="$result<li><a href=\"${href}\"${cls}>${indent}${name}</a></li>"
  done < <(if [[ "$lang" == "en" ]]; then
    find "$ROOT" -name "$find_pat" -print0 | sort -z
  else
    find "$ROOT" -name "$find_pat" ! -name "$exclude" -print0 | sort -z
  fi)

  echo "$result"
}

build_lang_switch() {
  local active_base="$1"
  local current_lang="$2"

  local ru_href en_href
  if [[ -z "$active_base" ]]; then
    ru_href="index.html"
    en_href="index.en.html"
  else
    ru_href="$(relpath "$active_base" "$active_base").html"
    en_href="$(relpath "$active_base" "$active_base").en.html"
  fi

  local ru_cls="" en_cls=""
  if [[ "$current_lang" == "ru" ]]; then
    ru_cls=' class="active"'
  else
    en_cls=' class="active"'
  fi

  cat <<EOF
<div class="lang-switch">
  <a href="${ru_href}"${ru_cls}>RU</a>
  <a href="${en_href}"${en_cls}>EN</a>
</div>
EOF
}

build_breadcrumb() {
  local rel="$1"
  local parts=""
  local saved_ifs="$IFS"; IFS=/; read -ra segs <<< "$rel"; IFS="$saved_ifs"
  for seg in "${segs[@]}"; do
    local label="$(label_of "$seg")"
    parts="$parts / ${label}"
  done
  local home="$(relpath "${rel}" "")"
  [[ "$home" == "." ]] && home="."
  echo '<div class="breadcrumb"><a href="'"${home}"'">Docs</a> <span>'"${parts}"'</span></div>'
}

wrap_page() {
  local title="$1" sidebar="$2" breadcrumb="$3" content="$4" lang_switch="$5"
  cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<style>${CSS}</style>
</head>
<body>
<nav><h2>SlipperOS Docs</h2><ul>${sidebar}</ul>${lang_switch}</nav>
<main>${breadcrumb}${content}</main>
</body>
</html>
EOF
}

echo "Generating docs..."

find "$ROOT" -name '*.html' ! -name 'index.html' ! -name 'index.en.html' -delete

# ---- RU pass (.md → .html) ----
echo "--- Russian ---"
declare -a RU_ENTRIES=()
while IFS= read -r -d '' e; do
  RU_ENTRIES+=("${e#$ROOT/}")
done < <(find "$ROOT" -name '*.md' ! -name '*.en.md' -print0 | sort -z)

for rel in "${RU_ENTRIES[@]}"; do
  md="$ROOT/$rel"
  base="${rel%.md}"
  name="$(label_of "$base")"
  content="$(md_to_html "$md")"
  sidebar="$(build_sidebar "$base" "ru")"
  lang_switch="$(build_lang_switch "$base" "ru")"
  breadcrumb="$(build_breadcrumb "$base")"
  html="$(wrap_page "SlipperOS - ${name}" "$sidebar" "$breadcrumb" "$content" "$lang_switch")"
  out="${md%.md}.html"
  echo "$html" > "$out"
  echo "  ${rel} -> ${rel%.md}.html"
done

# ---- EN pass (.en.md → .en.html) ----
echo "--- English ---"
declare -a EN_ENTRIES=()
while IFS= read -r -d '' e; do
  EN_ENTRIES+=("${e#$ROOT/}")
done < <(find "$ROOT" -name '*.en.md' -print0 | sort -z)

for rel in "${EN_ENTRIES[@]}"; do
  md="$ROOT/$rel"
  base="${rel%.en.md}"
  name="$(label_of "$base")"
  content="$(md_to_html "$md")"
  sidebar="$(build_sidebar "$base" "en")"
  lang_switch="$(build_lang_switch "$base" "en")"
  breadcrumb="$(build_breadcrumb "$base")"
  html="$(wrap_page "SlipperOS - ${name}" "$sidebar" "$breadcrumb" "$content" "$lang_switch")"
  out="${md%.en.md}.en.html"
  echo "$html" > "$out"
  echo "  ${rel} -> ${rel%.en.md}.en.html"
done

# ---- index (RU) ----
readme_content="$(md_to_html "$SCRIPT_DIR/README.md")"
readme_content="$(echo "$readme_content" | sed 's|href="LICENSE"|href="../LICENSE"|g')"
readme_content="$(echo "$readme_content" | sed 's|href="docs/|href="|g')"
idx_sidebar="$(build_sidebar "" "ru")"
idx_lang_switch="$(build_lang_switch "" "ru")"
idx_html="$(wrap_page "$TITLE" "$idx_sidebar" "" "$readme_content" "$idx_lang_switch")"
echo "$idx_html" > "$ROOT/index.html"
echo "  index.html"

# ---- index (EN) ----
if [[ -f "$SCRIPT_DIR/README.en.md" ]]; then
  readme_en_content="$(md_to_html "$SCRIPT_DIR/README.en.md")"
  readme_en_content="$(echo "$readme_en_content" | sed 's|href="LICENSE"|href="../LICENSE"|g')"
  readme_en_content="$(echo "$readme_en_content" | sed 's|href="docs/|href="|g')"
  idx_en_sidebar="$(build_sidebar "" "en")"
  idx_en_lang_switch="$(build_lang_switch "" "en")"
  idx_en_html="$(wrap_page "$TITLE" "$idx_en_sidebar" "" "$readme_en_content" "$idx_en_lang_switch")"
  echo "$idx_en_html" > "$ROOT/index.en.html"
  echo "  index.en.html"
fi

echo ""
echo "Done. ${#RU_ENTRIES[@]} RU pages + ${#EN_ENTRIES[@]} EN pages + index.html + index.en.html"
