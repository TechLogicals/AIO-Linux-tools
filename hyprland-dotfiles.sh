#!/bin/bash

# Install Go if not already installed
install_go() {
    if ! command -v go &> /dev/null; then
        echo "Installing Go..."
        # You may need to adjust this based on your system and desired Go version
        wget https://golang.org/dl/go1.17.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
        echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
        rm go1.17.linux-amd64.tar.gz
    fi
}

# Install Bubble Tea
install_bubbletea() {
    echo "Installing Bubble Tea..."
    go install github.com/charmbracelet/bubbletea@latest
}

# Function to install Hyprland and all necessary dependencies
install_hyprland() {
    echo "Installing Hyprland and all necessary dependencies..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm hyprland waybar wofi kitty network-manager-applet pavucontrol brightnessctl playerctl \
            polkit-gnome gnome-keyring xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
            pipewire wireplumber xdg-utils grim slurp wl-clipboard swappy
    elif command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y hyprland waybar wofi kitty network-manager-gnome pavucontrol brightnessctl playerctl \
            policykit-1-gnome gnome-keyring xdg-desktop-portal-wlr qt5-wayland qt6-wayland \
            pipewire wireplumber xdg-utils grim slurp wl-clipboard swappy
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y hyprland waybar wofi kitty NetworkManager-applet pavucontrol brightnessctl playerctl \
            polkit-gnome gnome-keyring xdg-desktop-portal-wlr qt5-qtwayland qt6-qtwayland \
            pipewire wireplumber xdg-utils grim slurp wl-clipboard swappy
    else
        echo "Unsupported package manager. Please install Hyprland and its dependencies manually."
        exit 1
    fi
}

# Function to install fonts
install_fonts() {
    echo "Installing common fonts..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm ttf-font-awesome ttf-fira-code noto-fonts-emoji ttf-jetbrains-mono ttf-roboto
    elif command -v apt &> /dev/null; then
        sudo apt install -y fonts-font-awesome fonts-firacode fonts-noto-color-emoji fonts-jetbrains-mono fonts-roboto
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y fontawesome-fonts fira-code-fonts google-noto-emoji-fonts jetbrains-mono-fonts google-roboto-fonts
    else
        echo "Unsupported package manager. Please install fonts manually."
    fi
}

# Function to clone and install dotfiles
install_dotfiles() {
    local repo=$1
    local name=$2
    echo "Installing $name dotfiles..."
    git clone "$repo" "/tmp/$name-dotfiles"
    
    # Check if there's an install script and run it if it exists
    if [ -f "/tmp/$name-dotfiles/install.sh" ]; then
        echo "Found install script. Running it..."
        chmod +x "/tmp/$name-dotfiles/install.sh"
        "/tmp/$name-dotfiles/install.sh"
    else
        # If no install script, copy files manually
        cp -r "/tmp/$name-dotfiles/.config/"* "$HOME/.config/"
    fi
    
    # Install specific dependencies for each dotfile set
    case $name in
        "ChrisTitusTech")
            sudo pacman -S --noconfirm rofi dunst picom || sudo apt install -y rofi dunst picom || sudo dnf install -y rofi dunst picom
            ;;
        "linuxmobile")
            sudo pacman -S --noconfirm eww-wayland || sudo apt install -y eww || sudo dnf install -y eww
            ;;
        "prasanthrangan")
            sudo pacman -S --noconfirm swww swaylock-effects || sudo apt install -y swww swaylock-effects || sudo dnf install -y swww swaylock-effects
            ;;
        "JaKooLit")
            sudo pacman -S --noconfirm swaybg swaylock-effects || sudo apt install -y swaybg swaylock-effects || sudo dnf install -y swaybg swaylock-effects
            ;;
        "end-4")
            sudo pacman -S --noconfirm eww-wayland fuzzel || sudo apt install -y eww fuzzel || sudo dnf install -y eww fuzzel
            ;;
        "iamverysimp1e")
            sudo pacman -S --noconfirm rofi-lbonn-wayland || sudo apt install -y rofi || sudo dnf install -y rofi
            ;;
        "nawfalmrouyan")
            sudo pacman -S --noconfirm mako || sudo apt install -y mako-notifier || sudo dnf install -y mako
            ;;
        "notusknot")
            echo "This is a Nix-based configuration. Please ensure you have Nix installed."
            ;;
        "ML4W (Stephan Raabe)")
            sudo pacman -S --noconfirm rofi dunst || sudo apt install -y rofi dunst || sudo dnf install -y rofi dunst
            ;;
        "Fufexan")
            echo "This is a Nix-based configuration. Please ensure you have Nix installed."
            ;;
        "Vaxry")
            sudo pacman -S --noconfirm eww-wayland || sudo apt install -y eww || sudo dnf install -y eww
            ;;
        "Flick0")
            sudo pacman -S --noconfirm eww-wayland || sudo apt install -y eww || sudo dnf install -y eww
            ;;
    esac
    
    rm -rf "/tmp/$name-dotfiles"
}

