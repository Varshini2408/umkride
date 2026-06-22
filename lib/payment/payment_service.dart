import 'dart:async';

enum PaymentStatus { success, failed, pending }

class PaymentService {
  // Mock function untuk simulasi proses bayaran
  static Future<PaymentStatus> processPayment(String method, double amount) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulasi loading
    
    // Logik mudah: Sentiasa berjaya untuk demo
    return PaymentStatus.success;
  }
}
