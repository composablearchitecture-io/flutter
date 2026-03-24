---
name: scope-store
description: Scope a parent Store into a child Store with state projection and action embedding. Use when connecting child features to parent stores, rendering collections, or handling optional/polymorphic state.
argument-hint: <scope-type>
---

# Scope Store

Create scoped child stores from parent stores using the `composable_architecture_core` package. Store scoping is the UI-level counterpart to reducer pullback — it projects state down and lifts actions up so child widgets work with focused types.

## Prerequisites

```yaml
dependencies:
  composable_architecture_core: ^0.1.0
  composable_architecture_flutterw: ^0.1.0  # for widget integration
```

## Conventions

1. Use `store.scope()` when both state and action types need to change
2. Use `store.scopeState()` when only state needs projecting (same action type)
3. Use `store.scopeAction()` when only actions need transforming (same state type)
4. Scoped stores forward actions to the parent — the child reducer is a no-op
5. Prefer `WithStore.observe` over manual `scopeState` in widget code
6. State classes used in scoping must have working `==` for `WithStore` rebuild detection — via freezed, dart_mappable, or hand-written `operator ==` (check `pubspec.yaml`)

## Core API

### Full Scope (state + action)

Projects state and embeds actions. The child store reads state from the parent via the projection function and forwards actions to the parent via the embedding function.

```dart
final childStore = parentStore.scope<ChildState, ChildAction>(
  toLocalState: (parentState) => parentState.child,
  toGlobalAction: (childAction) => ParentAction.child(childAction),
);
```

### State-Only Scope

When child and parent share the same action type but the child only needs a slice of state:

```dart
final counterStore = appStore.scopeState<int>(
  toLocalState: (state) => state.counter,
);
// counterStore is Store<int, AppAction>
```

### Action-Only Scope

When state stays the same but actions need transformation:

```dart
final localStore = appStore.scopeAction<ChildAction>(
  toGlobalAction: (childAction) => AppAction.child(childAction),
);
// localStore is Store<AppState, ChildAction>
```

## Widget Integration

### WithStore.observe — Scoped Rebuilds

The most common scoping pattern in widgets. Projects state so the widget only rebuilds when the projected value changes:

```dart
WithStore.observe(
  store: appStore,
  observe: (AppState state) => state.username,
  builder: (String username, send, context) => Text(username),
);
```

Internally this calls `store.scopeState(toLocalState: observe)`.

### Full Scope in Widgets

When a child feature has its own state and action types:

```dart
class ParentPage extends StatelessWidget {
  final Store<ParentState, ParentAction> store;

  const ParentPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final childStore = store.scope<ChildState, ChildAction>(
      toLocalState: (state) => state.child,
      toGlobalAction: (action) => ParentAction.child(action),
    );

    return Column(
      children: [
        ChildPage(store: childStore),
        WithStore.observe(
          store: store,
          observe: (state) => state.title,
          builder: (title, send, context) => Text(title),
        ),
      ],
    );
  }
}
```

### ForEachStore — Collection Scoping

Creates a scoped store for each element in a collection. Each item gets its own `Store<ItemState, ItemAction>`:

```dart
ForEachStore.id(
  store: store,
  getIterable: (state) => state.contacts,
  embedAction: (id, action) => AppAction.contact(id, action),
  toID: (ContactState contact) => contact.id,
  iterableBuilder: IterableBuilder.listViewBuilder(),
  builder: (context, Store<ContactState, ContactAction> contactStore, id) =>
      ContactCard(store: contactStore),
);
```

#### ForEachStore.indexed — By Index

```dart
ForEachStore.indexed(
  store: store,
  getIterable: (state) => state.items,
  embedAction: (index, action) => AppAction.item(index, action),
  iterableBuilder: IterableBuilder.column(context),
  builder: (context, Store<ItemState, ItemAction> itemStore, index) =>
      ItemRow(store: itemStore),
);
```

### IfLetStore — Optional State Scoping

Scopes to nullable state. Renders the builder only when state is non-null:

```dart
IfLetStore<UserProfile, ProfileAction>(
  store: profileStore, // Store<UserProfile?, ProfileAction>
  builder: (context, store) => WithStore(
    store: store, // Store<UserProfile, ProfileAction> — non-nullable
    builder: (profile, send, ctx) => Text(profile.name),
  ),
  orElse: (context) => Text('No profile'),
);
```

#### IfLetStore.observe — Project then unwrap

```dart
IfLetStore.observe(
  store: appStore,
  toNullableState: (state) => state.selectedUser,
  toGlobalAction: (action) => AppAction.user(action),
  builder: (context, store) => UserDetailView(store: store),
  orElse: (context) => Text('Select a user'),
);
```

### SwitchStore — Type-Based State Scoping

When state is a sealed class hierarchy, render different widgets per variant:

```dart
SwitchStore<AuthState, AuthAction>(
  store: authStore,
  typeMap: {
    LoggedIn: (context, store) => HomeScreen(store: store),
    LoggedOut: (context, store) => LoginScreen(store: store),
  },
);
```

#### Fluent API

```dart
SwitchStore(store: authStore)
    .when<LoggedIn>((ctx, store) => HomeScreen(store: store))
    .when<LoggedOut>((ctx, store) => LoginScreen(store: store));
```

Internally uses `store.scopeState(toLocalState: (s) => s as T)` to downcast.

## Common Patterns

### Scoping with Lens

When you already have a `Lens` defined for reducer pullback, reuse it for store scoping:

```dart
final stateLens = (
  get: (ParentState state) => state.child,
  set: (ParentState state, ChildState child) => state.copyWith(child: child),
);

// In widget:
final childStore = parentStore.scope<ChildState, ChildAction>(
  toLocalState: stateLens.get,
  toGlobalAction: (action) => ParentAction.child(action),
);
```

### Multiple Scopes from One Parent

```dart
@override
Widget build(BuildContext context) {
  final headerStore = store.scope<HeaderState, HeaderAction>(
    toLocalState: (s) => s.header,
    toGlobalAction: (a) => AppAction.header(a),
  );

  final contentStore = store.scope<ContentState, ContentAction>(
    toLocalState: (s) => s.content,
    toGlobalAction: (a) => AppAction.content(a),
  );

  return Column(
    children: [
      HeaderWidget(store: headerStore),
      ContentWidget(store: contentStore),
    ],
  );
}
```

### Derived / Computed State

Project to a value that doesn't exist directly in state:

```dart
WithStore.observe(
  store: store,
  observe: (state) => (
    fullName: '${state.firstName} ${state.lastName}',
    itemCount: state.items.length,
  ),
  builder: (derived, send, context) => Column(
    children: [
      Text(derived.fullName),
      Text('${derived.itemCount} items'),
    ],
  ),
);
```

## Checklist

- [ ] Correct scope variant chosen (`scope`, `scopeState`, `scopeAction`)
- [ ] `toLocalState` projects the exact state slice needed
- [ ] `toGlobalAction` correctly embeds child actions into parent action type
- [ ] Widget rebuilds are minimized via `WithStore.observe` where possible
- [ ] Collections use `ForEachStore` with proper ID function
- [ ] Optional state uses `IfLetStore` with `orElse` fallback
- [ ] Sealed state hierarchies use `SwitchStore` with exhaustive type map
