import 'avatar_upload.dart';
import 'user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getMyProfile();

  Future<UserProfile> updateProfile({String? name, AvatarUpload? avatar});
}
