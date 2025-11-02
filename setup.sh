#!/usr/bin/env bash

# Elixir Learning Repository Setup Script for Platform Engineers
# This script will help you set up your development environment for learning Elixir
# with a focus on building Internal Developer Platforms and infrastructure abstractions

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Version comparison function
version_ge() {
    printf '%s\n%s' "$2" "$1" | sort -C -V
}

print_header "Elixir Learning Environment Setup for Platform Engineers"

echo "This script will:"
echo "  1. Check for Elixir and Erlang installation"
echo "  2. Verify version requirements"
echo "  3. Check for Livebook (optional)"
echo "  4. Install project dependencies"
echo "  5. Run tests to verify everything works"
echo ""

# Check OS
OS="$(uname -s)"
print_info "Detected OS: $OS"

# Step 1: Check for Erlang/OTP
print_header "Step 1: Checking Erlang/OTP"

if command_exists erl; then
    ERLANG_VERSION=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>&1 | sed 's/"//g')
    print_success "Erlang/OTP is installed (Version: $ERLANG_VERSION)"
    
    # Check if version is at least 24
    if [[ "$ERLANG_VERSION" -lt 24 ]]; then
        print_warning "Erlang/OTP version 24 or higher is recommended. You have version $ERLANG_VERSION"
    fi
else
    print_error "Erlang/OTP is not installed"
    echo ""
    echo "Please install Erlang/OTP first:"
    echo ""
    case "$OS" in
        Darwin)
            echo "  brew install erlang"
            ;;
        Linux)
            if command_exists apt-get; then
                echo "  sudo apt-get update"
                echo "  sudo apt-get install -y erlang"
            elif command_exists yum; then
                echo "  sudo yum install erlang"
            else
                echo "  Visit: https://www.erlang.org/downloads"
            fi
            ;;
        *)
            echo "  Visit: https://www.erlang.org/downloads"
            ;;
    esac
    exit 1
fi

# Step 2: Check for Elixir
print_header "Step 2: Checking Elixir"

if command_exists elixir; then
    ELIXIR_VERSION=$(elixir --version | grep "Elixir" | awk '{print $2}')
    print_success "Elixir is installed (Version: $ELIXIR_VERSION)"
    
    # Check if version is at least 1.14
    MIN_VERSION="1.14.0"
    if version_ge "$ELIXIR_VERSION" "$MIN_VERSION"; then
        print_success "Elixir version is $ELIXIR_VERSION (>= $MIN_VERSION required)"
    else
        print_warning "Elixir version $MIN_VERSION or higher is recommended. You have $ELIXIR_VERSION"
    fi
else
    print_error "Elixir is not installed"
    echo ""
    echo "Please install Elixir:"
    echo ""
    case "$OS" in
        Darwin)
            echo "  brew install elixir"
            ;;
        Linux)
            if command_exists apt-get; then
                echo "  sudo apt-get update"
                echo "  sudo apt-get install -y elixir"
            elif command_exists yum; then
                echo "  sudo yum install elixir"
            else
                echo "  Visit: https://elixir-lang.org/install.html"
            fi
            ;;
        *)
            echo "  Visit: https://elixir-lang.org/install.html"
            ;;
    esac
    exit 1
fi

# Step 3: Check for Mix
print_header "Step 3: Checking Mix (Elixir build tool)"

if command_exists mix; then
    MIX_VERSION=$(mix --version | grep "Mix" | awk '{print $2}')
    print_success "Mix is installed (Version: $MIX_VERSION)"
else
    print_error "Mix is not installed (it should come with Elixir)"
    exit 1
fi

# Step 4: Update Hex package manager
print_header "Step 4: Updating Hex Package Manager"

print_info "Installing/updating Hex..."
mix local.hex --force
print_success "Hex package manager is ready"

# Step 5: Install Rebar (for Erlang dependencies)
print_header "Step 5: Installing Rebar"

print_info "Installing/updating Rebar..."
mix local.rebar --force
print_success "Rebar is ready"

# Step 6: Check for Livebook (optional but recommended)
print_header "Step 6: Checking Livebook (Optional)"

if command_exists livebook; then
    print_success "Livebook is installed"
else
    print_warning "Livebook is not installed (recommended for interactive notebooks)"
    echo ""
    echo "To install Livebook, run:"
    echo "  mix escript.install hex livebook"
    echo ""
    echo "Or download the desktop app from: https://livebook.dev"
    echo ""
    
    read -p "Would you like to install Livebook now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing Livebook..."
        mix escript.install hex livebook
        print_success "Livebook installed"
        print_info "Note: You may need to add ~/.mix/escripts to your PATH"
    else
        print_info "Skipping Livebook installation"
    fi
fi

# Step 7: Install project dependencies
print_header "Step 7: Installing Project Dependencies"

PROJECT_DIR="projects/health_check_aggregator"

if [ -d "$PROJECT_DIR" ]; then
    print_info "Installing dependencies for Health Check Aggregator..."
    cd "$PROJECT_DIR"
    
    if mix deps.get; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    # Compile the project
    print_info "Compiling project..."
    if mix compile; then
        print_success "Project compiled successfully"
    else
        print_error "Failed to compile project"
        exit 1
    fi
    
    cd - > /dev/null
else
    print_warning "Health Check Aggregator project not found at $PROJECT_DIR"
fi

# Step 8: Run tests
print_header "Step 8: Running Tests"

if [ -d "$PROJECT_DIR" ]; then
    print_info "Running tests for Health Check Aggregator..."
    cd "$PROJECT_DIR"
    
    if mix test; then
        print_success "All tests passed!"
    else
        print_warning "Some tests failed. This is okay if you haven't completed the exercises yet."
    fi
    
    cd - > /dev/null
fi

# Step 9: Final summary
print_header "Setup Complete!"

print_success "Your Elixir learning environment is ready!"
echo ""
echo "Quick Start Commands:"
echo ""
echo -e "${BLUE}1. Start Interactive Elixir Shell:${NC}"
echo "   iex"
echo ""
echo -e "${BLUE}2. Open Livebook Notebooks:${NC}"
echo "   livebook server"
echo "   # Then open: http://localhost:8080"
echo ""
echo -e "${BLUE}3. Run Health Check Aggregator:${NC}"
echo "   cd projects/health_check_aggregator"
echo "   iex -S mix"
echo ""
echo -e "${BLUE}4. Run Tests:${NC}"
echo "   cd projects/health_check_aggregator"
echo "   mix test"
echo ""
echo "Next Steps:"
echo ""
echo "  • Read the main README: cat README.md"
echo "  • Start with beginner docs: ls docs/01-beginner/"
echo "  • Try the quick start guide: cat GET_STARTED.md"
echo "  • Explore notebooks: cd notebooks/01-beginner/"
echo ""
print_success "Happy learning! 🚀"
echo ""

