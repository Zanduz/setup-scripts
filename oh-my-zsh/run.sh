#!/bin/bash

# ------------------------------------------------------------------------------
# setup_zsh.sh
#
# Sets up a Zsh development environment with Oh My Zsh, Powerlevel10k, plugins,
# aliases, and a preconfigured .p10k.zsh theme. Fully idempotent.
# ------------------------------------------------------------------------------

abort() {
  echo "❌ $1" >&2
  exit 1
}

# 1. Check if Zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  abort "zsh is not installed. Please install zsh and try again."
fi

echo "✅ Zsh is installed."

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
ZSHRC="$HOME/.zshrc"

# 2. Install Oh My Zsh
if [ -d "$ZSH_DIR" ]; then
  echo "🧠 Oh My Zsh already installed. Skipping."
else
  echo "📦 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || abort "Failed to install Oh My Zsh"
fi

# 3. Install Plugins
declare -A PLUGINS
PLUGINS=(
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-colorls]="https://github.com/gretzky/auto-color-ls.git"
)

for name in "${!PLUGINS[@]}"; do
  target="$ZSH_CUSTOM/plugins/$name"
  if [ -d "$target" ]; then
    echo "✅ $name already installed."
  else
    echo "🔧 Installing $name..."
    git clone "${PLUGINS[$name]}" "$target" || abort "Failed to clone $name"
  fi
done

# 4. Install Powerlevel10k
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  echo "✅ Powerlevel10k already installed."
else
  echo "🎨 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || abort "Failed to clone Powerlevel10k"
fi

# 5. Set ZSH_THEME in .zshrc
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
  sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

# 6. Ensure .p10k.zsh is sourced
if [ -f "$HOME/.p10k.zsh" ]; then
  if ! grep -q '[[ -f ~/.p10k.zsh ]]' "$ZSHRC"; then
    echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> "$ZSHRC"
  fi
else
  echo "⚠️ Note: .p10k.zsh not found in home directory. Please add your config to ~/.p10k.zsh."
fi

# 7. Configure plugins in .zshrc
REQUIRED_PLUGINS=(git zsh-syntax-highlighting zsh-autosuggestions zsh-colorls eza)
if grep -q "^plugins=" "$ZSHRC"; then
  sed -i.bak '/^plugins=/c\plugins=('${REQUIRED_PLUGINS[*]}')' "$ZSHRC"
else
  echo "plugins=(${REQUIRED_PLUGINS[*]})" >> "$ZSHRC"
fi

# 8. Add aliases
declare -A ALIASES
ALIASES=(
  [dog]="cat"
  [edit]="nano"
  [gst]="git status"
  [bro]="git"
  [pls]="sudo"
  [ll]="eza -l"
  [ls]="eza"
  [lla]="eza -la"
  [k]="kubectl"
)

echo "📝 Adding aliases..."
for alias in "${!ALIASES[@]}"; do
  if ! grep -q "alias $alias=" "$ZSHRC"; then
    echo "alias $alias=\"${ALIASES[$alias]}\"" >> "$ZSHRC"
  fi
done

# 9. Set default shell to Zsh if needed
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "🔁 Setting Zsh as your default shell..."
  chsh -s "$(which zsh)" || echo "⚠️ Could not change shell. Try running: chsh -s $(which zsh)"
else
  echo "✅ Zsh is already your default shell."
fi

# 10. Source .zshrc via Zsh
echo "🔄 Sourcing ~/.zshrc with Zsh..."
zsh -i -c "source ~/.zshrc"

echo "🎉 Setup complete! Your Powerlevel10k Zsh environment is ready."

# 11. Optionally enter Zsh shell
exec zsh