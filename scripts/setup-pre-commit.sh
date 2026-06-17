#!/usr/bin/env bash
# =============================================================================
# OPEN HORIZONS PLATFORM - PRE-COMMIT SETUP SCRIPT
# =============================================================================
#
# This script sets up pre-commit hooks and all required dependencies for
# local development.
#
# Usage:
#   ./scripts/setup-pre-commit.sh [--install-tools] [--skip-hooks] [--help]
#
# Options:
#   --install-tools  Install required tools (terraform, tflint, etc.)
#   --skip-hooks     Skip pre-commit hooks installation
#   --help           Show this help message
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Versions
readonly TERRAFORM_VERSION="1.6.6"
readonly TFLINT_VERSION="0.50.2"
readonly TERRAFORM_DOCS_VERSION="0.17.0"
readonly TFSEC_VERSION="1.28.4"
readonly CHECKOV_VERSION="3.1.55"

# Flags
INSTALL_TOOLS=false
SKIP_HOOKS=false

# =============================================================================
# FUNCTIONS
# =============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

show_help() {
    cat << EOF
Open Horizons Platform - Pre-commit Setup

Usage:
  ./scripts/setup-pre-commit.sh [OPTIONS]

Options:
  --install-tools  Install required tools (terraform, tflint, etc.)
  --skip-hooks     Skip pre-commit hooks installation
  --help           Show this help message

Examples:
  # Basic setup (pre-commit only)
  ./scripts/setup-pre-commit.sh

  # Full setup with tools installation
  ./scripts/setup-pre-commit.sh --install-tools

  # Only install tools, no hooks
  ./scripts/setup-pre-commit.sh --install-tools --skip-hooks

Required Tools:
  - Python 3.11+
  - pip
  - pre-commit
  - terraform
  - tflint
  - terraform-docs
  - tfsec
  - checkov
  - shellcheck
  - shfmt
  - kubeconform
  - yamllint
  - markdownlint-cli

EOF
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    fi
    return 1
}

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "darwin";;
        MINGW*|MSYS*|CYGWIN*) echo "windows";;
        *)          echo "unknown";;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)   echo "amd64";;
        arm64|aarch64)  echo "arm64";;
        *)              echo "unknown";;
    esac
}

install_homebrew_package() {
    local package=$1
    if check_command brew; then
        log_info "Installing $package via Homebrew..."
        brew install "$package"
    else
        log_error "Homebrew not found. Please install $package manually."
        return 1
    fi
}

install_tools() {
    log_info "Installing development tools..."
    local os
    os=$(detect_os)

    # Python dependencies
    log_info "Installing Python dependencies..."
    pip install --upgrade pip
    pip install pre-commit black isort flake8 yamllint checkov detect-secrets

    # TFLint
    if ! check_command tflint; then
        log_info "Installing TFLint..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package tflint
        else
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
        fi
    else
        log_success "TFLint already installed"
    fi

    # TFLint Azure plugin
    log_info "Installing TFLint Azure plugin..."
    mkdir -p ~/.tflint.d/plugins
    tflint --init || true

    # Terraform-docs
    if ! check_command terraform-docs; then
        log_info "Installing terraform-docs..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package terraform-docs
        else
            curl -sSLo ./terraform-docs.tar.gz \
                "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-$(detect_os)-$(detect_arch).tar.gz"
            tar -xzf terraform-docs.tar.gz
            chmod +x terraform-docs
            sudo mv terraform-docs /usr/local/bin/
            rm terraform-docs.tar.gz
        fi
    else
        log_success "terraform-docs already installed"
    fi

    # TFSec
    if ! check_command tfsec; then
        log_info "Installing tfsec..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package tfsec
        else
            curl -sSLo ./tfsec \
                "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-$(detect_os)-$(detect_arch)"
            chmod +x tfsec
            sudo mv tfsec /usr/local/bin/
        fi
    else
        log_success "tfsec already installed"
    fi

    # ShellCheck
    if ! check_command shellcheck; then
        log_info "Installing shellcheck..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package shellcheck
        else
            sudo apt-get update && sudo apt-get install -y shellcheck
        fi
    else
        log_success "shellcheck already installed"
    fi

    # shfmt
    if ! check_command shfmt; then
        log_info "Installing shfmt..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package shfmt
        else
            curl -sS https://webinstall.dev/shfmt | bash
        fi
    else
        log_success "shfmt already installed"
    fi

    # Kubeconform
    if ! check_command kubeconform; then
        log_info "Installing kubeconform..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package kubeconform
        else
            curl -sSLo ./kubeconform.tar.gz \
                "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-$(detect_os)-$(detect_arch).tar.gz"
            tar -xzf kubeconform.tar.gz
            chmod +x kubeconform
            sudo mv kubeconform /usr/local/bin/
            rm kubeconform.tar.gz
        fi
    else
        log_success "kubeconform already installed"
    fi

    # markdownlint-cli
    if ! check_command markdownlint; then
        log_info "Installing markdownlint-cli..."
        if check_command npm; then
            npm install -g markdownlint-cli
        else
            log_warning "npm not found. Please install markdownlint-cli manually."
        fi
    else
        log_success "markdownlint-cli already installed"
    fi

    # gitleaks
    if ! check_command gitleaks; then
        log_info "Installing gitleaks..."
        if [[ "$os" == "darwin" ]]; then
            install_homebrew_package gitleaks
        else
            curl -sSLo ./gitleaks.tar.gz \
                "https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_8.18.1_$(detect_os)_$(detect_arch).tar.gz"
            tar -xzf gitleaks.tar.gz
            chmod +x gitleaks
            sudo mv gitleaks /usr/local/bin/
            rm gitleaks.tar.gz
        fi
    else
        log_success "gitleaks already installed"
    fi

    log_success "All tools installed successfully!"
}

