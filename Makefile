# vim: ts=2 sw=2 sts=2 et :
SHELL := /bin/bash
PAPER ?= main        # tex basename (no .tex)
OUT   ?= $(HOME)/tmp # pdf output dir
Theme ?= https://github.com/catppuccin/nvim # for sh, vi

PAPER := $(strip $(PAPER))
OUT   := $(strip $(OUT))

need = @command -v $(1) >/dev/null || { printf "missing: %s (needed for %s)\n" $(1) $(2); exit 1; }

$(shell mkdir -p $(OUT))

.PHONY: help fast all clean push doctor sh vi claude claude-off tmux tmux-off tmux-restore

help: ## show help
	@gawk 'BEGIN {FS = ":.*?##"; \
	         printf "\nUsage:\n  make \033[36m<target>\033[0m [VAR=val ...]\n\ntargets:\n"} \
	       /^[a-zA-Z0-9_%\.\/ -]+:.*?##/ { \
	         printf("  \033[36m%-12s\033[0m %s\n", $$1, $$2) | "sort" }' $(MAKEFILE_LIST)
	@printf "\ndefaults:\n"
	@gawk 'match($$0, /^([A-Za-z][A-Za-z0-9]*)[ \t]*\?=[ \t]*([^#]*[^# \t])[ \t]*#[ \t]*(.+)/, a) { \
	         printf("  \033[36m%-8s\033[0m = %-30s %s\n", a[1], a[2], a[3]) | "sort" }' $(MAKEFILE_LIST)

fast: ## one pdflatex, open in Skim
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $(PAPER).tex
	@echo "PDF: $(OUT)/$(PAPER).pdf"
	@open -a Skim $(OUT)/$(PAPER).pdf

all: ## pdflatex + bibtex + pdflatex x2
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $(PAPER).tex
	cd $(OUT) && BIBINPUTS=$(CURDIR): BSTINPUTS=$(CURDIR): bibtex $(PAPER)
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $(PAPER).tex
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $(PAPER).tex
	@echo "PDF: $(OUT)/$(PAPER).pdf"
	@open -a Skim $(OUT)/$(PAPER).pdf

clean: ## wipe aux/pdf in OUT
	rm -f $(OUT)/$(PAPER).{aux,bbl,blg,log,out,toc,pdf}

CLAUDE_TGT := $(HOME)/.claude/keybindings.json
CLAUDE_SRC := $(CURDIR)/.claude/keybindings.json

define CLAUDE_KEYS
{
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+k": "chat:clearInput"
      }
    }
  ]
}
endef
export CLAUDE_KEYS

$(CLAUDE_SRC):
	@mkdir -p $(dir $(CLAUDE_SRC))
	@printf '%s\n' "$$CLAUDE_KEYS" > $@
	@echo "wrote $@"

claude: $(CLAUDE_SRC) ## install portable keybindings → ~/.claude/ (back up existing)
	@mkdir -p $(HOME)/.claude
	@if [ -e $(CLAUDE_TGT) ] && [ ! -L $(CLAUDE_TGT) ]; then \
	   mv $(CLAUDE_TGT) $(CLAUDE_TGT).bak.$$(date +%s); \
	   echo "backed up existing → $(CLAUDE_TGT).bak.*"; fi
	@ln -sfn $(CLAUDE_SRC) $(CLAUDE_TGT)
	@echo "linked: $(CLAUDE_TGT) → $(CLAUDE_SRC)"

TMUX_TGT := $(HOME)/.tmux.conf
TMUX_SRC := $(CURDIR)/.tmux.conf
TPM_DIR  := $(HOME)/.tmux/plugins/tpm

define TMUX_CONF
# vim: ft=tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 50000
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left  ' #[fg=#f5c2e7,bold]#S '
set -g status-right ' #[fg=#89b4fa]%H:%M  #[fg=#a6e3a1]%d-%b '
setw -g mode-keys vi

# plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# survive reboot: auto-save every 15 min, auto-tmux-restore on start
set -g @continuum-tmux-restore 'on'
set -g @continuum-save-interval '15'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'

