import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoommateProfile {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final String job;
  final List<String> tags;
  final int matchPercentage;
  final String budget;
  final String bio;

  const RoommateProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    required this.job,
    required this.tags,
    required this.matchPercentage,
    required this.budget,
    required this.bio,
  });
}

final roommateProfilesProvider = Provider<List<RoommateProfile>>((ref) {
  return [
    const RoommateProfile(
      id: '1',
      name: 'Minh Hằng',
      age: 22,
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      job: 'Sinh viên NEU',
      tags: ['Sạch sẽ', 'Cú đêm', 'Yêu mèo'],
      matchPercentage: 98,
      budget: '2.5tr - 3.5tr',
      bio:
          'Mình đang tìm 1 bạn nữ ở ghép khu vực Hai Bà Trưng. Mình có nuôi 1 bé mèo Anh lông ngắn siêu ngoan.',
    ),
    const RoommateProfile(
      id: '2',
      name: 'Hoàng Nam',
      age: 25,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      job: 'IT Developer',
      tags: ['Gọn gàng', 'Thích yên tĩnh', 'Không hút thuốc'],
      matchPercentage: 95,
      budget: '3tr - 4tr',
      bio:
          'Đi làm cả ngày, tối về chỉ cần chỗ ngủ yên tĩnh. Thỉnh thoảng cày game cuối tuần.',
    ),
    const RoommateProfile(
      id: '3',
      name: 'Phương Thảo',
      age: 21,
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      job: 'Sinh viên FTU',
      tags: ['Hay nấu ăn', 'Ngủ sớm', 'Hòa đồng'],
      matchPercentage: 88,
      budget: '2tr - 3tr',
      bio:
          'Mình thích tự nấu ăn mang đi học. Cuối tuần hay rủ bạn bè qua chơi sương sương.',
    ),
    const RoommateProfile(
      id: '4',
      name: 'Trần Vũ',
      age: 24,
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      job: 'Designer',
      tags: ['Sống chill', 'Cú đêm', 'Chơi đàn'],
      matchPercentage: 75,
      budget: '3.5tr - 5tr',
      bio:
          'Cần tìm người share tiền thuê chung cư mini. Phòng đã có đủ đồ đạc, chỉ việc xách vali vào ở.',
    ),
  ];
});
