#!/bin/bash
# Interactive user switching menu

show_current_context() {
    echo "=== Current Context ==="
    echo "User: $(whoami)"
    echo "Groups: $(groups)"
    echo "Home: $HOME"
    echo "Shell: $SHELL"
    echo ""
}

show_menu() {
    echo "=== User Environment Menu ==="
    echo "1. Switch to Pentester"
    echo "2. Switch to Developer"  
    echo "3. Switch to Sandbox"
    echo "4. Show current context"
    echo "5. Clean sandbox"
    echo "6. Exit"
    echo ""
}

main() {
    show_current_context
    
    while true; do
        show_menu
        read -p "Choose option [1-6]: " choice
        
        case $choice in
            1)
                /usr/local/bin/switch-to-pentester.sh
                ;;
            2)
                /usr/local/bin/switch-to-developer.sh
                ;;
            3)
                echo "Entering sandbox (isolated environment)..."
                doas -u sandbox bash -l
                ;;
            4)
                show_current_context
                ;;
            5)
                /usr/local/bin/cleanup-sandbox.sh
                ;;
            6)
                echo "Goodbye!"
                break
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
        echo ""
    done
}

main
