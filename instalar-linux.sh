#!/bin/sh
# ============================================================================
#  Computer Optimization - instalacao automatica para Linux
#  Uso (um comando so):
#    curl -fsSL https://raw.githubusercontent.com/ThomasFarss/computer-optimization-linux/main/instalar-linux.sh | sh
#  Faz: instala dependencias (Arch/CachyOS, Debian, Fedora, openSUSE) -> baixa o instalador
#       -> confere o SHA-256 -> instala -> liga a inicializacao automatica -> abre o programa.
#  Nao precisa de root para o programa; so pede a senha se faltar python/tk/xwayland-satellite.
# ============================================================================
REPO="ThomasFarss/computer-optimization-linux"
BRANCH="main"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
RUN_NAME="Instalador-ComputerOptimization-Linux.run"
SLUG="computer-optimization"
BIN="$HOME/.local/bin/$SLUG"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/$SLUG/last-run.log"

say()  { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
die()  { printf 'X %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Rode como usuario normal (sem sudo): o programa e instalado na sua conta."

SUDO=""; command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# ---------------------------------------------------------------- dependencias
step "Conferindo dependencias"
have_tk() { command -v python3 >/dev/null 2>&1 && python3 -c 'import tkinter' >/dev/null 2>&1; }
need_pkgs=""
if command -v pacman >/dev/null 2>&1; then
  have_tk || need_pkgs="$need_pkgs python tk"
  command -v curl >/dev/null 2>&1 || need_pkgs="$need_pkgs curl"
  PM_INSTALL="pacman -S --needed --noconfirm"
elif command -v apt-get >/dev/null 2>&1; then
  have_tk || need_pkgs="$need_pkgs python3 python3-tk"
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || need_pkgs="$need_pkgs curl"
  PM_INSTALL="apt-get install -y"
elif command -v dnf >/dev/null 2>&1; then
  have_tk || need_pkgs="$need_pkgs python3 python3-tkinter"
  PM_INSTALL="dnf install -y"
elif command -v zypper >/dev/null 2>&1; then
  have_tk || need_pkgs="$need_pkgs python3 python3-tk"
  PM_INSTALL="zypper install -y"
fi

# niri nao tem XWayland embutido: o tkinter precisa do xwayland-satellite para abrir janelas
case "$(printf '%s' "${XDG_CURRENT_DESKTOP:-}${XDG_SESSION_DESKTOP:-}" | tr 'A-Z' 'a-z')" in
  *niri*) command -v xwayland-satellite >/dev/null 2>&1 || { command -v pacman >/dev/null 2>&1 && need_pkgs="$need_pkgs xwayland-satellite"; } ;;
esac

if [ -n "$need_pkgs" ]; then
  say "Vou instalar:$need_pkgs  (pode pedir sua senha)"
  [ -n "$SUDO" ] || die "sudo nao encontrado. Instale como administrador:$need_pkgs"
  # shellcheck disable=SC2086
  $SUDO $PM_INSTALL $need_pkgs || die "Falha ao instalar:$need_pkgs"
fi
have_tk || die "Python 3 com tkinter nao encontrado. Instale (Arch: sudo pacman -S python tk) e rode de novo."
say "Python $(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])') com tkinter: OK"

# ---------------------------------------------------------------- baixar
step "Baixando o instalador"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM
if command -v curl >/dev/null 2>&1; then curl -fsSL "$BASE/$RUN_NAME" -o "$TMP/$RUN_NAME"
elif command -v wget >/dev/null 2>&1; then wget -q "$BASE/$RUN_NAME" -O "$TMP/$RUN_NAME"
else die "Precisa de curl ou wget."; fi
[ -s "$TMP/$RUN_NAME" ] || die "Download falhou ($BASE/$RUN_NAME)."

# ---------------------------------------------------------------- instalar (verifica SHA-256, atalho e inicializacao)
step "Instalando"
sh "$TMP/$RUN_NAME" --silencioso --sem-inicializacao || die "A instalacao falhou."
[ -x "$BIN" ] || die "Comando $BIN nao foi criado."

# ---------------------------------------------------------------- inicializacao automatica
step "Ligando a inicializacao automatica"
AUTO_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"; mkdir -p "$AUTO_DIR"
cp "${XDG_DATA_HOME:-$HOME/.local/share}/applications/$SLUG.desktop" "$AUTO_DIR/$SLUG.desktop" 2>/dev/null && say "XDG autostart: $AUTO_DIR/$SLUG.desktop"

# niri nao le a pasta autostart: precisa de spawn-at-startup no config.kdl
NIRI_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
if [ -f "$NIRI_CFG" ]; then
  if grep -q "$SLUG" "$NIRI_CFG"; then say "niri: ja configurado."
  else
    cp "$NIRI_CFG" "$NIRI_CFG.bak-computer-optimization"
    printf '\n// Computer Optimization: abrir ao iniciar a sessao\nspawn-at-startup "%s"\n' "$BIN" >> "$NIRI_CFG"
    say "niri: adicionado spawn-at-startup em $NIRI_CFG (backup: $NIRI_CFG.bak-computer-optimization)"
  fi
fi

# ---------------------------------------------------------------- testar e abrir
step "Testando a janela (X11/XWayland)"
if [ -z "$DISPLAY" ]; then
  warn "DISPLAY vazio nesta sessao. Sem XWayland o tkinter nao abre janela."
  warn "No niri: sudo pacman -S xwayland-satellite e reinicie a sessao (ou rode: xwayland-satellite &)."
elif ! python3 -c 'import tkinter; r = tkinter.Tk(); r.destroy()' 2>"$TMP/tk.err"; then
  warn "O tkinter nao conseguiu abrir uma janela de teste:"; sed 's/^/    /' "$TMP/tk.err"
fi

step "Abrindo o Computer Optimization"
pkill -f "$SLUG/computer_optimization.py" 2>/dev/null; sleep 1
( nohup "$BIN" >/dev/null 2>&1 & ) 2>/dev/null
sleep 3
if pgrep -f "$SLUG/computer_optimization.py" >/dev/null 2>&1; then
  say "Programa em execucao. Da proxima vez ele abre sozinho ao iniciar a sessao."
else
  warn "O programa fechou logo ao abrir. Motivo:"
  if [ -s "$LOG" ]; then sed 's/^/    /' "$LOG"; else say "    (sem mensagem; rode no terminal: $BIN)"; fi
  exit 1
fi
