# Computer Optimization para Linux

Monitor e otimizador do PC (CPU, memória, disco, rede, processos e limpeza do sistema), feito em Python + tkinter.
Instala só na sua conta de usuário, sem precisar de root, e não envia nada para a internet.

## Instalação em um comando

Abra um terminal **como usuário normal** (sem `sudo`) e cole:

```sh
curl -fsSL https://raw.githubusercontent.com/ThomasFarss/computer-optimization-linux/main/instalar-linux.sh | sh
```

O script faz tudo sozinho:

1. Instala o que faltar: Python 3, tkinter e, no niri, o `xwayland-satellite`. Só pede a senha nessa etapa.
2. Baixa o instalador e confere o SHA-256.
3. Instala o programa e cria o atalho no menu de aplicativos.
4. Liga a abertura automática ao iniciar a sessão.
5. Testa a janela, abre o programa e confere se ele continuou rodando. Se fechar, mostra o motivo na tela.

Distribuições testadas pelo script: Arch/CachyOS/Manjaro, Debian/Ubuntu/Mint, Fedora e openSUSE.

## Instalação manual

```sh
git clone https://github.com/ThomasFarss/computer-optimization-linux
cd computer-optimization-linux
sh Instalador-ComputerOptimization-Linux.run
```

Opções do instalador: `-y` (sem perguntas) · `--sem-atalho` · `--sem-inicializacao` · `--instalar-dependencias` · `--verificar` · `--ajuda`.

Para conferir o arquivo baixado, compare com o [SHA256.txt](SHA256.txt):

```sh
sha256sum Instalador-ComputerOptimization-Linux.run
```

## Abrir o programa

- Pelo menu de aplicativos: **Computer Optimization**.
- Pelo terminal: `~/.local/bin/computer-optimization`.

> O arquivo `.run` só **instala**. Para abrir depois, use o menu ou o comando acima.

## Abrir sozinho ao ligar o computador

O instalador cria `~/.config/autostart/computer-optimization.desktop`, que funciona no GNOME, KDE, XFCE e similares.

No **niri** essa pasta não é lida. Por isso o script de instalação adiciona esta linha ao `~/.config/niri/config.kdl` (com backup ao lado):

```kdl
spawn-at-startup "/home/SEU_USUARIO/.local/bin/computer-optimization"
```

## Problemas comuns

**A janela não abre (principalmente em niri, Sway, Hyprland ou outro Wayland puro).**
O tkinter 8.6 só fala X11, então precisa do XWayland.

```sh
echo $DISPLAY                       # precisa mostrar algo como :0 ou :1
pacman -Q xwayland-satellite        # niri: precisa estar instalado
sudo pacman -S xwayland-satellite   # se não estiver
```

Depois reinicie a sessão.

**Abre pelo terminal mas não pelo menu.** O menu pode estar abrindo o programa sem a variável `DISPLAY`. Confira com `echo $DISPLAY` dentro da mesma sessão do menu e reinicie a sessão depois de instalar o `xwayland-satellite`.

**Ver o erro real:**

```sh
python3 ~/.local/share/computer-optimization/computer_optimization.py; echo "saiu com codigo: $?"
cat ~/.cache/computer-optimization/last-run.log
```

**"O Computer Optimization já está aberto" e nada aparece.** Há uma cópia rodando escondida:

```sh
pkill -f computer_optimization.py
~/.local/bin/computer-optimization
```

Se continuar sem abrir, abra uma *issue* aqui no repositório com a saída desses comandos e o resultado de `python3 --version`, `echo $XDG_SESSION_TYPE $DISPLAY` e `python3 -c "import tkinter; print(tkinter.TkVersion)"`.

## Desinstalar

```sh
sh ~/.local/share/computer-optimization/desinstalar.sh
```

Se você usou o niri, apague também a linha `spawn-at-startup` do `config.kdl` (o backup tem o nome `config.kdl.bak-computer-optimization`).