run '~/.tmux/plugins/tpm/tpm'
endef
export TMUX_CONF

$(TMUX_SRC):
	@printf '%s\n' "$$TMUX_CONF" > $@
	@echo "wrote $@"

tmux: $(TMUX_SRC) ## install .tmux.conf + tpm + resurrect/continuum (survive reboot)
	$(call need,git,tmux)
	$(call need,tmux,tmux)
	@if [ -e $(TMUX_TGT) ] && [ ! -L $(TMUX_TGT) ]; then \
	   mv $(TMUX_TGT) $(TMUX_TGT).bak.$$(date +%s); \
	   echo "backed up existing → $(TMUX_TGT).bak.*"; fi
	@ln -sfn $(TMUX_SRC) $(TMUX_TGT)
	@echo "linked: $(TMUX_TGT) → $(TMUX_SRC)"
	@if [ ! -d $(TPM_DIR) ]; then \
	   git clone -q https://github.com/tmux-plugins/tpm $(TPM_DIR); \
	   echo "cloned tpm → $(TPM_DIR)"; fi
	@$(TPM_DIR)/bin/install_plugins
	@echo "DONE. start tmux with: tm   (continuum auto-tmux-restore on start)"

tmux-restore: ## how to restore tmux after window-kill or reboot
	@printf "\n\033[1;36mRestore tmux session:\033[0m\n\n"
	@printf "  \033[1;33m(a) window killed / wezterm closed\033[0m  (tmux server still alive)\n"
	@printf "      \033[32mtm\033[0m         # re-attach to 'main' (alias = tmux new -A -s main)\n"
	@printf "      \033[32mtml\033[0m        # list sessions\n\n"
	@printf "  \033[1;33m(b) reboot / power-off\033[0m              (tmux server died)\n"
	@printf "      \033[32mcd %s\033[0m\n" "$(CURDIR)"
	@printf "      \033[32mmake sh\033[0m    # tmux-restores prompt + aliases\n"
	@printf "      \033[32mtm\033[0m         # continuum auto-tmux-restores last save (≤15min old)\n\n"
	@printf "  manual save/tmux-restore inside tmux:  \033[32mprefix + Ctrl-s\033[0m save,  \033[32mprefix + Ctrl-r\033[0m tmux-restore\n"
	@printf "  (default prefix = Ctrl-b)\n\n"

tmux-off: ## remove tmux symlink, restore latest .bak
	@if [ -L $(TMUX_TGT) ]; then rm $(TMUX_TGT); echo "unlinked $(TMUX_TGT)"; fi
	@bak=$$(ls -t $(TMUX_TGT).bak.* 2>/dev/null | head -1); \
	 if [ -n "$$bak" ]; then mv $$bak $(TMUX_TGT); echo "tmux-restored $$bak → $(TMUX_TGT)"; fi

claude-off: ## remove symlink, restore latest .bak
	@if [ -L $(CLAUDE_TGT) ]; then rm $(CLAUDE_TGT); echo "unlinked $(CLAUDE_TGT)"; fi
	@bak=$$(ls -t $(CLAUDE_TGT).bak.* 2>/dev/null | head -1); \
	 if [ -n "$$bak" ]; then mv $$bak $(CLAUDE_TGT); echo "tmux-restored $$bak → $(CLAUDE_TGT)"; fi

push: ## prompt msg, commit -am, push
	@read -p "Reason? " msg; git commit -am "$$msg"; git push; git status

