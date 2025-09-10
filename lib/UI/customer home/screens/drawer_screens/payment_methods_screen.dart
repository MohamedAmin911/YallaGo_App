import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/auth/screens/customer_auth/add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String customerUid;
  const PaymentMethodsScreen({super.key, required this.customerUid});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _db = FirebaseFirestore.instance;
  final _pageCtrl = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAddNewCard() async {
    final customerState = context.read<CustomerCubit>().state;
    if (customerState is! CustomerLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile not loaded')),
      );
      return;
    }
    final user = customerState.customer;

// Reuse your existing AddPaymentMethod screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPaymentMethod(
          redirectToPaymentMethods: true,
          email: user.email ?? '',
          phone: user.phoneNumber,
        ),
      ),
    );
  }

  Future<void> _onSetDefault(
    QueryDocumentSnapshot<Map<String, dynamic>> cardDoc,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
  ) async {
    final pmId = cardDoc.id;
    await context.read<PaymentCubit>().setDefaultPaymentMethod(
        customerUid: widget.customerUid, paymentMethodId: pmId);
  }

  Future<void> _onDelete(
    QueryDocumentSnapshot<Map<String, dynamic>> cardDoc,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
  ) async {
    if (allDocs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't delete your only card.")),
      );
      return;
    }
    final pmId = cardDoc.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This card will be removed from your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    await context.read<PaymentCubit>().detachPaymentMethod(
        customerUid: widget.customerUid, paymentMethodId: pmId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back_ios,
            color: KColor.primaryText,
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PaymentCubit, PaymentState>(
            listener: (context, state) {
              if (state is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('customers')
              .doc(widget.customerUid)
              .collection('payment_methods')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading cards: ${snap.error}'));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _EmptyState(onAdd: _onAddNewCard);
            }

            if (_currentIndex >= docs.length) _currentIndex = docs.length - 1;

            final selectedDoc = docs[_currentIndex];
            final isDefault =
                (selectedDoc.data()['isDefault'] as bool?) ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 22.h),
                //title
                Padding(
                  padding:
                      EdgeInsets.only(left: 16.w, right: 16.w, bottom: 30.h),
                  child: Text(
                    "Payment Methods",
                    style: appStyle(
                      size: 25.sp,
                      color: KColor.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                SizedBox(
                  height: 200.h,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: docs.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final d = docs[index].data();
                      return _PaymentCard(
                        brand: (d['cardBrand'] as String?) ?? 'CARD',
                        last4: (d['last4'] as String?) ?? '••••',
                        isDefault: (d['isDefault'] as bool?) ?? false,
                        index: index,
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: _CardActions(
                    isDefault: isDefault,
                    onSetDefault: () => _onSetDefault(selectedDoc, docs),
                    onDelete: () => _onDelete(selectedDoc, docs),
                    onAdd: _onAddNewCard,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card, size: 56),
            const SizedBox(height: 12),
            const Text('No cards yet'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add a card'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String brand;
  final String last4;
  final bool isDefault;
  final int index;

  const _PaymentCard({
    required this.brand,
    required this.last4,
    required this.isDefault,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
// Colors and styles from your theme
    final primary = KColor.primary;

    final gradient = LinearGradient(
      colors: [
        primary.withOpacity(0.95),
        primary.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final brandUpper = brand.toUpperCase();
    final brandText = brandUpper == 'MASTERCARD' ? 'MASTER CARD' : brandUpper;

    return Container(
// Let the SizedBox above control overall height; fill available
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // instead of Spacer
        children: [
// Brand and default badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                brandText,
                style: appStyle(
                  size: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          // Bottom block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '**** **** **** $last4',
                style: appStyle(
                    size: 22, color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Card',
                      style: appStyle(
                          size: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                  Text('Tap below to manage',
                      style: appStyle(
                          size: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  const _CardActions({
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: RoundButton(
                    title: 'Set default',
                    onPressed: () {
                      isDefault ? null : onSetDefault();
                    },
                    color: isDefault ? KColor.lightGray : KColor.primary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: RoundButton(
                    title: 'Delete',
                    onPressed: () {
                      onDelete();
                    },
                    color: KColor.red,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Add card
          SizedBox(
            height: 50.h,
            width: double.infinity,
            child: ElevatedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: KColor.secondary,
                  side: BorderSide(color: KColor.secondary, width: 3),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: KColor.secondary, width: 3),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  onAdd();
                },
                child: Text(
                  'ADD A NEW CARD',
                  style: appStyle(
                      size: 20.sp,
                      color: KColor.bg,
                      fontWeight: FontWeight.w900),
                )),
          ),
          SizedBox(height: 10.h),
          Row(children: [
            const Spacer(),
            Text(
              'Powered by',
              style: appStyle(
                  size: 12.sp,
                  color: KColor.secondaryText,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 10.w),
            Image.asset(
              KImage.stripeLogo,
              width: 40.w,
            ),
            SizedBox(width: 10.w),
          ])
        ],
      ),
    );
  }
}
