# KISS Repository Example

This example demonstrates the **centralized approach** of the KISS Repository pattern with a fully functional Flutter app that showcases:

- **Repository switching** between Firebase, PocketBase, and InMemory implementations
- **Unified interface** - same code works with all backends
- **Real-time streaming** of data changes
- **CRUD operations** (Create, Read, Update, Delete)
- **Custom Query system** with QueryBuilder and search functionality
- **Modern Material 3 UI** with comprehensive error handling
- **Dependency injection** for clean architecture

## 🔄 Implementation Switching

The key feature of this example is the **repository selector dropdown** that allows you to switch between:

- **InMemory** - For development and testing (no setup required)
- **Firebase** - Real-time cloud database with offline support
- **PocketBase** - Self-hosted backend with built-in admin UI

All implementations use the **same interface** and **same UI code** - demonstrating the power of the repository pattern.

## 🚀 Quick Start

### Option 1: Start with InMemory (No Setup)
```bash
cd example
flutter run -d web
```

### Option 2: Start with All Emulators
```bash
# Install and start all emulators
cd example/scripts
./start_emulators.sh

# In another terminal, run the app
cd example
flutter run -d web
```

The app will start with **InMemory** repository selected by default. Use the dropdown in the app bar to switch between implementations.

## 📋 Prerequisites

Before switching to external implementations, you need to start their local emulators:

### 🚀 Emulator Manager

Use the comprehensive emulator management script that handles installation and startup:

```bash
cd example/scripts
./start_emulators.sh
```

**Features:**
- **Install emulators** - Firebase CLI, Docker (for DynamoDB), PocketBase
- **Start individual or multiple emulators** - Interactive selection
- **Status checking** - See what's installed and running
- **Graceful shutdown** - Ctrl+C stops all emulators cleanly

### For InMemory
No setup required - works immediately!

## ✨ Features Demonstrated

### Core Repository Operations
- ✅ Add products with auto-generated IDs
- ✅ Real-time streaming of product list updates
- ✅ Update product information inline
- ✅ Delete products with confirmation
- ✅ Error handling for all operations

### Query System
- ✅ **Custom Query classes** (`QueryByName`, `QueryByPriceRange`)
- ✅ **QueryBuilder implementation** for each backend
- ✅ **Search functionality** with real-time filtering
- ✅ **Tabbed interface** (All Products / Search)

### Architecture Benefits
- ✅ **Same code, multiple backends** - switch without changing business logic
- ✅ **Dependency injection** - clean separation of concerns
- ✅ **Type safety** - compile-time verification
- ✅ **Testability** - easy to mock and test



## 📊 Available Implementations

| Implementation | Documentation | Requirements |
|----------------|---------------|--------------|
| **InMemory** | [Built-in Repository](../README.md#using-the-in-memory-implementation) | None - works immediately |
| **Firebase** | [Firebase Repository](https://github.com/WAMF/kiss_firebase_repository) | Firebase CLI |
| **PocketBase** | [PocketBase Repository](https://github.com/WAMF/kiss_pocketbase_repository) | PocketBase binary |
| **DynamoDB** | [DynamoDB Repository](https://github.com/WAMF/kiss_dynamodb_repository) | Docker |

For detailed feature comparison, see the [main documentation](../README.md#implementation-comparison).


## 🎯 Key Learning Points

### 1. Repository Pattern Benefits
- **Backend agnostic** - business logic doesn't depend on storage
- **Easy testing** - mock repositories for unit tests
- **Future-proof** - add new backends without changing existing code

### 2. Query System Design
- **Type-safe queries** - compile-time verification
- **Backend-specific optimization** - each implementation can optimize differently
- **Reusable components** - queries work across the entire app

## 🚀 Running the Example

1. **Clone the repository**
2. **Start local emulators** (if needed - see Prerequisites section above)
3. **Run the app**: `flutter run -d web`
4. **Switch implementations** using the dropdown
5. **Explore the features** - add products, search, see real-time updates

This example demonstrates how the KISS Repository pattern enables you to build applications that can seamlessly work with multiple backends while maintaining clean, testable, and maintainable code.

## 🔗 Related Documentation

- [Main Repository Documentation](../README.md) - Core interface and implementation comparison
