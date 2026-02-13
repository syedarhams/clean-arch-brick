# Clean Architecture Feature Brick

A Mason brick that scaffolds a complete Clean Architecture feature with **Cubit + Equatable** state management, abstract repository, repository implementation, and presentation layer folders.

---

## Setup

### 1. Install Mason CLI (one-time)

```bash
dart pub global activate mason_cli
```

Add `pub-cache/bin` to your PATH. Add this line to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Then reload your shell:

```bash
source ~/.zshrc
```

### 2. Initialize Mason in your project

```bash
mason init
```

### 3. Add the brick to your `mason.yaml`

```yaml
bricks:
  feature:
    git:
      url: https://github.com/syedarhams/clean-arch-brick.git
```

### 4. Install the brick

```bash
mason get
```

### Quick Start (copy-paste)

```bash
# 1. Install Mason (one-time)
dart pub global activate mason_cli
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

# 2. In your Flutter project
mason init

# 3. Add to mason.yaml
cat > mason.yaml << 'EOF'
bricks:
  feature:
    git:
      url: https://github.com/syedarhams/clean-arch-brick.git
EOF

# 4. Install
mason get

# 5. Generate a feature
mason make feature --output-dir lib/features
```

### Access

Since this is a **private** repository, teammates must be added as collaborators:

1. Go to https://github.com/syedarhams/clean-arch-brick/settings/access
2. Click **Add people**
3. Add your teammate's GitHub username or email

---

## Usage

### Interactive Mode

Run the command and it will prompt you for the feature name:

```bash
mason make feature --output-dir lib/features
```

### Inline Mode (no prompts)

```bash
mason make feature --feature_name user_profile --output-dir lib/features
```

### Examples

**Feature directly in `lib/features/`:**

```bash
mason make feature --feature_name user_profile --output-dir lib/features
```

**Feature nested under a user type:**

```bash
mason make feature --feature_name order_management --output-dir lib/features/customer
```

```bash
mason make feature --feature_name store_management --output-dir lib/features/business
```

The `--output-dir` flag controls where the feature folder is placed. The generated files use relative imports, so they work regardless of where you put them.

### Auto-Registration in `app_page.dart`

After generating a feature, the brick's **post-generation hook** automatically:

1. Finds your project's `app_page.dart` at `lib/app/view/app_page.dart`
2. Reads the package name from `pubspec.yaml`
3. Adds the required imports (cubit + repository implementation)
4. Inserts a `BlocProvider` entry into the `MultiBlocProvider` providers list
5. Runs `dart format` on the file

**Requirements:**
- Your project must have `lib/app/view/app_page.dart` with a `MultiBlocProvider`
- The `--output-dir` must be inside `lib/` (e.g., `lib/features/customer`)
- If the cubit is already registered, it will be skipped (no duplicates)

To disable hooks during generation:
```bash
mason make feature --feature_name user_profile --output-dir lib/features --no-hooks
```

### Conflict Handling

If files already exist, Mason will ask how to handle them. You can also pass a flag:

```bash
# Skip existing files
mason make feature --feature_name user_profile --output-dir lib/features --on-conflict skip

# Overwrite existing files
mason make feature --feature_name user_profile --output-dir lib/features --on-conflict overwrite
```

---

## Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `feature_name` | The name of the feature in snake_case | `user_profile` |

---

## Generated Structure

```
{feature_name}/
├── data/
│   └── repositories/
│       └── {feature_name}_repository_impl.dart
├── domain/
│   └── repositories/
│       └── {feature_name}_repository.dart
└── presentation/
    ├── cubit/
    │   ├── cubit.dart
    │   └── state.dart
    ├── views/
    └── widgets/
```

### What Each File Contains

**`domain/repositories/{feature_name}_repository.dart`**
```dart
abstract class UserProfileRepository {}
```

**`data/repositories/{feature_name}_repository_impl.dart`**
```dart
import '../../domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl
    implements UserProfileRepository {}
```

**`presentation/cubit/state.dart`**
```dart
import 'package:equatable/equatable.dart';

class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}
```

**`presentation/cubit/cubit.dart`**
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit({
    required this.repository,
  }) : super(const UserProfileState());

  final UserProfileRepository repository;
}
```
