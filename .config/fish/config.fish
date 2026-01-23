set -gx PATH $HOME/.config/fish/extra $PATH

if not set -q fish_prompt_style 
    set -Ux fish_prompt_style 1
end
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.config/emacs/bin $PATH
set -gx JAVA_HOME /usr/lib/jvm/java-21-openjdk
set -gx PATH $JAVA_HOME/bin $PATH
set -gx PATH /home/chickencuber/.cargo/bin $PATH
set -gx PATH /home/chickencuber/.local/share/gem/ruby/3.4.0/bin $PATH

set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH

if status is-interactive
    # ~/.config/fish/config.fish
    alias emsdk_setup ". ~/emsdk/emsdk_env.fish"


    # Aliases
    alias ls 'ls --color=auto'
    alias ll 'ls -l --color=auto'
    alias grep 'grep --color=auto'
    alias cls 'clear'
    alias vim 'nvim'
    alias vi 'vim'
    alias cd 'z'
    alias more 'less'

    alias md 'mkdir'
    alias rd 'rmdir'

    set -g fish_greeting ''

    . (pyenv init --path | psub)
    . (pyenv init - | psub)
    . (pyenv virtualenv-init - | psub)

    fish_vi_key_bindings
    bind -M insert \cy 'accept-autosuggestion'
    bind \cy "accept-autosuggestion"
    fastfetch
    if test "$TERM" != "linux"
        # Only init Starship if not on a raw TTY
        starship init fish | source
    end
    zoxide init fish | source
end
