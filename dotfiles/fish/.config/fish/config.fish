# 环境变量 (全局设置)
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx HF_ENDPOINT https://hf-mirror.com
set -gx UV_CACHE_DIR "/mnt/github/.caches/uv"
set -gx BAT_THEME "Nord"

set -gx NVM_DIR "$HOME/.config/nvm"

# FZF 配置
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"


# 路径设置 (推荐用 fish_add_path，简洁且自动去重)
fish_add_path "$HOME/.local/bin"
if test -d $HOME/.opencode/bin
    fish_add_path $HOME/.opencode/bin
end

if status is-interactive
    # 常用别名
    alias ls='ls --color=auto'
    alias ll='ls -alF --time-style="+%m-%d %H:%M:%S"'
    alias la='ls -A'
    # alias v="nvim"
    # alias vi="nvim"
    # alias vim="nvim"
    alias cat="bat"
    alias comfyup='cd /mnt/github/comfyui-docker; touch ./custom_nodes/.update; docker compose restart; cd -'
    alias lzd='lazydocker'
    alias dcp='docker compose'

	abbr -a v  nvim
    abbr -a vi nvim
    abbr -a vim nvim
    
    # 特色别名
    alias battheme='bat --list-themes | fzf --preview "bat --theme={} --color=always --style=numbers ~/.config/fish/config.fish"'

    # 外部工具初始化
    fzf --fish | source
    zoxide init fish | source
    thefuck --alias | source
    thefuck --alias fk | source

    # Yazi 函数 (保持原样即可)
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # fz-menu 函数
    function fz-menu
        fzf --multi \
            --height 50% --layout=reverse --border \
            --header "➜ Ctrl-A:全选 | Ctrl-D:取消 | Ctrl-R:反选" \
            --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-r:toggle-all"
    end
end