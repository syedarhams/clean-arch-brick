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

Run the command and answer the prompts:

```bash
mason make feature --output-dir lib/features
```

It will ask you for:
1. Feature name (e.g. `user_profile`)
2. Package name (defaults to `muebly`)
3. User type path (leave empty for none, or enter `customer`, `business`, etc.)

### Inline Mode (no prompts)

Pass all variables directly:

```bash
mason make feature \
  --feature_name user_profile \
  --package_name muebly \
  --feature_path customer \
  --output-dir lib/features/customer
```

### Examples

**Directly in features/ (no user type nesting):**

```bash
mason make feature \
  --feature_name user_profile \
  --package_name muebly \
  --feature_path "" \
  --output-dir lib/features
```

Generates `lib/features/user_profile/` with imports like:
```dart
import 'package:muebly/features/user_profile/domain/repositories/...';
```

**Under a user type (customer):**

```bash
mason make feature \
  --feature_name order_management \
  --package_name muebly \
  --feature_path customer \
  --output-dir lib/features/customer
```

Generates `lib/features/customer/order_management/` with imports like:
```dart
import 'package:muebly/features/customer/order_management/domain/repositories/...';
```

**Under a user type (business):**

```bash
mason make feature \
  --feature_name store_management \
  --package_name muebly \
  --feature_path business \
  --output-dir lib/features/business
```

**Different project:**

```bash
mason make feature \
  --feature_name checkout \
  --package_name my_other_app \
  --feature_path "" \
  --output-dir lib/features
```

### Conflict Handling

If files already exist, Mason will ask how to handle them. You can also pass a flag:

```bash
# Skip existing files
mason make feature --output-dir lib/features --on-conflict skip

# Overwrite existing files
mason make feature --output-dir lib/features --on-conflict overwrite
```

---

## Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `feature_name` | The name of the feature in snake_case | — | `user_profile` |
| `package_name` | The package name from `pubspec.yaml` | `muebly` | `my_app` |
| `feature_path` | Path under `lib/features/` (e.g. `customer`, `business`). Leave empty for no nesting. | `""` (empty) | `customer` |

---

## Generated Structure

```
{feature_name}/
├── data/
│   └── repositories/
│       └── {feature_name}_repository_implementation.dart
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

**`data/repositories/{feature_name}_repository_implementation.dart`**
```dart
import 'package:muebly/features/user_profile/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImplementation
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
import 'package:muebly/exports.dart';
import 'package:muebly/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:muebly/features/user_profile/presentation/cubit/state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit({
    required this.repository,
  }) : super(const UserProfileState());

  final UserProfileRepository repository;
}
```