# Function to provide information about using the dotfiles by repo
provide_usage_info() {
    local name=$1
    case $name in
        "ChrisTitusTech")
            echo "ChrisTitusTech's dotfiles include configurations for Hyprland, Waybar, and other tools."
            echo "You may need to install additional dependencies. Check the README for more information."
            echo "To start Hyprland, use the command: Hyprland"
            ;;
        "linuxmobile")
            echo "linuxmobile's dotfiles provide a minimalist Hyprland setup with custom themes."
            echo "Make sure to install the required fonts and dependencies listed in the repository."
            echo "You can start Hyprland by running: Hyprland"
            ;;
        "prasanthrangan")
            echo "prasanthrangan's Hyprdots come with a variety of themes and configurations."
            echo "Use the 'hyprdots' command to access the configuration menu."
            echo "Start Hyprland with: Hyprland"
            ;;
        "JaKooLit")
            echo "JaKooLit's dotfiles include extensive customizations for Hyprland and related tools."
            echo "Refer to the included documentation for keybindings and additional setup steps."
            echo "Launch Hyprland using: Hyprland"
            ;;
        "end-4")
            echo "end-4's dotfiles offer a unique and customizable Hyprland experience."
            echo "Check the repository for any additional setup instructions or dependencies."
            echo "Start Hyprland with: Hyprland"
            ;;
        "iamverysimp1e")
            echo "iamverysimp1e's dots provide a clean and simple Hyprland configuration."
            echo "Make sure to install any required fonts or tools mentioned in the repository."
            echo "Launch Hyprland using: Hyprland"
            ;;
        "nawfalmrouyan")
            echo "nawfalmrouyan's Hyprland configuration includes custom scripts and themes."
            echo "Review the README for any additional setup steps or dependencies."
            echo "Start Hyprland with: Hyprland"
            ;;
        "notusknot")
            echo "notusknot's dotfiles are Nix-based. Ensure you have Nix installed."
            echo "Follow the repository instructions for Nix-specific setup steps."
            echo "To use with Hyprland, you may need to integrate these configs manually."
            ;;
        "ML4W (Stephan Raabe)")
            echo "ML4W dotfiles offer a comprehensive Hyprland setup with additional tools."
            echo "Use the provided scripts to customize your environment."
            echo "Start Hyprland using: Hyprland"
            echo "Refer to the ML4W documentation for detailed usage instructions."
            ;;
        "Fufexan")
            echo "Fufexan's dotfiles are Nix-based and offer a unique Hyprland setup."
            echo "Ensure you have Nix installed and follow the repository instructions."
            echo "You may need to manually integrate some configs with Hyprland."
            ;;
        "Vaxry")
            echo "Vaxry's dotfiles provide a sleek and modern Hyprland configuration."
            echo "Check the repository for any additional dependencies or setup steps."
            echo "Start Hyprland with: Hyprland"
            ;;
        "Flick0")
            echo "Flick0's dotfiles offer a customized Hyprland experience with unique themes."
            echo "Review the README for any specific setup instructions or dependencies."
            echo "Launch Hyprland using: Hyprland"
            ;;
    esac
}

# Main script
echo "Welcome to the Hyprland and dotfiles installer!"

# Install Go and Bubble Tea
install_go
install_bubbletea

# Create a Go file for the Bubble Tea menu
cat << EOF > menu.go
package main

import (
    "fmt"
    "os"

    tea "github.com/charmbracelet/bubbletea"
)

type model struct {
    choices  []string
    cursor   int
    selected map[int]struct{}
}

func initialModel() model {
    return model{
        choices: []string{
            "Install Hyprland",
            "ChrisTitusTech",
            "linuxmobile",
            "prasanthrangan",
            "JaKooLit",
            "end-4",
            "iamverysimp1e",
            "nawfalmrouyan",
            "notusknot",
            "ML4W (Stephan Raabe)",
            "Fufexan",
            "Vaxry",
            "Flick0",
        },
        selected: make(map[int]struct{}),
    }
}

func (m model) Init() tea.Cmd {
    return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        switch msg.String() {
        case "ctrl+c", "q":
            return m, tea.Quit
        case "up", "k":
            if m.cursor > 0 {
                m.cursor--
            }
        case "down", "j":
            if m.cursor < len(m.choices)-1 {
                m.cursor++
            }
        case "enter", " ":
            _, ok := m.selected[m.cursor]
            if ok {
                delete(m.selected, m.cursor)
            } else {
                m.selected[m.cursor] = struct{}{}
            }
        }
    }
    return m, nil
}

func (m model) View() string {
    s := "What would you like to install?\n\n"

    for i, choice := range m.choices {
        cursor := " "
        if m.cursor == i {
            cursor = ">"
        }

        checked := " "
        if _, ok := m.selected[i]; ok {
            checked = "x"
        }

        s += fmt.Sprintf("%s [%s] %s\n", cursor, checked, choice)
    }

    s += "\nPress q to quit and install.\n"

    return s
}

func main() {
    p := tea.NewProgram(initialModel())
    m, err := p.Run()
    if err != nil {
        fmt.Printf("Alas, there's been an error: %v", err)
        os.Exit(1)
    }

    if len(m.(model).selected) == 0 {
        fmt.Println("No items selected")
        return
    }

    fmt.Println("Selected items:")
    for i := range m.(model).selected {
        fmt.Printf("- %s\n", m.(model).choices[i])
    }
}
EOF

# Run the Bubble Tea menu
go run menu.go

# Process user selection
for i in "${!selected[@]}"; do
    choice=${choices[$i]}
    case $choice in
        "Install Hyprland")
            install_hyprland
            install_fonts
            ;;
        *)
            IFS='|' read -r repo name <<< "${dotfiles[$choice]}"
            install_dotfiles "$repo" "$name"
            provide_usage_info "$name"
            ;;
    esac
done

echo "Installation complete!"
echo "Please log out and log back in, or reboot your system, to ensure all changes take effect."
echo "To start Hyprland, run the command: Hyprland"
echo "Note: You may need to configure your display manager to show Hyprland as a session option."








