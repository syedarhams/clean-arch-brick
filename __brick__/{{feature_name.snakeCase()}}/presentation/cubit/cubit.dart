import 'package:{{package_name}}/exports.dart';
import 'package:{{package_name}}/features/{{feature_path}}/{{feature_name.snakeCase()}}/domain/repositories/{{feature_name.snakeCase()}}_repository.dart';
import 'package:{{package_name}}/features/{{feature_path}}/{{feature_name.snakeCase()}}/presentation/cubit/state.dart';

class {{feature_name.pascalCase()}}Cubit extends Cubit<{{feature_name.pascalCase()}}State> {
  {{feature_name.pascalCase()}}Cubit({
    required this.repository,
  }) : super(const {{feature_name.pascalCase()}}State());

  final {{feature_name.pascalCase()}}Repository repository;
}
