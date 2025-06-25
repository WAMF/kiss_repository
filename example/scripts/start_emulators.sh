#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array to store running processes
declare -a RUNNING_PIDS=()
declare -a RUNNING_SERVICES=()

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping all emulators...${NC}"
    
    for pid in "${RUNNING_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
    done
    
    # Stop Docker containers if running
    if command -v docker >/dev/null 2>&1; then
        # Try to stop DynamoDB container by name if it exists
        docker stop dynamodb-local 2>/dev/null || true
        docker rm dynamodb-local 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ All emulators stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

print_header() {
    echo -e "${PURPLE}🚀 KISS Emulator Manager${NC}"
    echo -e "${CYAN}=========================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check installation status
check_firebase() {
    command_exists firebase
}

check_dynamodb() {
    command_exists docker && docker info >/dev/null 2>&1
}

check_pocketbase() {
    command_exists pocketbase
}

# Start emulator functions
start_firebase() {
    echo -e "${BLUE}🔥 Starting Firebase emulators...${NC}"
    
    # Check if Firebase emulators are already running
    if lsof -i :4000 >/dev/null 2>&1; then
        print_success "Firebase emulators are already running"
        print_info "Firebase UI: http://localhost:4000"
        print_info "Auth: http://localhost:9099"
        print_info "Firestore: http://localhost:8080"
        RUNNING_SERVICES+=("Firebase")
        return 0
    fi
    
    # Check if we have a firebase.json in the example directory
    if [ -f "$PROJECT_DIR/../firebase.json" ]; then
        cd "$PROJECT_DIR/.."
    elif [ -f "$PROJECT_DIR/firebase.json" ]; then
        cd "$PROJECT_DIR"
    else
        # Create a minimal firebase.json for emulator use
        cd "$PROJECT_DIR/.."
        cat > firebase.json << 'EOF'
{
  "projects": {
    "default": "demo-kiss-example"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
EOF
        print_info "Created firebase.json for emulator use"
    fi
    
    firebase emulators:start --only auth,firestore --project demo-kiss-example &
    local pid=$!
    RUNNING_PIDS+=($pid)
    RUNNING_SERVICES+=("Firebase")
    
    # Wait a moment for startup
    sleep 3
    if kill -0 "$pid" 2>/dev/null; then
        print_success "Firebase emulators started (PID: $pid)"
        print_info "Firebase UI: http://localhost:4000"
        print_info "Auth: http://localhost:9099"
        print_info "Firestore: http://localhost:8080"
        return 0
    else
        print_error "Failed to start Firebase emulators"
        return 1
    fi
}

start_dynamodb() {
    echo -e "${BLUE}🗄️  Starting DynamoDB Local...${NC}"
    
    # Check if already running
    if docker ps --format "table {{.Names}}" | grep -q "dynamodb-local"; then
        print_success "DynamoDB Local is already running"
        print_info "DynamoDB Local: http://localhost:8000"
        RUNNING_SERVICES+=("DynamoDB")
        return 0
    fi
    
    # Stop and remove existing container if it exists
    docker stop dynamodb-local 2>/dev/null || true
    docker rm dynamodb-local 2>/dev/null || true
    
    # Create data directory in the example folder
    mkdir -p "$PROJECT_DIR/../dynamodb_data"
    
    # Start DynamoDB Local using Docker directly
    docker run -d \
        --name dynamodb-local \
        -p 8000:8000 \
        -v "$PROJECT_DIR/../dynamodb_data:/home/dynamodblocal/data" \
        amazon/dynamodb-local:2.5.2 \
        -jar DynamoDBLocal.jar -sharedDb -dbPath ./data -disableTelemetry
    
    if [ $? -eq 0 ]; then
        print_success "DynamoDB Local started"
        print_info "DynamoDB Local: http://localhost:8000"
        print_info "Region: us-east-1"
        print_info "Access Key: fakeMyKeyId"
        print_info "Secret Key: fakeSecretAccessKey"
        RUNNING_SERVICES+=("DynamoDB")
        return 0
    else
        print_error "Failed to start DynamoDB Local"
        return 1
    fi
}

start_pocketbase() {
    echo -e "${BLUE}📱 Starting PocketBase...${NC}"
    
    # Check if port 8090 is already in use
    if lsof -i :8090 >/dev/null 2>&1; then
        print_success "PocketBase is already running on port 8090"
        print_info "PocketBase Admin: http://127.0.0.1:8090/_/"
        print_info "PocketBase API: http://127.0.0.1:8090/api/"
        RUNNING_SERVICES+=("PocketBase")
        return 0
    fi
    
    # Create data directory in the example folder
    mkdir -p "$PROJECT_DIR/../pb_data"
    cd "$PROJECT_DIR/.."
    
    # Start PocketBase
    pocketbase serve --http=127.0.0.1:8090 --dir=pb_data &
    local pid=$!
    RUNNING_PIDS+=($pid)
    RUNNING_SERVICES+=("PocketBase")
    
    # Wait a moment for startup
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        print_success "PocketBase started (PID: $pid)"
        print_info "PocketBase Admin: http://127.0.0.1:8090/_/"
        print_info "PocketBase API: http://127.0.0.1:8090/api/"
        return 0
    else
        print_error "Failed to start PocketBase"
        return 1
    fi
}

# Auto-install missing emulators
install_missing() {
    local needs_install=false
    
    if ! check_firebase; then
        print_warning "Firebase CLI not found"
        if command_exists npm; then
            echo -e "${BLUE}📦 Installing Firebase CLI...${NC}"
            npm install -g firebase-tools
        else
            print_error "npm not found. Install Node.js: brew install node"
            needs_install=true
        fi
    fi
    
    if ! check_dynamodb; then
        print_warning "Docker not available"
        if ! command_exists docker; then
            print_error "Docker not found. Install: brew install --cask docker"
            needs_install=true
        else
            print_error "Docker not running. Please start Docker Desktop"
            needs_install=true
        fi
    fi
    
    if ! check_pocketbase; then
        print_warning "PocketBase not found"
        if command_exists brew; then
            echo -e "${BLUE}📦 Installing PocketBase...${NC}"
            brew install pocketbase
        else
            print_error "Homebrew not found. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            needs_install=true
        fi
    fi
    
    if [ "$needs_install" = true ]; then
        echo -e "\n${YELLOW}Please install missing dependencies and run the script again${NC}"
        exit 1
    fi
}

# Show available emulators with status
show_emulators() {
    echo -e "\n${CYAN}📋 Available Emulators:${NC}"
    
    local firebase_status="❌ Not installed"
    local dynamodb_status="❌ Docker not available"
    local pocketbase_status="❌ Not installed"
    
    if check_firebase; then
        firebase_status="${GREEN}✅ Installed${NC}"
    fi
    
    if check_dynamodb; then
        dynamodb_status="${GREEN}✅ Docker available${NC}"
    fi
    
    if check_pocketbase; then
        pocketbase_status="${GREEN}✅ Installed${NC}"
    fi
    
    echo -e "1) Firebase     - $firebase_status"
    echo -e "2) DynamoDB     - $dynamodb_status"  
    echo -e "3) PocketBase   - $pocketbase_status"
}

# Get user selection
get_selection() {
    echo -e "\n${CYAN}🎯 Select emulators to start:${NC}"
    echo "Enter numbers separated by spaces (e.g., '1 3' for Firebase and PocketBase)"
    echo "Or press Enter to start all available emulators"
    echo -n "Selection: "
    read selection
    
    if [ -z "$selection" ]; then
        # Start all available
        local started_any=false
        
        if check_firebase; then
            start_firebase &
            started_any=true
        fi
        
        if check_dynamodb; then
            start_dynamodb
            started_any=true
        fi
        
        if check_pocketbase; then
            start_pocketbase &
            started_any=true
        fi
        
        if [ "$started_any" = false ]; then
            print_error "No emulators available. Please install them first."
            exit 1
        fi
    else
        # Start selected emulators
        local started_any=false
        
        for num in $selection; do
            case $num in
                1)
                    if check_firebase; then
                        start_firebase &
                        started_any=true
                    else
                        print_error "Firebase CLI not installed"
                    fi
                    ;;
                2)
                    if check_dynamodb; then
                        start_dynamodb
                        started_any=true
                    else
                        print_error "Docker not available"
                    fi
                    ;;
                3)
                    if check_pocketbase; then
                        start_pocketbase &
                        started_any=true
                    else
                        print_error "PocketBase not installed"
                    fi
                    ;;
                *)
                    print_warning "Invalid selection: $num"
                    ;;
            esac
        done
        
        if [ "$started_any" = false ]; then
            print_error "No valid emulators selected or available"
            exit 1
        fi
    fi
}

# Wait for emulators
wait_for_emulators() {
    if [ ${#RUNNING_SERVICES[@]} -gt 0 ]; then
        echo -e "\n${GREEN}🎉 Running emulators: ${RUNNING_SERVICES[*]}${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop all emulators${NC}"
        
        # Wait for all background processes
        wait
    fi
}

# Main function
main() {
    print_header
    
    # Try to auto-install missing emulators
    install_missing
    
    # Show available emulators
    show_emulators
    
    # Get user selection and start emulators
    get_selection
    
    # Wait for emulators to run
    wait_for_emulators
}

# Run main function
main 