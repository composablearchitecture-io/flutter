# composable_architecture_flutterw

Flutter bindings for [composable_architecture_core](../composable_architecture_core/). Provides reactive widgets that connect the Composable Architecture's unidirectional data flow to Flutter's widget tree.

Re-exports everything from `composable_architecture_core`, so you only need this one dependency in Flutter apps.

## Widgets

### WithStore

The primary widget for connecting a Store to the UI. Rebuilds only when state changes:

```dart
WithStore<int, CounterAction>(
  store: store,
  builder: (state, send, context) {
    return Column(
      children: [
        Text('$state'),
        ElevatedButton(
          onPressed: () => send(CounterAction.increment),
          child: Text('Increment'),
        ),
      ],
    );
  },
);
```

#### Observe (scoped rebuilds)

Project state to a subset so the widget only rebuilds when that subset changes:

```dart
WithStore.observe(
  store: store,
  toLocalState: (AppState state) => state.counter,
  toGlobalAction: (CounterAction action) => AppAction.counter(action),
  builder: (count, send, context) => Text('$count'),
);
```

#### Custom Equality

Control when rebuilds happen with a custom equality function:

```dart
WithStore<MyState, MyAction>(
  store: store,
  isEqual: (prev, curr) => prev.name == curr.name, // only rebuild when name changes
  builder: (state, send, context) => Text(state.name),
);
```

### ForEachStore

Render a collection where each item gets its own scoped store. Items are cached by ID for performance:

```dart
ForEachStore.id(
  store: store,
  getIterable: (state) => state.contacts,
  embedAction: (id, action) => AppAction.contact(id, action),
  toID: (contact) => contact.id,
  iterableBuilder: IterableBuilder.listViewBuilder(),
  builder: (context, contactStore, id) => ContactCard(store: contactStore),
);
```

#### Layout Builders

| Builder | Widget |
|---|---|
| `IterableBuilder.listViewBuilder()` | `ListView.builder` with optional separators |
| `IterableBuilder.sliverListBuilder()` | `SliverList` with optional separators |
| `IterableBuilder.sliverReorderableList()` | Draggable reorderable sliver list |
| `IterableBuilder.pageController()` | `PageView` |
| `IterableBuilder.column()` | `Column` |
| `IterableBuilder.row()` | `Row` |
| `MaterialIterableBuilder.reorderableList()` | Material `ReorderableListView` |

### IfLetStore

Conditionally render content based on optional (nullable) state:

```dart
IfLetStore<UserProfile, ProfileAction>(
  store: profileStore, // Store<UserProfile?, ProfileAction>
  builder: (context, store) {
    // store is Store<UserProfile, ProfileAction> (non-nullable)
    return WithStore(
      store: store,
      builder: (profile, send, context) => Text(profile.name),
    );
  },
  orElse: (context) => Text('No profile loaded'),
);
```

With state projection:

```dart
IfLetStore.observe(
  store: appStore,
  toLocalState: (AppState s) => s.selectedUser, // nullable projection
  toGlobalAction: (UserAction a) => AppAction.user(a),
  builder: (context, store) => UserDetailView(store: store),
);
```

### SwitchStore

Render different widgets based on the runtime type of the state:

```dart
SwitchStore<AuthState, AuthAction>(
  store: authStore,
  typeMap: {
    LoggedIn: (context, store) => HomeScreen(store: store),
    LoggedOut: (context, store) => LoginScreen(store: store),
    Loading: (context, store) => LoadingIndicator(),
  },
);
```

## TextEditingController Integration

Two-way binding between a Store and `TextEditingController`:

```dart
WithStore.textEditingController(
  store: store,
  toText: (state) => state.searchQuery,
  fromTextEditingAction: (action) => switch (action) {
    TextEditingAction.edit(:final text) => SearchAction.updateQuery(text),
    _ => null,
  },
  builder: (controller, focusNode) => TextField(
    controller: controller,
    focusNode: focusNode,
  ),
);
```

`TextEditingAction` is a sealed class with three cases:
- `TextEditingAction.edit(String text)` - text content changed
- `TextEditingAction.onKeyEvent(FocusNode, KeyEvent)` - key pressed
- `TextEditingAction.onFocusChange(FocusNode)` - focus changed

## Dependency Injection

InheritedWidget-based service locator for providing dependencies to the widget tree:

```dart
// Register
Dependency(
  provider: DependencyProvider()
    ..register<ApiClient>(ApiClient())
    ..register<Database>(Database()),
  child: MyApp(),
);

// Resolve
final api = Dependency.of(context).resolve<ApiClient>();
```

## App Builders

Pre-built app widgets that integrate store state with MaterialApp/CupertinoApp, including automatic handling of platform events (locale changes, brightness, app lifecycle, memory pressure, etc.).

### Material

```dart
import 'package:composable_architecture_flutterw/material.dart';

ComposableMaterialApp<AppState, AppAction>(
  title: 'My App',
  store: appStore,
  toMaterialAppState: (state) => state.materialAppState,
  toThemeData: (appState) => ThemeData(brightness: appState.brightness),
  routerConfig: routerConfig,
);
```

### Cupertino

```dart
import 'package:composable_architecture_flutterw/cupertino.dart';

ComposableCupertinoApp<AppState, AppAction>(
  title: 'My App',
  store: appStore,
  toCupertinoAppState: (state) => state.cupertinoAppState,
);
```

Platform events dispatched automatically:
- Locale changes
- Brightness / dark mode changes
- App lifecycle (paused, resumed, detached)
- Accessibility feature changes
- Screen metrics changes
- Memory pressure warnings

## Full Example

A counter feature from state definition to UI:

```dart
// -- State & Actions --
enum CounterAction { increment, decrement, reset }

final counterReducer = Reducer<int, CounterAction, EmptyEnvironment>.transform(
  (state, action, env) => switch (action) {
    CounterAction.increment => state + 1,
    CounterAction.decrement => state - 1,
    CounterAction.reset => 0,
  },
);

// -- UI --
class CounterPage extends StatelessWidget {
  final store = Store.emptyEnvironment(0, counterReducer);

  @override
  Widget build(BuildContext context) {
    return WithStore<int, CounterAction>(
      store: store,
      builder: (state, send, context) => Scaffold(
        body: Center(child: Text('$state')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => send(CounterAction.increment),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## Installation

```yaml
dependencies:
  composable_architecture_flutterw: ^0.1.0
```

## Requirements

- Dart SDK ^3.0.6
- Flutter SDK ^3.0.0
