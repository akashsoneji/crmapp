import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../data/datasources/pmam_remote_data_source.dart';
import '../data/repositories/pmam_repository_impl.dart';
import '../domain/repositories/pmam_repository.dart';
import '../domain/usecases/apply_as_manager.dart';
import '../domain/usecases/get_manager_dashboard.dart';
import '../domain/usecases/get_manager_status.dart';
import '../../../controllers/pmam/pmam_controller.dart';

class PmamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PmamRemoteDataSource>(
      () => PmamRemoteDataSource(Get.find<ApiClient>()),
    );
    Get.lazyPut<PmamRepository>(
      () => PmamRepositoryImpl(Get.find<PmamRemoteDataSource>()),
    );

    Get.lazyPut<GetManagerStatus>(
      () => GetManagerStatus(Get.find<PmamRepository>()),
    );
    Get.lazyPut<ApplyAsManager>(
      () => ApplyAsManager(Get.find<PmamRepository>()),
    );
    Get.lazyPut<GetManagerDashboard>(
      () => GetManagerDashboard(Get.find<PmamRepository>()),
    );

    Get.lazyPut<PmamController>(
      () => PmamController(
        getManagerStatus: Get.find<GetManagerStatus>(),
        applyAsManager: Get.find<ApplyAsManager>(),
        getManagerDashboard: Get.find<GetManagerDashboard>(),
        repo: Get.find<PmamRepository>(),
      ),
    );
  }
}

