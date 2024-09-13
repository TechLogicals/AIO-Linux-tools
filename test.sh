#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_packages() {
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y curl
    elif command_exists dnf; then
        sudo dnf install -y curl
    elif command_exists yum; then
        sudo yum install -y curl
    elif command_exists pacman; then
        sudo pacman -Sy --noconfirm curl
    else
        echo "Unsupported package manager. Please install curl manually."
        exit 1
    fi
}

# Install Starship
install_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

# Install Zoxide
install_zoxide() {
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# Configure Starship and Zoxide for Bash
configure_shell() {
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
}

# Create custom Starship configuration
create_starship_config() {
    mkdir -p ~/.config
    cat > ~/.config/starship.toml << EOL
format = """
[╭─](bold green)$time$directory$git_branch$git_status
[╰─](bold green)$character"""

[character]
success_symbol = "[➜](bold green) "
error_symbol = "[✗](bold red) "

[time]
disabled = false
format = '[\[$time\]]($style) '
time_format = "%T"
style = "bold yellow"

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold purple"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"
EOL
}

# Main script execution
main() {
    install_packages
    install_starship
    install_zoxide
    configure_shell
    create_starship_config
    
    echo "Installation and configuration complete. Please restart your shell or source ~/.bashrc to apply changes."
}

main
