import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/{{feature_name.snakeCase()}}_repository.dart';
import 'state.dart';

class {{feature_name.pascalCase()}}Cubit extends Cubit<{{feature_name.pascalCase()}}State> {
  {{feature_name.pascalCase()}}Cubit({
    required this.repository,
  }) : super(const {{feature_name.pascalCase()}}State());

  final {{feature_name.pascalCase()}}Repository repository;
}
