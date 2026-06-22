import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../history/history_service.dart';
import 'payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedMethod;
  bool _isProcessing = false;
  final Color themeColor = const Color(0xFF6C5CE7);

  final List<Map<String, dynamic>> paymentMethods = [
    {'id': 'cash', 'name': 'Cash', 'icon': Icons.payments_outlined},
    {'id': 'online', 'name': 'Online Banking', 'icon': Icons.account_balance_outlined},
    {'id': 'tng', 'name': 'Touch \'n Go eWallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    final status = await PaymentService.processPayment(
      selectedMethod!, 
      widget.booking.price ?? 0.0
    );

    setState(() => _isProcessing = false);

    if (status == PaymentStatus.success) {
      // Save to history before showing success dialog
      HistoryService.addBooking(widget.booking);
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: _isProcessing ? null : () => Navigator.pop(context)
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountCard(),
                const SizedBox(height: 30),
                const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];
                      bool isSelected = selectedMethod == method['id'];
                      return _buildPaymentMethodItem(method, isSelected);
                    },
                  ),
                ),
                _buildPayButton(),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Payment', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 4),
              Text('UMK Ride Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Text(
            'RM ${widget.booking.price?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method, bool isSelected) {
    return GestureDetector(
      onTap: _isProcessing ? null : () => setState(() => selectedMethod = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? themeColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(method['icon'], color: isSelected ? themeColor : Colors.black54),
            const SizedBox(width: 16),
            Text(method['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: selectedMethod == null || _isProcessing ? null : _handlePayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        selectedMethod == 'cash' ? 'CONFIRM BOOKING' : 'PAY NOW',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('Success!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 12),
            const Text('Your booking has been confirmed. Your driver will arrive shortly.', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('BACK TO HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
