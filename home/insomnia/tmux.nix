{ ... }:

{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-j";
    mouse = true;
    baseIndex = 1;
    terminal = "screen-256color";

    extraConfig = ''
      set -g terminal-overrides 'xterm:colors=256'

      # Popup
      bind p run-shell "fish -c \"tmux_popup\""

      # Status bar lengths
      set-option -g status-left-length 90
      set-option -g status-right-length 90

      set-option -g status-left '#H:[#P]'
      set-option -g status-right '#(wifi) #(battery --tmux) [%Y-%m-%d(%a) %H:%M]'

      set-option -g status-interval 1
      set-option -g status-justify centre
      set-option -g status-bg "colour238"
      set-option -g status-fg "colour255"

      # prefix-key indicator (reverse colors while pressed)
      set-option -g status-left '#[fg=cyan,bg=#303030]#{?client_prefix,#[reverse],} tmux #[default]'

      # vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # vim-like pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # split panes
      bind | split-window -h
      bind - split-window -v

      # mouse wheel enters copy-mode
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"

      # copy-mode-vi bindings
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi V send -X select-line
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi y send -X copy-selection
      bind -T copy-mode-vi Y send -X copy-line

      bind-key C-p paste-buffer

      # Clipboard via xclip
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -i -sel clip > /dev/null"
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -i -sel clip > /dev/null"
    '';
  };
}
