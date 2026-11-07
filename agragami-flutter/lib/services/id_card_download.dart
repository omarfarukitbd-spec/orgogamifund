/// PNG ফাইল নামানো — মোবাইল, ওয়েব আর কম্পিউটারে আলাদা উপায়।
/// এই ফাইলটি শুধু সঠিক প্ল্যাটফর্মের ফাইলটি বেছে দেয়।
library;

export 'id_card_download_stub.dart'
    if (dart.library.html) 'id_card_download_web.dart'
    if (dart.library.io) 'id_card_download_io.dart';
