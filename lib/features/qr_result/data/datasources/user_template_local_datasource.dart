import '../models/user_qr_template_model.dart';

abstract class UserTemplateLocalDataSource {
  List<UserQrTemplateModel> readAll();
  UserQrTemplateModel? readById(String id);
  Future<void> write(UserQrTemplateModel model);
  Future<void> delete(String id);
  Future<void> clear();
}
