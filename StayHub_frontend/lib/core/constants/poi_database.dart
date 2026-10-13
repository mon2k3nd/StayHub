class PoiDatabase {
  static const List<Map<String, dynamic>> hanoiPois = [
    // Giáo dục
    {
      'name': 'ĐH Bách Khoa Hà Nội',
      'lat': 21.0041,
      'lng': 105.8435,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Kinh tế Quốc dân',
      'lat': 21.0000,
      'lng': 105.8423,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Xây Dựng',
      'lat': 21.0028,
      'lng': 105.8430,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Y Hà Nội',
      'lat': 21.0034,
      'lng': 105.8306,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Thủy Lợi',
      'lat': 21.0069,
      'lng': 105.8247,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Quốc Gia Hà Nội',
      'lat': 21.0371,
      'lng': 105.7820,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Sư Phạm Hà Nội',
      'lat': 21.0379,
      'lng': 105.7821,
      'group': 'Giáo dục',
    },
    {
      'name': 'Học viện Báo chí',
      'lat': 21.0378,
      'lng': 105.7891,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Ngoại Thương',
      'lat': 21.0232,
      'lng': 105.8058,
      'group': 'Giáo dục',
    },
    {
      'name': 'Học viện Ngoại Giao',
      'lat': 21.0234,
      'lng': 105.8062,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Giao thông Vận tải',
      'lat': 21.0278,
      'lng': 105.8035,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Công Nghiệp Hà Nội',
      'lat': 21.0543,
      'lng': 105.7351,
      'group': 'Giáo dục',
    },
    {'name': 'ĐH Hà Nội', 'lat': 20.9859, 'lng': 105.7975, 'group': 'Giáo dục'},
    {
      'name': 'Học viện An Ninh',
      'lat': 20.9818,
      'lng': 105.7885,
      'group': 'Giáo dục',
    },
    {
      'name': 'Học viện Bưu chính',
      'lat': 20.9806,
      'lng': 105.7876,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Kiến Trúc',
      'lat': 20.9798,
      'lng': 105.7881,
      'group': 'Giáo dục',
    },

    // Y tế
    {
      'name': 'Bệnh viện Bạch Mai',
      'lat': 21.0008,
      'lng': 105.8402,
      'group': 'Y tế',
    },
    {'name': 'Bệnh viện 108', 'lat': 21.0180, 'lng': 105.8643, 'group': 'Y tế'},
    {
      'name': 'Bệnh viện Việt Đức',
      'lat': 21.0298,
      'lng': 105.8466,
      'group': 'Y tế',
    },
    {
      'name': 'Bệnh viện Nhi TW',
      'lat': 21.0253,
      'lng': 105.8057,
      'group': 'Y tế',
    },
    {
      'name': 'Bệnh viện Phụ Sản TW',
      'lat': 21.0267,
      'lng': 105.8459,
      'group': 'Y tế',
    },
    {
      'name': 'Bệnh viện Xanh Pôn',
      'lat': 21.0315,
      'lng': 105.8361,
      'group': 'Y tế',
    },
    {'name': 'Bệnh viện E', 'lat': 21.0453, 'lng': 105.7845, 'group': 'Y tế'},
    {'name': 'Bệnh viện 103', 'lat': 20.9705, 'lng': 105.7946, 'group': 'Y tế'},

    // Mua sắm & TTTM
    {
      'name': 'AEON Mall Long Biên',
      'lat': 21.0270,
      'lng': 105.9015,
      'group': 'Mua sắm',
    },
    {
      'name': 'AEON Mall Hà Đông',
      'lat': 20.9634,
      'lng': 105.7533,
      'group': 'Mua sắm',
    },
    {
      'name': 'Lotte Center Hà Nội',
      'lat': 21.0319,
      'lng': 105.8123,
      'group': 'Mua sắm',
    },
    {
      'name': 'Lotte Mall Tây Hồ',
      'lat': 21.0716,
      'lng': 105.8118,
      'group': 'Mua sắm',
    },
    {
      'name': 'Vincom Bà Triệu',
      'lat': 21.0125,
      'lng': 105.8493,
      'group': 'Mua sắm',
    },
    {
      'name': 'Vincom Royal City',
      'lat': 21.0031,
      'lng': 105.8159,
      'group': 'Mua sắm',
    },
    {
      'name': 'Vincom Times City',
      'lat': 20.9959,
      'lng': 105.8679,
      'group': 'Mua sắm',
    },
    {
      'name': 'Big C Thăng Long',
      'lat': 21.0076,
      'lng': 105.7941,
      'group': 'Mua sắm',
    },

    // Giao thông
    {
      'name': 'Bến xe Mỹ Đình',
      'lat': 21.0289,
      'lng': 105.7788,
      'group': 'Giao thông',
    },
    {
      'name': 'Bến xe Giáp Bát',
      'lat': 20.9814,
      'lng': 105.8427,
      'group': 'Giao thông',
    },
    {
      'name': 'Bến xe Nước Ngầm',
      'lat': 20.9619,
      'lng': 105.8437,
      'group': 'Giao thông',
    },
    {
      'name': 'Ga Hà Nội',
      'lat': 21.0245,
      'lng': 105.8413,
      'group': 'Giao thông',
    },
    {
      'name': 'Sân bay Nội Bài',
      'lat': 21.2187,
      'lng': 105.8042,
      'group': 'Giao thông',
    },
  ];

  static const List<Map<String, dynamic>> hcmcPois = [
    // Giáo dục
    {
      'name': 'ĐH Khoa học Tự nhiên',
      'lat': 10.7629,
      'lng': 106.6825,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Bách Khoa HCM',
      'lat': 10.7732,
      'lng': 106.6596,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Kinh tế TP.HCM',
      'lat': 10.7829,
      'lng': 106.6953,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Y Dược TP.HCM',
      'lat': 10.7554,
      'lng': 106.6644,
      'group': 'Giáo dục',
    },
    {
      'name': 'ĐH Tôn Đức Thắng',
      'lat': 10.7327,
      'lng': 106.6991,
      'group': 'Giáo dục',
    },
    {'name': 'ĐH RMIT', 'lat': 10.7292, 'lng': 106.6958, 'group': 'Giáo dục'},
    {
      'name': 'Làng ĐH Thủ Đức',
      'lat': 10.8700,
      'lng': 106.8032,
      'group': 'Giáo dục',
    },

    // Y tế
    {
      'name': 'Bệnh viện Chợ Rẫy',
      'lat': 10.7558,
      'lng': 106.6586,
      'group': 'Y tế',
    },
    {
      'name': 'Bệnh viện Đại học Y Dược',
      'lat': 10.7548,
      'lng': 106.6625,
      'group': 'Y tế',
    },
    {
      'name': 'Bệnh viện Từ Dũ',
      'lat': 10.7675,
      'lng': 106.6853,
      'group': 'Y tế',
    },

    // Giao thông
    {
      'name': 'Sân bay Tân Sơn Nhất',
      'lat': 10.8184,
      'lng': 106.6588,
      'group': 'Giao thông',
    },
    {
      'name': 'Bến xe Miền Đông',
      'lat': 10.8122,
      'lng': 106.7118,
      'group': 'Giao thông',
    },
    {
      'name': 'Bến xe Miền Tây',
      'lat': 10.7397,
      'lng': 106.6200,
      'group': 'Giao thông',
    },
    {
      'name': 'Ga Sài Gòn',
      'lat': 10.7828,
      'lng': 106.6775,
      'group': 'Giao thông',
    },
  ];

  static List<Map<String, dynamic>> getAllPois() {
    return [...hanoiPois, ...hcmcPois];
  }
}
