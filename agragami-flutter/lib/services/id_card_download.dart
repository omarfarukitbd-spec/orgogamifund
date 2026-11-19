/// PNG ফাইল নামানো — মোবাইল, ওয়েব আর কম্পিউটারে আলাদা উপায়।
/// এই ফাইলটি শুধু সঠিক প্ল্যাটফর্মের ফাইলটি বেছে দেয়।
/// Phase 5 (F34): ওয়েব শনাক্তকরণে dart.library.js_interop
/// ব্যবহার হয় (dart.library.html আর রক্ষণাবেক্ষণ হয় না)।
library;

export 'id_card_download_stub.dart'
    if (dart.library.js_interop) 'id_card_download_web.dart'
    if (dart.library.io) 'id_card_download_io.dart';
