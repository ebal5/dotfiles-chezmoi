#!/bin/sh
# shellcheck shell=sh  # `.shellcheckrc` の shell=bash を上書きする。このスクリプトは POSIX sh なので bash 前提の指摘（SC2292 等）は当たらない
# Install herdr plugins pinned in ~/.config/herdr-plugins
#
# 完全な commit SHA で取得 → HEAD と照合 → 定義ファイルのコマンドでビルド →
# `herdr plugin link` で登録する。`herdr plugin install` を使わないのは、
# install が (1) プラグイン側の [[build]] を無条件に実行し (2) checkout を
# herdr 管理下に置いて再インストールで差し替えるため。link ならビルドは走らず、
# 監査した木がそのまま動く木になる。
#

set -eu

# このスクリプトは apply を止めない。毎 apply 走るので、ここで非ゼロ終了すると
# herdr と無関係な dotfile の更新まで恒久的に巻き込む。プラグイン1本の失敗は
# ERROR/WARNING を出して次のプラグインへ進む

DEFS="$HOME/.config/herdr-plugins"
ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-plugins"
STATE="$ROOT/.state"

[ -f "$DEFS" ] || exit 0

# 毎 apply 走るので、herdr を入れないマシンで恒久的にノイズを出さないよう黙って終わる
command -v herdr >/dev/null 2>&1 || exit 0

# herdr の CLI はソケット応答にタイムアウトを設けていない（plugin 系は
# request_value_with_timeout を使わない）。デーモンが接続だけ受けて応答しない状態だと
# apply が永久に止まるので、こちら側で頭を押さえる。打ち切りは「読めなかった」に倒れる
timeout_cmd=""
if command -v timeout >/dev/null 2>&1; then
  timeout_cmd=timeout
fi
herdr_run() {
  if [ -n "$timeout_cmd" ]; then
    "$timeout_cmd" 15 herdr "$@"
  else
    herdr "$@"
  fi
}

# ここで落ちると apply 全体が止まる。毎 apply 走るスクリプトなので、
# herdr と無関係な dotfile の更新まで恒久的に巻き込まないようにする
mkdir -p "$STATE" || {
  echo "herdr-plugins: ERROR: could not create $STATE, skipping" >&2
  exit 0
}

# jq が無いとリンク先を照合できない。herdr と jq は同じ Nix プロファイルから
# 入るので本来は起きないが、起きたときに黙って縮退しないよう一度だけ警告する
have_jq=yes
if ! command -v jq >/dev/null 2>&1; then
  have_jq=no
  echo "herdr-plugins: WARNING: jq not found, falling back to id-only checks (stale link targets will not be repaired)" >&2
fi