setup_pre_commit() {
    log_info "Setting up pre-commit hooks..."

    cd "$ROOT_DIR"

    # Check if pre-commit is installed
    if ! check_command pre-commit; then
        log_info "Installing pre-commit..."
        pip install pre-commit
    fi

    # Initialize secrets baseline if it doesn't exist
    if [[ ! -f ".secrets.baseline" ]]; then
        log_info "Creating secrets baseline..."
        detect-secrets scan > .secrets.baseline 2>/dev/null || true
    fi

    # Install pre-commit hooks
    log_info "Installing pre-commit hooks..."
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg

    # Run pre-commit on all files to verify setup
    log_info "Running pre-commit on all files (this may take a while)..."
    pre-commit run --all-files || true

    log_success "Pre-commit hooks installed successfully!"
}

verify_setup() {
    log_info "Verifying setup..."

    local tools=(
        "pre-commit"
        "terraform"
        "tflint"
        "tfsec"
        "shellcheck"
        "kubeconform"
        "gitleaks"
    )

    local missing=()

    for tool in "${tools[@]}"; do
        if check_command "$tool"; then
            log_success "  $tool: $(command -v "$tool")"
        else
            log_warning "  $tool: NOT FOUND"
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Some tools are missing. Run with --install-tools to install them."
    else
        log_success "All tools verified!"
    fi
}

print_summary() {
    echo ""
    echo "============================================================"
    echo "  Pre-commit Setup Complete!"
    echo "============================================================"
    echo ""
    echo "What happens now:"
    echo "  - Pre-commit hooks run automatically on 'git commit'"
    echo "  - Terraform files are formatted and validated"
    echo "  - Security scans run on every commit"
    echo "  - Shell scripts are checked with ShellCheck"
    echo "  - YAML and Markdown files are linted"
    echo ""
    echo "Manual commands:"
    echo "  pre-commit run --all-files    # Run on all files"
    echo "  pre-commit run terraform_fmt  # Run specific hook"
    echo "  pre-commit autoupdate         # Update hook versions"
    echo ""
    echo "Skip hooks (if needed):"
    echo "  git commit --no-verify -m 'message'"
    echo ""
    echo "Documentation:"
    echo "  https://pre-commit.com/"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-tools)
                INSTALL_TOOLS=true
                shift
                ;;
            --skip-hooks)
                SKIP_HOOKS=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo ""
    echo "============================================================"
    echo "  Open Horizons Platform - Pre-commit Setup"
    echo "============================================================"
    echo ""

    # Check Python
    if ! check_command python3; then
        log_error "Python 3 is required. Please install it first."
        exit 1
    fi

    # Install tools if requested
    if [[ "$INSTALL_TOOLS" == "true" ]]; then
        install_tools
    fi

    # Setup pre-commit
    if [[ "$SKIP_HOOKS" != "true" ]]; then
        setup_pre_commit
    fi

    # Verify setup
    verify_setup

    # Print summary
    print_summary
}

main "$@"
