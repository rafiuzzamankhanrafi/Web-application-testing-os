#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}🔹${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Check if Go is installed
check_go() {
    if command -v go &> /dev/null; then
        print_success "Go is already installed: $(go version)"
        print_status "GOROOT: $(go env GOROOT)"
        print_status "GOPATH: $(go env GOPATH)"
        
        read -p "$(echo -e "${YELLOW}Do you want to reinstall? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Exiting..."
            exit 0
        fi
        print_status "Proceeding with reinstallation..."
    else
        print_status "Go not found. Installing..."
    fi
}

# Update system packages
update_system() {
    print_status "Updating package list..."
    sudo apt update -y > /dev/null 2>&1
    print_success "Package list updated"
}

# Clean old installations
clean_old() {
    print_status "Cleaning old Go installations..."
    sudo rm -rf /usr/local/go
    rm -rf /tmp/go.tar.gz
    rm -rf ~/go
    print_success "Cleanup completed"
}

# Get latest Go version
get_latest_version() {
    print_status "Fetching latest Go version..."
    GO_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    
    if [ -z "$GO_VERSION" ]; then
        print_error "Failed to fetch latest version"
        exit 1
    fi
    
    print_success "Latest version: $GO_VERSION"
}

# Download and install Go
install_go() {
    local tarball="${GO_VERSION}.linux-amd64.tar.gz"
    local url="https://go.dev/dl/${tarball}"
    local tmp_file="/tmp/go.tar.gz"
    
    print_status "Downloading Go..."
    wget -q --show-progress "$url" -O "$tmp_file"
    
    print_status "Extracting Go..."
    sudo tar -C /usr/local -xzf "$tmp_file"
    
    print_success "Go installed successfully"
}

# Setup Go environment
setup_env() {
    print_status "Creating GOPATH structure..."
    mkdir -p $HOME/go/{bin,src,pkg}
    
    print_status "Configuring environment variables..."
    
    GO_ENV='# Go environment setup
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
    
    # Backup original files
    [ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.backup
    [ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup
    
    # Add to bashrc
    if [ -f ~/.bashrc ]; then
        if ! grep -q "GOROOT=/usr/local/go" ~/.bashrc; then
            echo -e "\n$GO_ENV" >> ~/.bashrc
            print_success "Added to ~/.bashrc"
        fi
    fi
    
    # Add to zshrc
    if [ -f ~/.zshrc ]; then
        if ! grep -q "GOROOT=/usr/local/go" ~/.zshrc; then
            echo -e "\n$GO_ENV" >> ~/.zshrc
            print_success "Added to ~/.zshrc"
        fi
    fi
}

# Verify installation
verify_install() {
    print_status "Verifying installation..."
    
    # Source the new environment
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    
    if /usr/local/go/bin/go version &> /dev/null; then
        print_success "Installation verified"
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        /usr/local/go/bin/go version
        echo -e "${BLUE}GOROOT:${NC} $(/usr/local/go/bin/go env GOROOT)"
        echo -e "${BLUE}GOPATH:${NC} $(/usr/local/go/bin/go env GOPATH)"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Show completion message
show_completion() {
    echo
    print_success "Go installation completed successfully!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Run: source ~/.bashrc (or restart terminal)"
    echo "  2. Test with: go version"
    echo "  3. Create a test project:"
    echo "     mkdir -p ~/go/src/hello"
    echo "     cd ~/go/src/hello"
    echo '     echo '\''package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("Hello, Go!")\n}'\'' > main.go'
    echo "     go run main.go"
    echo
}

# Main execution
main() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}         Go Installation Process${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    check_go
    update_system
    clean_old
    get_latest_version
    install_go
    setup_env
    verify_install
    show_completion
}

# Run main function
main