# レジストリは走査の前に 1 回だけ読む。プラグインごとに herdr を叩くと、
# 呼び出し回数も応答しないときの待ち時間もプラグイン数に比例して伸びる。
# 読んだ後に登録を書き換えるのは各プラグイン自身の行だけなので、
# 使い回しても他のプラグインの判定は狂わない
# shellcheck disable=SC2310 # 非ゼロは「読めなかった」の意味。直後の判定で扱う
registry=$(herdr_run plugin list --json 2>/dev/null) || registry=""
registry_ok=yes
if [ "$have_jq" = yes ]; then
  # 応答の type と plugins が配列であることまで見る。type だけ見て中身を見ないと、
  # キー名が変わった応答を「全件未登録」と読んで全部貼り直してしまう。
  # herdr はエラーを stderr に出して stdout を空にするので、失敗も同じ枝に入る
  # shellcheck disable=SC2312 # jq の非ゼロは「読めなかった」を意味する。述語として使っている
  if ! printf '%s' "$registry" |
    jq -e '(((.result? | .type?) // "") == "plugin_list")
           and ((((.result? | .plugins?) // null) | type) == "array")' >/dev/null 2>&1; then
    registry_ok=no
  fi
else
  # jq 経路と同じく形を見る。非空のゴミを「登録ゼロ」と読むと、全プラグインを
  # --disabled なしで貼り直して無効化を有効へ戻してしまう
  # shellcheck disable=SC2312 # grep の非ゼロは「読めなかった」を意味する。述語として使っている
  if ! printf '%s' "$registry" | grep -qF '"type":"plugin_list"'; then
    registry_ok=no
  fi
fi
if [ "$registry_ok" = no ]; then
  echo "herdr-plugins: WARNING: could not read the plugin registry, leaving existing registrations as they are (try: herdr plugin list --json)" >&2
fi

# 指定した id の登録を 1 行で返す。返す値:
#
#   unknown             レジストリを読めなかった。登録の有無すら分からない
#   missing             未登録
#   unverified          登録はあるが、リンク先が分からない
#   enabled <path>      登録済み。リンク先は <path>
#   disabled <path>     同上。ただしユーザーが無効化している
#
# id の有無だけを見ると、登録が残ったままリンク先が別のパスを指す状態を
# 「登録済み」と誤判定して再リンクを飛ばす（#219）。冪等性のガードが修復を
# 妨げる向きに働くので、herdr が登録しているリンク先まで持ち帰る
plugin_entry() {
  if [ "$registry_ok" = no ]; then
    echo unknown
    return 0
  fi
  if [ "$have_jq" = no ]; then
    # パスを取り出せないので id の有無だけを見る
    if printf '%s' "$registry" | grep -qF "\"plugin_id\":\"$1\""; then
      echo unverified
    else
      echo missing
    fi
    return 0
  fi
  printf '%s' "$registry" |
    jq -r --arg id "$1" '
      [.result.plugins[]? | select((.plugin_id // .id) == $id)] as $found
      | if ($found | length) == 0 then "missing"
        elif (($found[0].plugin_root // "") == "") then "unverified"
        else
          # enabled が欠けていれば null == false が偽になり「有効」側へ倒れる。
          # `// true` は使えない（jq の // は false も既定へ倒してしまう）
          (if $found[0].enabled == false then "disabled" else "enabled" end)
          + " " + $found[0].plugin_root
        end' 2>/dev/null
}

wanted=""
# linked_ids は「その行が id を主張した」印。重複定義の検出だけに使う
linked_ids=""
# verified_ids は「この実行で link した、またはリンク先が今回の checkout だと
# 確認できた」id。掃除がこれを守る。主張しただけの id を守ると、照合できな
# かった登録（jq 無し・応答の欠損）を unlink できず #219 が恒久化する
verified_ids=""
# 1行でも最後まで処理できなかったら、掃除（unlink + rm -rf）はしない。
# 全体像が取れていない状態で消すと、動いているインストールを落としかねない
incomplete=no

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "#"* | "") continue ;;
    *) ;;
  esac

  # source SHA [build...] へ分解する。ビルドコマンドに含まれる * を展開させない
  set -f
  # shellcheck disable=SC2086
  set -- $line
  set +f
  [ $# -ge 2 ] || {
    echo "herdr-plugins: WARNING: invalid line '$line', skipping" >&2
    incomplete=yes
    continue
  }
  spec="$1"
  sha="$2"
  shift 2
  build="$*"

  # SHA は 40 桁の hex のみ受け付ける。タグやブランチは可変なのでピンにならない
  case "$sha" in
    *[!0-9a-f]*)
      echo "herdr-plugins: WARNING: '$sha' is not a commit SHA, skipping $spec" >&2
      incomplete=yes
      continue
      ;;
    *) ;;
  esac
  if [ ${#sha} -ne 40 ]; then
    echo "herdr-plugins: WARNING: '$sha' is not a full 40-char SHA, skipping $spec" >&2
    incomplete=yes
    continue
  fi

  # owner/repo[/subdir]
  case "$spec" in
    */*) ;;
    *)
      echo "herdr-plugins: WARNING: '$spec' is not owner/repo, skipping" >&2
      incomplete=yes
      continue
      ;;
  esac
  owner="${spec%%/*}"
  rest="${spec#*/}"
  repo="${rest%%/*}"
  case "$rest" in
    */*) subdir="${rest#*/}" ;;
    *) subdir="" ;;
  esac

  key="${owner}_${repo}"
  dir="$ROOT/$key"
  stamp="$STATE/$key"
  wanted="$wanted $key"

  # 取得。herdr 自身と同じく shallow fetch + 明示 SHA
  if [ ! -d "$dir/.git" ]; then
    if ! (rm -rf "${dir:?}" && git init -q "$dir" &&
      git -C "$dir" remote add origin "https://github.com/$owner/$repo.git"); then
      echo "herdr-plugins: ERROR: could not initialize $dir, skipping $spec" >&2
      incomplete=yes
      continue
    fi
  fi
  head=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo "")
  if [ "$head" != "$sha" ]; then
    echo "herdr-plugins: fetching $owner/$repo @ $sha"
    if ! git -C "$dir" fetch -q --depth 1 origin "$sha"; then
      echo "herdr-plugins: ERROR: fetch failed for $spec@$sha" >&2
      incomplete=yes
      continue
    fi
    # 前バージョンのビルド成果物を残さない（node_modules, bin, target 等）
    if ! { git -C "$dir" reset -q --hard FETCH_HEAD && git -C "$dir" clean -qxdff; }; then
      echo "herdr-plugins: ERROR: could not check out $sha in $dir, skipping $spec" >&2
      incomplete=yes
      continue
    fi
  fi

  # 取得したものがピン通りかを最終確認する
  # rev-parse が失敗したら空文字となりピン不一致になる。拒否側に倒れるので安全
  # shellcheck disable=SC2312
  if [ "$(git -C "$dir" rev-parse HEAD)" != "$sha" ]; then
    echo "herdr-plugins: ERROR: $spec HEAD does not match pinned $sha, refusing" >&2
    incomplete=yes
    continue
  fi

  plugin_dir="$dir"
  [ -z "$subdir" ] || plugin_dir="$dir/$subdir"
  manifest="$plugin_dir/herdr-plugin.toml"
  if [ ! -f "$manifest" ]; then
    echo "herdr-plugins: ERROR: no herdr-plugin.toml in $plugin_dir" >&2
    incomplete=yes
    continue
  fi
  # shellcheck disable=SC2312 # sedが失敗すればidが空になり、直後の -z チェックが明示的に捕まえる
  id=$(sed -n 's/^id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)
  if [ -z "$id" ]; then
    echo "herdr-plugins: ERROR: could not read plugin id from $manifest" >&2
    incomplete=yes
    continue
  fi
  # herdr 側は id を trim して登録する（normalize_plugin_id）。揃えないと前後に
  # 空白のある id で永久に「未登録」と判定し、毎回 link し直すことになる
  # shellcheck disable=SC2312 # 空白しかなければ空文字になるが、その id は直前のチェックで既に弾かれている
  id=$(printf '%s' "$id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # herdr が受け付ける文字種（英数と : . _ -）に限る。範囲外の id は link が
  # 失敗するうえ、空白入りだと下の重複判定が空白区切りで割れて無関係な定義を巻き込む
  case "$id" in
    *[!A-Za-z0-9:._-]*)
      echo "herdr-plugins: ERROR: plugin id '$id' in $manifest has characters herdr rejects, skipping $spec" >&2
      # この id は verified_ids に入らないので、この行が引き取るはずだった
      # 旧 key の登録を掃除から守れない。掃除ごと見送る
      incomplete=yes
      continue
      ;;
    *) ;;
  esac
  if [ ${#id} -gt 120 ]; then
    echo "herdr-plugins: ERROR: plugin id in $manifest is longer than herdr allows, skipping $spec" >&2
    incomplete=yes
    continue
  fi

  # link は plugin id をキーにした upsert なので、同じ id を宣言する定義が
  # 2 行あると互いの登録を上書きし合い、毎回 relink して収束しない。
  # 先に現れた行を採り、後の行は登録に進めない
  case " $linked_ids " in
    *" $id "*)
      echo "herdr-plugins: WARNING: plugin id $id is already claimed by an earlier line, skipping $spec" >&2
      continue
      ;;
    *) ;;
  esac
  linked_ids="$linked_ids $id"

  # stamp は「この SHA でビルドを通した」印。SHA が動いたら作り直す。
  # link の成否は記録しない。毎 apply 走るので、link が通らない状態が続く間
  # ずっと `npm ci` をやり直すことになる
  done_sha=""
  done_id=""
  if [ -f "$stamp" ]; then
    read -r done_sha done_id <"$stamp" || {
      done_sha=""
      done_id=""
    }
  fi

  if [ -n "$build" ] && [ "$done_sha" != "$sha" ]; then
    echo "herdr-plugins: building $id"
    if ! (cd "$plugin_dir" && sh -c "$build"); then
      echo "herdr-plugins: ERROR: build failed for $id, not linking" >&2
      rm -f "$stamp" || true
      incomplete=yes
      continue
    fi
  fi
  # SHA を記録して次回の再ビルドを避ける。id は「旧登録を外せた」ことが確認できる
  # まで旧 id のまま残す。先に上書きすると、外し損ねた登録を辿る手がかりが消える
  stamp_id="$id"
  [ -z "$done_id" ] || stamp_id="$done_id"
  printf '%s %s\n' "$sha" "$stamp_id" >"$stamp" ||
    echo "herdr-plugins: WARNING: could not write $stamp (the next run will rebuild $id)" >&2

  # 登録済みかどうかは、リンク先が今回の checkout と同じディレクトリかで見る。
  # `-ef` は device+inode の比較なので、herdr 側の正規化（canonicalize）と
  # こちらの文字列表現が食い違っても誤判定しない。存在しないパスは偽になるため、
  # リンク先が消えた場合もそのまま「別のパス」として拾える。
  # link は plugin id をキーにした upsert なので unlink は要らないが、
  # enabled は link の引数で決まるため、無効化されている登録は --disabled で引き継ぐ
  link_note=""
  link_opts=""
  # jq がこの行を解釈できないと非ゼロで終わる。set -e に巻き込ませず、
  # 空文字として下の case で拾う
  # shellcheck disable=SC2310 # plugin_entry の非ゼロは「解釈できなかった」の意味。失敗ではない
  entry=$(plugin_entry "$id") || entry=""
  case "$entry" in
    unknown) ;; # 読めなかった。当て推量で link すると無効化を有効へ戻してしまう（警告済み）
    "")
      # レジストリ全体は読めたが、この id の行を jq が解釈できなかった
      echo "herdr-plugins: WARNING: could not read the registry entry for $id, leaving it as is" >&2
      ;;
    unverified)
      if [ "$have_jq" = yes ]; then
        echo "herdr-plugins: WARNING: herdr reported no link target for $id, leaving the registration as is" >&2
      fi
      ;;
    missing) link_note="linking $id" ;;
    *)
      registered="${entry#* }"
      if [ "$registered" -ef "$plugin_dir" ]; then
        verified_ids="$verified_ids $id"
      elif [ -L "$manifest" ]; then
        # herdr は manifest を canonicalize してその親を登録するので、実体が別の
        # ディレクトリにあると貼り直しても登録は checkout を指さない。照合すると
        # 毎 apply relink し続けることになるため、照合を諦めて現状維持に倒す
        echo "herdr-plugins: WARNING: $manifest is a symlink, cannot verify the link target for $id" >&2
      elif [ "${entry%% *}" = disabled ]; then
        link_note="relinking $id (registry points at $registered, keeping it disabled)"
        link_opts="--disabled"
      else
        link_note="relinking $id (registry points at $registered)"
      fi
      ;;
  esac
  if [ -n "$link_note" ]; then
    echo "herdr-plugins: $link_note"
    # shellcheck disable=SC2310,SC2086 # 失敗は下で扱う。link_opts は空か --disabled のみ
    if ! herdr_run plugin link "$plugin_dir" $link_opts >/dev/null; then
      echo "herdr-plugins: ERROR: link failed for $id" >&2
      incomplete=yes
      continue
    fi
    verified_ids="$verified_ids $id"
  fi

  # 上流が manifest の id を変えると、古い id の登録が checkout を指したまま残る。
  # 掃除ループが辿れるのは stamp の id だけなので、ここで外しておかないと
  # 定義から消したときに孤児になる。外すのは新しい id を登録し終えた後。
  # 先に外すと、link に失敗したときに新旧どちらの登録も無い状態になる
  if [ -n "$done_id" ] && [ "$done_id" != "$id" ]; then
    # 先の行がこの実行で link/照合した id なら、id が行をまたいで移動しただけ。
    # 外すと直前に登録したものを打ち消す（掃除ループと同じ守り）
    unlink_previous=yes
    case " $verified_ids " in
      *" $done_id "*) unlink_previous=no ;;
      *) ;;
    esac
    if [ "$unlink_previous" = no ]; then
      :
    elif [ "$registry_ok" = no ] || [ -z "$entry" ]; then
      # この id の状態を読めていない。消すのは「判定できないときは触らない」に反する
      echo "herdr-plugins: WARNING: not unlinking previous id $done_id while its state is unknown" >&2
    else
      echo "herdr-plugins: unlinking previous id $done_id (now $id)"
      # shellcheck disable=SC2310 # 失敗は下で扱う。外せなければ stamp を進めず次回やり直す
      if herdr_run plugin unlink "$done_id" >/dev/null 2>&1; then
        printf '%s %s\n' "$sha" "$id" >"$stamp" ||
          echo "herdr-plugins: WARNING: could not write $stamp" >&2
      else
        # 外せないまま定義行ごと消されると、新 id の登録は掃除から辿れなくなる。
        # stamp が持てる id は1つなので、そこは受け入れる
        echo "herdr-plugins: WARNING: could not unlink previous id $done_id" >&2
      fi
    fi
  fi
