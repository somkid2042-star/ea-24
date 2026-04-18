import 'dart:io';

import 'package:flutterquiz/features/profile_management/models/user_profile.dart';
import 'package:flutterquiz/features/profile_management/profile_management_local_data_source.dart';
import 'package:flutterquiz/features/profile_management/profile_management_remote_data_source.dart';

final class ProfileManagementRepository {
  factory ProfileManagementRepository() {
    _profileManagementRepository._profileManagementLocalDataSource =
        ProfileManagementLocalDataSource();
    _profileManagementRepository._profileManagementRemoteDataSource =
        ProfileManagementRemoteDataSource();

    return _profileManagementRepository;
  }

  ProfileManagementRepository._internal();

  static final ProfileManagementRepository _profileManagementRepository =
      ProfileManagementRepository._internal();
  late ProfileManagementLocalDataSource _profileManagementLocalDataSource;
  late ProfileManagementRemoteDataSource _profileManagementRemoteDataSource;

  ProfileManagementLocalDataSource get profileManagementLocalDataSource =>
      _profileManagementLocalDataSource;

  Future<void> deleteAccount() async {
    await _profileManagementRemoteDataSource.deleteAccount();
  }

  Future<void> setUserDetailsLocally(UserProfile userProfile) async {
    await profileManagementLocalDataSource.setUserUId(userProfile.userId!);
    await profileManagementLocalDataSource.setCoins(userProfile.coins!);
    await profileManagementLocalDataSource.serProfileUrl(
      userProfile.profileUrl!,
    );
    await profileManagementLocalDataSource.setEmail(userProfile.email!);
    await profileManagementLocalDataSource.setFirebaseId(
      userProfile.firebaseId!,
    );
    await profileManagementLocalDataSource.setName(userProfile.name!);
    await profileManagementLocalDataSource.setRank(userProfile.allTimeRank!);
    await profileManagementLocalDataSource.setScore(userProfile.allTimeScore!);
    await profileManagementLocalDataSource.setMobileNumber(
      userProfile.mobileNumber!,
    );
    await profileManagementLocalDataSource.setFCMToken(userProfile.fcmToken!);
    await profileManagementLocalDataSource.setReferCode(userProfile.referCode!);
  }

  Future<UserProfile> getUserDetails() async {
    return UserProfile(
      fcmToken: _profileManagementLocalDataSource.getFCMToken(),
      referCode: _profileManagementLocalDataSource.getReferCode(),
      allTimeRank: _profileManagementLocalDataSource.getRank(),
      allTimeScore: _profileManagementLocalDataSource.getScore(),
      coins: _profileManagementLocalDataSource.getCoins(),
      email: _profileManagementLocalDataSource.getEmail(),
      firebaseId: _profileManagementLocalDataSource.getFirebaseId(),
      mobileNumber: _profileManagementLocalDataSource.getMobileNumber(),
      name: _profileManagementLocalDataSource.getName(),
      profileUrl: _profileManagementLocalDataSource.getProfileUrl(),
      registeredDate: '',
      status: _profileManagementLocalDataSource.getStatus(),
      userId: _profileManagementLocalDataSource.getUserUID(),
    );
  }

  Future<UserProfile> getUserDetailsById() async {
    final result = await _profileManagementRemoteDataSource
        .getUserDetailsById();

    return UserProfile.fromJson(result);
  }

  Future<String> uploadProfilePicture(File? file) async {
    final result = await _profileManagementRemoteDataSource.addProfileImage(
      file,
    );

    return result['profile'].toString();
  }

  Future<({String? coins, String? score})> updateCoins({
    required int? coins,
    required bool addCoin,
    required String title,
    String? type,
  }) async {
    final result = await _profileManagementRemoteDataSource.updateCoins(
      title: title,
      coins: addCoin ? coins.toString() : (coins! * -1).toString(),
      type: type,
    );

    return (
      coins: result['coins'] as String?,
      score: result['score'] as String?,
    );
  }

  Future<void> removeAdsForUser({required bool status}) async {
    await _profileManagementRemoteDataSource.removeAdsForUser(status: status);
  }

  Future<void> updateLanguage({required String languageName}) async {
    await _profileManagementRemoteDataSource.updateLanguage(languageName);
  }

  //update profile method in remote data source
  Future<void> updateProfile({
    required String email,
    required String name,
    required String mobile,
  }) async {
    await _profileManagementRemoteDataSource.updateProfile(
      email: email,
      mobile: mobile,
      name: name,
    );
  }

  Future<bool> watchedDailyAd() async {
    return _profileManagementRemoteDataSource.watchedDailyAd();
  }
}
