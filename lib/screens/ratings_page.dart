import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingsPage extends StatefulWidget {
  final bool isDriver;
  final String? rideId;
  final String? driverUid;
  const RatingsPage({
    super.key,
    this.isDriver = false,
    this.rideId,
    this.driverUid,
  });
  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final _commentCtrl = TextEditingController();
  double _selectedRating = 5;
  bool _submitting = false;
  bool _alreadyRated = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isDriver && widget.rideId != null) _checkAlreadyRated();
  }

  Future<void> _checkAlreadyRated() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('rideId', isEqualTo: widget.rideId)
        .where('studentUid', isEqualTo: uid)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() => _alreadyRated = true);
    }
  }

  Future<void> _submitRating() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    if (widget.driverUid == null || widget.rideId == null) return;
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final studentName = userDoc.data()?['name'] ?? 'Student';
      final rating = _selectedRating.toInt();

      // Save rating
      await FirebaseFirestore.instance.collection('ratings').add({
        'rideId':     widget.rideId,
        'studentUid': uid,
        'driverUid':  widget.driverUid,
        'studentName': studentName,
        'rating':     rating,
        'comment':    _commentCtrl.text.trim(),
        'createdAt':  FieldValue.serverTimestamp(),
      });

      // Update driver average rating
      final ratingsSnap = await FirebaseFirestore.instance
          .collection('ratings')
          .where('driverUid', isEqualTo: widget.driverUid)
          .get();
      double total = 0;
      for (final r in ratingsSnap.docs) {
        total += (r.data()['rating'] ?? 5).toDouble();
      }
      final avg = total / ratingsSnap.docs.length;
      await FirebaseFirestore.instance
          .collection('users').doc(widget.driverUid)
          .update({'rating': avg});

      // Send notification to driver
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid':   widget.driverUid,
        'title':   'New Rating Received!',
        'message': '$studentName gave you $rating stars — "${_commentCtrl.text.trim()}"',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() { _submitting = false; _alreadyRated = true; });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your rating!'),
                backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDriver
        ? Colors.orange.shade800 : Colors.blue.shade900;
    final driverUidQuery = widget.isDriver
        ? FirebaseAuth.instance.currentUser?.uid
        : widget.driverUid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver
            ? 'My Ratings & Comments' : 'Rate Your Driver'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [
        // Rating input for student
        if (!widget.isDriver && !_alreadyRated && widget.rideId != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate your driver:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                        i < _selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber),
                    onPressed: () => setState(() => _selectedRating = i + 1.0),
                  )),
                ),
                TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Write your comment here...',
                      border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white),
                    onPressed: _submitting ? null : _submitRating,
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT RATING'),
                  ),
                ),
              ],
            ),
          ),

        if (!widget.isDriver && _alreadyRated)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('You have already rated this ride!',
                  style: TextStyle(color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

        // Ratings list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: driverUidQuery == null ? null :
                FirebaseFirestore.instance
                    .collection('ratings')
                    .where('driverUid', isEqualTo: driverUidQuery)
                    .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No ratings yet.',
                        style: TextStyle(color: Colors.grey)));
              }
              final ratings = snap.data!.docs.toList()
                ..sort((a, b) {
                  final at = (a.data() as Map)['createdAt'];
                  final bt = (b.data() as Map)['createdAt'];
                  if (at == null || bt == null) return 0;
                  try { return bt.toDate().compareTo(at.toDate()); }
                  catch (_) { return 0; }
                });
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ratings.length,
                itemBuilder: (_, i) {
                  final r = ratings[i].data() as Map<String, dynamic>;
                  final ts = r['createdAt'];
                  String time = '';
                  if (ts != null) {
                    try {
                      final dt = (ts as dynamic).toDate();
                      time = '${dt.day}/${dt.month}/${dt.year}';
                    } catch (_) {}
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r['studentName'] ?? 'Student',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(time,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: List.generate(5, (j) => Icon(
                              j < (r['rating'] ?? 5)
                                  ? Icons.star : Icons.star_border,
                              color: Colors.amber, size: 18))),
                          const SizedBox(height: 8),
                          Text(r['comment'] ?? ''),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
