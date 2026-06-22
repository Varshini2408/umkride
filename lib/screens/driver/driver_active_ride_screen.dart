import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notification_helper.dart';
import 'driver_main.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final String rideId;
  final String studentName;
  final String studentPhone;
  final String studentUid;
  final String pickup;
  final String dropoff;
  final double fare;
  final String payment;
  const DriverActiveRideScreen({
    super.key,
    required this.rideId,
    required this.studentName,
    required this.studentPhone,
    required this.studentUid,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.payment,
  });
  @override
  State<DriverActiveRideScreen> createState() =>
      _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  String _status = 'ACCEPTED';

  Future<void> _markPickedUp() async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({'status': 'PICKED_UP'});
    setState(() => _status = 'PICKED_UP');
    await NotificationHelper.send(
      toUid: widget.studentUid,
      title: '🚗 Driver Has Picked You Up!',
      message: 'You are now on your way to ${widget.dropoff}. Enjoy your ride!',
    );
  }

  Future<void> _completeRide() async {
    final driverUid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
      'status':      'COMPLETED',
      'completedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(driverUid)
        .update({'totalRides': FieldValue.increment(1)});
    // Notify student
    await NotificationHelper.send(
      toUid: widget.studentUid,
      title: '✅ Ride Completed!',
      message:
          'You have arrived at ${widget.dropoff}. Total: RM ${widget.fare.toStringAsFixed(2)}. Please rate your driver!',
    );
    // Notify driver
    await NotificationHelper.send(
      toUid: driverUid,
      title: '💰 Ride Completed!',
      message:
          'Great job! You earned RM ${widget.fare.toStringAsFixed(2)} from this ride.',
    );
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Ride Completed!'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Great job! The ride has been completed.'),
          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Text('Earned:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('RM ${widget.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ]),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DriverMain()),
                (_) => false),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C5E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Done',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C5E),
        title: const Text('Active Ride',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: _status == 'PICKED_UP'
                    ? Colors.green.withOpacity(0.2)
                    : const Color(0xFFC9A84C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              _status == 'PICKED_UP' ? 'In Ride' : 'Heading to Student',
              style: TextStyle(
                  color: _status == 'PICKED_UP'
                      ? Colors.green : const Color(0xFFC9A84C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Student card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                    color: Color(0xFFC9A84C), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  widget.studentName.isNotEmpty
                      ? widget.studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C5E)),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.studentName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C5E))),
                if (widget.studentPhone.isNotEmpty)
                  Text(widget.studentPhone,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9DB0C8))),
              ]),
              const Spacer(),
              const Text('STUDENT',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9DB0C8))),
            ]),
          ),
          const SizedBox(height: 14),
          // Route card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.circle, color: Colors.green, size: 14),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('PICKUP',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9DB0C8),
                          fontWeight: FontWeight.bold)),
                  Text(widget.pickup,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF0D1F35))),
                ]),
              ]),
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.location_on, color: Colors.red, size: 14),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('DROPOFF',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9DB0C8),
                          fontWeight: FontWeight.bold)),
                  Text(widget.dropoff,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF0D1F35))),
                ]),
              ]),
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.receipt_outlined,
                    color: Color(0xFF1A3C5E), size: 18),
                const SizedBox(width: 8),
                const Text('Earnings',
                    style: TextStyle(color: Color(0xFF9DB0C8))),
                const Spacer(),
                Text('RM ${widget.fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          // Chat button
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _DriverChatQuick(
                          rideId: widget.rideId,
                          studentName: widget.studentName,
                          studentUid: widget.studentUid,
                        ))),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat with Student'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A3C5E),
              side: const BorderSide(color: Color(0xFF1A3C5E)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (_status == 'ACCEPTED')
            ElevatedButton(
              onPressed: _markPickedUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_pin, color: Color(0xFF1A3C5E)),
                    SizedBox(width: 8),
                    Text('STUDENT PICKED UP',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E))),
                  ]),
            ),
          if (_status == 'PICKED_UP') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Student is in the car',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _completeRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C5E),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag, color: Colors.white),
                    SizedBox(width: 8),
                    Text('COMPLETE RIDE',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DriverChatQuick extends StatefulWidget {
  final String rideId;
  final String studentName;
  final String studentUid;
  const _DriverChatQuick({
    required this.rideId,
    required this.studentName,
    required this.studentUid,
  });
  @override
  State<_DriverChatQuick> createState() => _DriverChatQuickState();
}

class _DriverChatQuickState extends State<_DriverChatQuick> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .collection('messages')
        .add({
      'text':      text,
      'senderUid': _uid,
      'isDriver':  true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationHelper.send(
      toUid: widget.studentUid,
      title: '💬 Message from Driver',
      message: text,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat — ${widget.studentName}'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .doc(widget.rideId)
                .collection('messages')
                .orderBy('createdAt')
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(
                  child: CircularProgressIndicator());
              final msgs = snap.data!.docs;
              if (msgs.isEmpty) return const Center(
                  child: Text('No messages yet',
                      style: TextStyle(color: Colors.grey)));
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final d = msgs[i].data() as Map<String, dynamic>;
                  final isMe = d['senderUid'] == _uid;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.orange.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Text(d['text'] ?? '',
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 14)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16)),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.orange.shade800,
              child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _send),
            ),
          ]),
        ),
      ]),
    );
  }
}
