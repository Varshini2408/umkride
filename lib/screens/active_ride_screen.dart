import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_helper.dart';
import 'ratings_page.dart';
import 'student/student_main.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  final String driverUid;
  final String pickup;
  final String dropoff;
  final double fare;
  final String payment;
  const ActiveRideScreen({
    super.key,
    required this.rideId,
    required this.driverUid,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.payment,
  });
  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  Map<String, dynamic>? _driverData;
  String _status = 'ACCEPTED';
  bool _notifiedPickup = false;
  bool _notifiedComplete = false;

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _listenStatus();
  }

  Future<void> _loadDriver() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.driverUid)
        .get();
    if (doc.exists && mounted) {
      setState(() => _driverData = doc.data());
    }
  }

  void _listenStatus() {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists || !mounted) return;
      final status = snap.data()?['status'] ?? 'ACCEPTED';
      if (status != _status) {
        setState(() => _status = status);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        if (status == 'PICKED_UP' && !_notifiedPickup) {
          _notifiedPickup = true;
          await NotificationHelper.send(
            toUid: uid,
            title: '🚗 You\'ve Been Picked Up!',
            message:
                'Your driver has picked you up. Enjoy your ride to ${widget.dropoff}!',
          );
        }
        if (status == 'COMPLETED' && !_notifiedComplete) {
          _notifiedComplete = true;
          // Save completedAt
          await FirebaseFirestore.instance
              .collection('rides')
              .doc(widget.rideId)
              .update({'completedAt': FieldValue.serverTimestamp()});
          await NotificationHelper.send(
            toUid: uid,
            title: '✅ Ride Completed!',
            message:
                'You have arrived at ${widget.dropoff}. Total fare: RM ${widget.fare.toStringAsFixed(2)}',
          );
          if (mounted) _showCompletedDialog();
        }
      }
    });
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Ride Completed!'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('You have arrived at your destination.'),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Fare:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('RM ${widget.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C5E),
                    fontSize: 18)),
          ]),
        ]),
        actions: [
          // Rate driver button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: SizedBox(
                    height: 500,
                    child: RatingsPage(
                      isDriver: false,
                      rideId: widget.rideId,
                      driverUid: widget.driverUid,
                    ),
                  ),
                ),
              ).then((_) => _goHome());
            },
            icon: const Icon(Icons.star, color: Colors.white),
            label: const Text('Rate Driver',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
          TextButton(
            onPressed: _goHome,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => StudentMain()),
        (_) => false);
  }

  String get _statusText {
    switch (_status) {
      case 'ACCEPTED':  return 'Driver is on the way';
      case 'PICKED_UP': return 'You are in the ride!';
      case 'COMPLETED': return 'Ride Completed!';
      default:          return 'Processing...';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'ACCEPTED':  return const Color(0xFFC9A84C);
      case 'PICKED_UP': return Colors.green;
      case 'COMPLETED': return Colors.green;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _statusColor.withOpacity(0.3))),
              child: Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(_statusText,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                        fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 14),
            // Driver card
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
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                      color: Color(0xFF1A3C5E), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    _driverData?['name']?.toString().isNotEmpty == true
                        ? _driverData!['name'].toString()[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC9A84C)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_driverData?['name'] ?? 'Loading...',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E))),
                    Text(_driverData?['phone'] ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9DB0C8))),
                  ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.star,
                        color: Color(0xFFC9A84C), size: 14),
                    const SizedBox(width: 3),
                    Text(
                        (_driverData?['rating'] ?? 5.0).toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC9A84C))),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            // Ride details
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
                _detailRow(Icons.circle, Colors.green, 'From', widget.pickup),
                const Divider(height: 20),
                _detailRow(
                    Icons.location_on, Colors.red, 'To', widget.dropoff),
                const Divider(height: 20),
                Row(children: [
                  const Icon(Icons.receipt_outlined,
                      color: Color(0xFF1A3C5E), size: 18),
                  const SizedBox(width: 8),
                  const Text('Fare',
                      style: TextStyle(color: Color(0xFF9DB0C8))),
                  const Spacer(),
                  Text('RM ${widget.fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A3C5E))),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            // Chat button — always visible during ride
            if (_status == 'ACCEPTED' || _status == 'PICKED_UP')
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _ChatQuickAccess(
                              rideId: widget.rideId,
                              isDriver: false,
                              otherName: _driverData?['name'] ?? 'Driver',
                            ))),
                icon: const Icon(Icons.chat_bubble, color: Colors.white),
                label: const Text('Chat with Driver',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C5E),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (_status == 'ACCEPTED') ...[
              const SizedBox(height: 12),
              const Text('Sit tight! Your driver is on the way.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Color(0xFF9DB0C8), fontSize: 13)),
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                  backgroundColor: Color(0xFFEEF4FF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A3C5E))),
            ],
            if (_status == 'PICKED_UP')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('You are in the ride!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 15)),
                    ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(
      IconData icon, Color color, String label, String value) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9DB0C8),
                fontWeight: FontWeight.bold)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0D1F35),
                fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

// Quick chat access widget
class _ChatQuickAccess extends StatefulWidget {
  final String rideId;
  final bool isDriver;
  final String otherName;
  const _ChatQuickAccess({
    required this.rideId,
    required this.isDriver,
    required this.otherName,
  });
  @override
  State<_ChatQuickAccess> createState() => _ChatQuickAccessState();
}

class _ChatQuickAccessState extends State<_ChatQuickAccess> {
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
      'isDriver':  widget.isDriver,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Notify the other party
    final rideDoc = await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .get();
    final data = rideDoc.data() ?? {};
    final toUid = widget.isDriver
        ? data['studentUid'] : data['driverUid'];
    if (toUid != null) {
      await NotificationHelper.send(
        toUid: toUid,
        title: '💬 New Message',
        message: '${widget.isDriver ? "Driver" : "Student"}: $text',
      );
    }
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
    final themeColor = widget.isDriver
        ? Colors.orange.shade800 : Colors.blue.shade900;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat — ${widget.otherName}'),
        backgroundColor: themeColor,
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
                  child: Text('No messages yet. Say hi!',
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
                        color: isMe ? themeColor : Colors.grey.shade200,
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
              backgroundColor: themeColor,
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