done <"$DEFS"

# 定義から消えたプラグインを登録解除して checkout ごと削除する。
# checkout と stamp の両方を候補にする（ビルド失敗で stamp の無い checkout が
# 残っている場合や、逆に checkout だけ手で消された場合を取りこぼさない）
stale=""
for path in "$ROOT"/* "$STATE"/*; do
  [ -e "$path" ] || continue
  key=$(basename "$path")
  case " $wanted $stale " in
    *" $key "*) continue ;;
    *) ;;
  esac
  stale="$stale $key"
done

if [ -n "$stale" ] && { [ "$incomplete" = yes ] || [ "$registry_ok" = no ]; }; then
  echo "herdr-plugins: WARNING: not removing anything while the state is incomplete; removals stay unapplied until the errors above are resolved" >&2
  stale=""
fi

# shellcheck disable=SC2086
for key in $stale; do
  stamp="$STATE/$key"
  # stamp はビルドを通した時点で書かれる。link していない id が入っていることも
  # あるが、その unlink は removed:false が返るだけで害はない
  if [ -f "$stamp" ]; then
    read -r _ id <"$stamp" || id=""
    # 定義行の key が変わっただけ（owner の改名など）だと、同じ id を今この実行で
    # link し直している。checkout は消してよいが、登録を外すと今 link したものが
    # 消える。逆に、照合できなかった id まで守ると死んだ登録が残るので、守るのは
    # 「link した／リンク先を確認できた」id だけにする
    case " $verified_ids " in
      *" $id "*) id="" ;;
      *) ;;
    esac
    if [ -n "$id" ]; then
      echo "herdr-plugins: unlinking removed plugin $id"
      # shellcheck disable=SC2310 # 失敗しても checkout の削除は続ける
      herdr_run plugin unlink "$id" >/dev/null 2>&1 || true
    fi
  fi
  echo "herdr-plugins: removing $key"
  rm -rf "${ROOT:?}/${key:?}" "$stamp" ||
    echo "herdr-plugins: WARNING: could not remove $key" >&2
done
