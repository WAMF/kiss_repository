# KISS Repository Example

A Flutter app demonstrating **repository switching** between Firebase, PocketBase, and InMemory implementations using the same interface and UI code.

## 🚀 Quick Start

```bash
# Option 1: Start with InMemory (no setup)
cd example && flutter run -d web

# Option 2: Start with all emulators
cd example/scripts && ./start_emulators.sh
# Then: flutter run -d web
```

Use the dropdown to switch between implementations in real-time.

## ✨ Features

- **Repository switching** - Same code, multiple backends
- **Real-time streaming** and CRUD operations  
- **Custom queries** with search functionality

## 📊 Available Implementations

| Implementation | Platforms | Requirements | Setup |
|----------------|-----------|--------|-------|
| **InMemory** | All (including web) | None   | Works immediately |
| **Drift (SQLite)** | All (including web) | None | Works immediately (web assets pre-included) |
| **Firebase** | All (including web) | Firebase CLI | `./start_emulators.sh` |
| **PocketBase** | All (including web) | PocketBase | `./start_emulators.sh` |
| **DynamoDB** | All (including web) | Docker | `./start_emulators.sh` |

⚠️ **Missing dependencies?** The script shows warnings but continues with available emulators.

## 🔧 Adding Your Implementation

### 1. Repository Provider
```dart
// lib/repositories/providers/your_provider.dart
class YourRepositoryProvider extends RepositoryProvider {
  Repository<Product> createRepository() => YourRepository<Product>();
}

// Register in repository_provider.dart enum and switch
```

### 2. Query Builder
```dart
// lib/repositories/query_builders/your_query_builder.dart
class YourProductQueryBuilder extends QueryBuilder<Product> {
  Query<Product> queryByName(String name) => YourQuery(/*...*/);
  Query<Product> queryByPriceRange(double min, double max) => YourQuery(/*...*/);
}
```

### 3. Emulator Script (Optional)
Create `scripts/emulators/yourimpl.sh`:

```bash
#!/bin/bash
EMULATOR_NAME="Your Implementation"
EMULATOR_PORTS=(8080)
EMULATOR_URL="http://localhost:8080"

check_installed() { command -v your-emulator >/dev/null 2>&1; }
install() { brew install your-emulator; }  # or your install method
start() {
  local project_dir="$1" log_file="$2"
  lsof -i :8080 >/dev/null 2>&1 && return 0  # Already running
  cd "$project_dir" && your-emulator serve --port=8080 >"$log_file" 2>&1 &
  echo $!
}
```

**Required:** `EMULATOR_NAME`, `EMULATOR_PORTS`, `EMULATOR_URL`, `check_installed()`, `start()`  
**Optional:** `install()`, `stop()`

The emulator manager auto-discovers scripts and handles installation, startup, and cleanup.

---

**Architecture Benefits:** Backend-agnostic business logic • Easy testing • Type-safe queries • Future-proof design
