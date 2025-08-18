import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../data/datasources/remote/supabase_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/app_controller.dart';
import '../../presentation/controllers/food_controller.dart';
import '../../presentation/controllers/invitations_controller.dart';
import '../../presentation/controllers/inventory_selection_controller.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  // (Supabase is initialized in main.dart)

  // Data sources
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService());
  sl.registerLazySingleton<SupabaseDataSource>(
    () => SupabaseDataSourceImpl(Supabase.instance.client),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<SupabaseDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));

  // Controllers
  sl.registerFactory(
    () => AuthController(
      signInUseCase: sl<SignInUseCase>(),
      signUpUseCase: sl<SignUpUseCase>(),
      signOutUseCase: sl<SignOutUseCase>(),
    ),
  );

  sl.registerLazySingleton(() => AppController());
  sl.registerLazySingleton(() => FoodController());
  sl.registerLazySingleton(() => InvitationsController());
  sl.registerLazySingleton(() => InventorySelectionController());
}