doctor: ## check required tools
	@for e in \
	   "pdflatex|fast/all targets" \
	   "bibtex|all target" \
	   "gawk|help target (self-doc)" \
	   "git|push target, sh prompt" \
	   "nvim|vi target" \
	   "open|fast/all (Skim launcher)"; do \
	   c=$${e%%|*}; use=$${e##*|}; \
	   if command -v $$c >/dev/null; then \
	     printf "  \033[32m✓\033[0m %-10s used by: %s\n" "$$c" "$$use"; \
	   else \
	     printf "  \033[31m✗\033[0m %-10s missing — can't: %s\n" "$$c" "$$use"; fi; done

define BASHRC
set -o vi
__gp(){ local b=$$(git branch --show-current 2>/dev/null); [[ -z $$b ]] && return
  [[ -n $$(git status --porcelain 2>/dev/null) ]] && b="$$b*"; echo " $$b"; }
__pw(){ pwd | awk -F/ '{print $$(NF-1)"/"$$NF}'; }
PS1='\[\e[36m\]$$(__pw)\[\e[33m\]$$(__gp) \[\e[0m\][\!]\$$ '
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43'
if command ls --color=auto / >/dev/null 2>&1; then
  alias ls='ls --color=auto'
else
  alias ls='ls -G'; fi
alias grep='grep --color=auto'
export LESS='-R'
alias ll='ls -la' gs='git status -s' gd='git diff' gl='git log --oneline -20'
alias mk='make fast' mka='make all'
alias tm='tmux new -A -s main' tma='tmux attach' tml='tmux ls'
D=$$(mktemp -d); trap 'rm -rf "$$D"' EXIT
git clone -q --depth 1 $(Theme) "$$D/cat" 2>/dev/null
printf '%s\n' "$$VIMRC" > "$$D/vimrc"
alias vi='nvim --clean -u "$$D/vimrc" -c "set rtp^=$$D/cat" -c "colorscheme catppuccin-mocha"'
endef
export BASHRC

define VIMRC
set nu rnu cursorline mouse=a termguicolors et ts=2 sw=2 sts=2 ai si
set ignorecase smartcase hlsearch incsearch scrolloff=8 signcolumn=yes
set splitbelow splitright wrap linebreak wildmenu clipboard=unnamedplus
syntax on | filetype plugin indent on
endef
export VIMRC

L := \033[38;5;53m·\033[38;5;91m░\033[38;5;127m▒\033[38;5;163m▓\033[38;5;199m█
R := \033[38;5;199m█\033[38;5;163m▓\033[38;5;127m▒\033[38;5;91m░\033[38;5;53m·\033[0m
define GREETING
$L\033[1;38;5;213m  █     █     █▙▄▟█  ▟▀▙  $R
$L\033[1;38;5;225m  █     █     █ ▀ █   ▟▘  $R
$L\033[1;38;5;199m  █████ █████ █   █   ▀   $R
endef
export GREETING

QUOTES := \
  "essence of strategy: choose what not to do. -- porter" \
  "complex systems evolve from simple ones that worked. -- gall" \
  "compose programs that do one thing well. -- mcilroy" \
  "extraordinary claims require extraordinary evidence. -- sagan" \
  "if you can't measure it, you can't improve it. -- drucker" \
  "weeks of coding save hours of planning. -- anon" \
  "code is read more than written. -- guido" \
  "build it twice. throw first away. -- brooks" \
  "every program attempts to expand until it can read mail. -- zawinski"

sh: ## launch tuned bash + catppuccin (wiped on exit)
	$(call need,nvim,sh)
	$(call need,git,sh)
	@clear; QUOTE=$$(printf '%s\n' $(QUOTES) | gshuf -n1 2>/dev/null || printf '%s\n' $(QUOTES) | awk 'BEGIN{srand()} {a[NR]=$$0} END{print a[int(rand()*NR)+1]}'); \
	 printf "\n$$GREETING\n\n"; \
	 printf " \033[38;5;117m»\033[0m  \033[3;38;5;229m%s\033[0m\n\n" "$$QUOTE"
	@bash --rcfile <(echo "$$BASHRC") -i

F ?= $(PAPER).tex # for vi
vi: ## launch tuned nvim + catppuccin (wiped on exit)
	$(call need,nvim,vi)
	$(call need,git,vi)
	@D=$$(mktemp -d); trap "rm -rf $$D" EXIT; \
	 git clone -q --depth 1 $(Theme) $$D/cat; \
	 nvim --clean -c "$$VIMRC" \
	      -c "set rtp^=$$D/cat" -c "colorscheme catppuccin-mocha" $F
