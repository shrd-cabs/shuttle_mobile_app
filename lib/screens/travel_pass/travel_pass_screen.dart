// ===============================================================
// travel_pass_screen.dart
// ---------------------------------------------------------------
// Travel Pass Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Shows Travel Pass tabs:
// 1. Available Passes
// 2. My Passes
// 3. Usage History
//
// Handles:
// - Load pass data
// - Pass details
// - Wallet pass purchase
// - Mixed Wallet + Razorpay purchase
// - Full Razorpay purchase
// ===============================================================

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../../services/travel_pass_service.dart';

class TravelPassScreen extends StatefulWidget {
  final Future<void> Function()? onWalletUpdated;

  const TravelPassScreen({
    super.key,
    this.onWalletUpdated,
  });

  @override
  State<TravelPassScreen> createState() => _TravelPassScreenState();
}

class _TravelPassScreenState extends State<TravelPassScreen> {
  final travelPassService = TravelPassService();
  final storageService = StorageService();

  late Razorpay razorpay;

  bool isLoading = true;
  bool isProcessing = false;

  String currentTab = 'available';

  String userEmail = '';
  String userName = '';
  String userPhone = '';

  List<Map<String, dynamic>> passTypes = [];
  List<Map<String, dynamic>> myPasses = [];
  List<Map<String, dynamic>> usageHistory = [];

  Map<String, dynamic>? selectedPass;

  double totalAmount = 0;
  double walletBalance = 0;
  bool useWallet = false;
  double walletUsed = 0;
  double onlineAmount = 0;

  @override
  void initState() {
    super.initState();

    razorpay = Razorpay();

    razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      handlePaymentSuccess,
    );

    razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      handlePaymentError,
    );

    razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      handleExternalWallet,
    );

    initTravelPass();
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  Future<void> initTravelPass() async {
    try {
      final user = await storageService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      userEmail = '${user['email'] ?? ''}';
      userName = '${user['name'] ?? 'User'}';
      userPhone = '${user['phone'] ?? ''}';

      if (userEmail.isEmpty) {
        throw Exception('User not logged in');
      }

      setState(() {
        isLoading = true;
        currentTab = 'available';
      });

      await loadAllTravelPassData();

      if (!mounted) return;

      setState(() => isLoading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(error.toString());
    }
  }

  Future<void> loadAllTravelPassData() async {
    final passTypesRes = await travelPassService.getPassTypes();

    final myPassesRes = await travelPassService.getMyPasses(
      userEmail: userEmail,
    );

    final usageRes = await travelPassService.getPassUsageHistory(
      userEmail: userEmail,
    );

    passTypes = ((passTypesRes['passTypes'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    myPasses = ((myPassesRes['myPasses'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    usageHistory = ((usageRes['usageHistory'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> refreshTravelPass() async {
    try {
      await loadAllTravelPassData();

      if (!mounted) return;

      setState(() {});
    } catch (error) {
      showMessage(error.toString());
    }
  }

  Future<void> buyTripPass(
    Map<String, dynamic> pass,
  ) async {
    if (userEmail.isEmpty) {
      showMessage('User not logged in');
      return;
    }

    final hasActivePass = myPasses.any((item) {
      final status = '${item['computed_status'] ?? item['status'] ?? ''}'
          .toUpperCase();

      return status == 'ACTIVE' || status == 'DAILY_LIMIT_REACHED';
    });

    if (hasActivePass) {
      showMessage('You already have an active pass.');
      return;
    }

    try {
      setState(() => isProcessing = true);

      final balance = await travelPassService.getWalletBalance(
        email: userEmail,
      );

      selectedPass = pass;
      totalAmount = double.tryParse('${pass['pass_price'] ?? 0}') ?? 0;
      walletBalance = balance;
      useWallet = false;
      walletUsed = 0;
      onlineAmount = totalAmount;

      if (!mounted) return;

      setState(() => isProcessing = false);

      showPassPurchaseDialog();
    } catch (error) {
      if (!mounted) return;

      setState(() => isProcessing = false);
      showMessage(error.toString());
    }
  }

  void updatePurchaseAmounts() {
    if (useWallet) {
      walletUsed = walletBalance < totalAmount ? walletBalance : totalAmount;
    } else {
      walletUsed = 0;
    }

    onlineAmount = totalAmount - walletUsed;
  }

  Future<void> confirmPassPurchaseSummary() async {
    if (isProcessing) return;

    final pass = selectedPass;

    if (pass == null || '${pass['pass_type_id'] ?? ''}'.isEmpty) {
      showMessage('Pass details missing');
      return;
    }

    try {
      setState(() => isProcessing = true);

      final passTypeId = '${pass['pass_type_id']}';

      if (walletUsed > 0 && onlineAmount == 0) {
        final result = await travelPassService.processWalletPassPayment(
          userEmail: userEmail,
          passTypeId: passTypeId,
          amount: totalAmount,
        );

        await handlePassPurchaseCompleted(
          result['message'] ?? 'Pass purchased successfully using wallet',
        );

        return;
      }

      final orderAmount = walletUsed > 0 && onlineAmount > 0
          ? onlineAmount
          : totalAmount;

      final order = await travelPassService.createPassOrder(
        amount: orderAmount,
        email: userEmail,
        passTypeId: passTypeId,
      );

      final description = walletUsed > 0 && onlineAmount > 0
          ? '${pass['pass_name'] ?? 'Travel Pass'} (Wallet + Online)'
          : '${pass['pass_name'] ?? 'Travel Pass'}';

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': order['amount'],
        'currency': order['currency'] ?? 'INR',
        'order_id': order['id'],
        'name': 'SHRD Shuttle',
        'description': description,
        'prefill': {
          'name': userName,
          'email': userEmail,
          'contact': userPhone,
        },
        'notes': {
          'purpose': 'travel_pass_purchase',
          'email': userEmail,
          'pass_type_id': passTypeId,
        },
        'theme': {
          'color': '#6B46C1',
        },
      };

      razorpay.open(options);
    } catch (error) {
      if (!mounted) return;

      setState(() => isProcessing = false);
      Navigator.pop(context);
      showMessage(error.toString());
    }
  }

  Future<void> handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    final pass = selectedPass;

    if (pass == null) {
      setState(() => isProcessing = false);
      showMessage('Pass details missing');
      return;
    }

    try {
      final passTypeId = '${pass['pass_type_id']}';

      Map<String, dynamic> result;

      if (walletUsed > 0 && onlineAmount > 0) {
        result = await travelPassService.verifyMixedPassPayment(
          userEmail: userEmail,
          passTypeId: passTypeId,
          walletAmount: walletUsed,
          onlineAmount: onlineAmount,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      } else {
        result = await travelPassService.verifyPassPayment(
          userEmail: userEmail,
          passTypeId: passTypeId,
          amount: totalAmount,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      }

      await handlePassPurchaseCompleted(
        result['message'] ?? 'Pass purchased successfully',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isProcessing = false);
      showMessage(
        'Payment successful, but pass activation failed. Please contact support.',
      );
    }
  }

  Future<void> handlePassPurchaseCompleted(
    String message,
  ) async {
    await refreshTravelPass();

    if (widget.onWalletUpdated != null) {
      await widget.onWalletUpdated!();
    }

    if (!mounted) return;

    setState(() {
      isProcessing = false;
      selectedPass = null;
      totalAmount = 0;
      walletBalance = 0;
      useWallet = false;
      walletUsed = 0;
      onlineAmount = 0;
      currentTab = 'myPasses';
    });

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    showMessage(message);
  }

  void handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (!mounted) return;

    setState(() => isProcessing = false);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    showMessage(
      response.message ?? 'Payment failed or cancelled',
    );
  }

  void handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    showMessage(
      'External wallet selected: ${response.walletName ?? ''}',
    );
  }

  Future<void> openPassDetails(
    String userPassId,
  ) async {
    try {
      showLoadingDialog();

      final data = await travelPassService.getPassDetails(
        userPassId: userPassId,
        userEmail: userEmail,
      );

      if (!mounted) return;

      Navigator.pop(context);

      final pass = Map<String, dynamic>.from(data['pass'] ?? {});

      final history = ((data['usageHistory'] ?? []) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      showPassDetailsDialog(
        pass: pass,
        usageHistoryList: history,
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.pop(context);
      showMessage(error.toString());
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void showPassPurchaseDialog() {
    updatePurchaseAmounts();

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _purchaseHeader(),
                      const SizedBox(height: 18),
                      _summaryCard(
                        title: 'Pass Details',
                        children: [
                          _summaryRow(
                            'Pass Name',
                            '${selectedPass?['pass_name'] ?? '-'}',
                          ),
                          _summaryRow(
                            'Pass Price',
                            formatAmount(totalAmount),
                            highlight: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _summaryCard(
                        title: 'Wallet',
                        children: [
                          _summaryRow(
                            'Wallet Balance',
                            formatAmount(walletBalance),
                          ),
                          CheckboxListTile(
                            value: useWallet,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'Use wallet balance',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onChanged: isProcessing
                                ? null
                                : (value) {
                                    dialogSetState(() {
                                      useWallet = value ?? false;
                                      updatePurchaseAmounts();
                                    });

                                    setState(() {});
                                  },
                          ),
                          _summaryRow(
                            'Wallet Used',
                            formatAmount(walletUsed),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xffF3EDFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xff6B46C1)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Pay Online',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff111827),
                                ),
                              ),
                            ),
                            Text(
                              formatAmount(onlineAmount),
                              style: const TextStyle(
                                color: Color(0xff6B46C1),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _warningBox(),
                      const SizedBox(height: 20),
                      _purchaseButtons(dialogSetState),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _purchaseHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy Travel Pass',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Complete your pass purchase securely',
                style: TextStyle(
                  color: Color(0xff6B7280),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: isProcessing ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xff6B46C1) : const Color(0xff111827),
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffFDBA74)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xffEA580C),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment in progress. Do not close this screen. Wait until your pass activation confirmation is received.',
              style: TextStyle(
                color: Color(0xff9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchaseButtons(
    void Function(void Function()) dialogSetState,
  ) {
    String buttonText;

    if (onlineAmount == 0 && walletUsed > 0) {
      buttonText = 'Pay ${formatAmount(totalAmount)} via Wallet';
    } else if (onlineAmount > 0 && walletUsed > 0) {
      buttonText = 'Pay ${formatAmount(onlineAmount)} Online';
    } else {
      buttonText = 'Pay ${formatAmount(totalAmount)} via Razorpay';
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isProcessing
                ? null
                : () async {
                    dialogSetState(() {});
                    await confirmPassPurchaseSummary();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6B46C1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  void showPassDetailsDialog({
    required Map<String, dynamic> pass,
    required List<Map<String, dynamic>> usageHistoryList,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailsHeader(pass),
                  const SizedBox(height: 18),
                  _detailSection(
                    title: 'Basic Information',
                    items: {
                      'User Pass ID': '${pass['user_pass_id'] ?? '-'}',
                      'Pass Type ID': '${pass['pass_type_id'] ?? '-'}',
                      'Status':
                          '${pass['computed_status'] ?? pass['status'] ?? '-'}',
                      'Pass Code': '${pass['pass_code'] ?? '-'}',
                      'Description': '${pass['description'] ?? '-'}',
                      'User Email': '${pass['user_email'] ?? '-'}',
                    },
                  ),
                  _detailSection(
                    title: 'Validity Information',
                    items: {
                      'Purchase Date':
                          formatDisplayDateTime(pass['purchase_date']),
                      'Start Date': formatDisplayDateTime(pass['start_date']),
                      'Expiry Date': formatDisplayDateTime(pass['expiry_date']),
                      'Last Used At':
                          formatDisplayDateTime(pass['last_used_at']),
                    },
                  ),
                  _detailSection(
                    title: 'Payment Information',
                    items: {
                      'Pass Price': formatAmount(pass['pass_price']),
                      'Purchase Amount': formatAmount(pass['purchase_amount']),
                      'Payment Type': '${pass['payment_type'] ?? '-'}',
                      'Payment Status': '${pass['payment_status'] ?? '-'}',
                      'Razorpay Order ID':
                          '${pass['razorpay_order_id'] ?? '-'}',
                      'Razorpay Payment ID':
                          '${pass['razorpay_payment_id'] ?? '-'}',
                    },
                  ),
                  _detailSection(
                    title: 'Discount Rules',
                    items: {
                      'Discount Type': '${pass['discount_type'] ?? '-'}',
                      'Discount Value':
                          '${double.tryParse('${pass['discount_value'] ?? 0}') ?? 0}%',
                      'Max Discount Amount':
                          formatAmount(pass['max_discount_amount']),
                      'Min Fare Amount': formatAmount(pass['min_fare_amount']),
                      'Applicable Routes':
                          '${pass['applicable_routes'] ?? '-'}',
                      'Usage Count': '${pass['usage_count'] ?? 0}',
                      'Remaining Trips': '${pass['remaining_trips'] ?? '-'}',
                      'Today\'s Usage':
                          '${pass['today_usage_count'] ?? 0}',
                      'Today\'s Remaining':
                          '${pass['remaining_trips_today'] ?? '-'}',
                    },
                  ),
                  _recentUsageSection(usageHistoryList),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6B46C1),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailsHeader(
    Map<String, dynamic> pass,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${pass['pass_name'] ?? '-'}',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xff111827),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _detailSection({
    required String title,
    required Map<String, String> items,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          ...items.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xff6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: Color(0xff111827),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentUsageSection(
    List<Map<String, dynamic>> list,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Usage',
            style: TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            const Text(
              'No usage available for this pass.',
              style: TextStyle(color: Color(0xff6B7280)),
            )
          else
            ...list.map(
              (item) => _usageMiniCard(item),
            ),
        ],
      ),
    );
  }

  Widget _usageMiniCard(
    Map<String, dynamic> item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniRow('Booking ID', '${item['booking_id'] ?? '-'}'),
          _miniRow('Travel Date', formatDisplayDateTime(item['travel_date'])),
          _miniRow('Route', '${item['route_id'] ?? '-'}'),
          _miniRow('Original Fare', formatAmount(item['original_fare'])),
          _miniRow('Discount', formatAmount(item['discount_amount'])),
          _miniRow('Final Fare', formatAmount(item['final_fare'])),
        ],
      ),
    );
  }

  Widget _miniRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff6B7280),
                fontSize: 12,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xff111827),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void changeTab(
    String tab,
  ) {
    setState(() => currentTab = tab);
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  String formatAmount(
    dynamic amount,
  ) {
    final value = double.tryParse('${amount ?? 0}') ?? 0;
    return '₹${value.toStringAsFixed(0)}';
  }

  String formatDisplayDateTime(
    dynamic value,
  ) {
    if (value == null || '$value'.trim().isEmpty || '$value' == '-') {
      return '-';
    }

    final str = '$value'.trim();

    final isoPattern = RegExp(r'^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2})');
    final match = isoPattern.firstMatch(str);

    if (match != null) {
      return '${match.group(1)} Time - ${match.group(2)}';
    }

    final parsedDate = DateTime.tryParse(str);

    if (parsedDate != null) {
      final year = parsedDate.year.toString().padLeft(4, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final day = parsedDate.day.toString().padLeft(2, '0');
      final hour = parsedDate.hour.toString().padLeft(2, '0');
      final minute = parsedDate.minute.toString().padLeft(2, '0');

      return '$year-$month-$day Time - $hour:$minute';
    }

    return str;
  }

  @override
    Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: refreshTravelPass,
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                child: Column(
                    children: [
                    const Text(
                        'Travel Pass',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        color: Color(0xff333333),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    const SizedBox(height: 18),
                    _tabs(),
                    const SizedBox(height: 22),
                    if (currentTab == 'available') _availablePasses(),
                    if (currentTab == 'myPasses') _myPasses(),
                    if (currentTab == 'usage') _usageHistory(),
                    ],
                ),
                ),
            ),
    );
    }

  Widget _tabs() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        _tabButton('available', 'Available\nPasses'),
        const SizedBox(width: 10),
        _tabButton('myPasses', 'My Passes'),
        const SizedBox(width: 10),
        _tabButton('usage', 'Usage History'),
        ],
    );
    }

  Widget _tabButton(String tab, String label) {
    final active = currentTab == tab;

    return Expanded(
        child: InkWell(
        onTap: () => changeTab(tab),
        borderRadius: BorderRadius.circular(7),
        child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
            color: active ? const Color(0xff6B46C1) : const Color(0xffEEEEEE),
            borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xff222222),
                fontWeight: FontWeight.w600,
                fontSize: 13,
            ),
            ),
        ),
        ),
    );
    }

  Widget _availablePasses() {
    if (passTypes.isEmpty) {
      return _emptyBox('No passes available right now.');
    }

    return Column(
      children: passTypes.map(_availablePassCard).toList(),
    );
  }

  Widget _availablePassCard(
    Map<String, dynamic> pass,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _passHeader(
            title: '${pass['pass_name'] ?? '-'}',
            trailing: '${pass['pass_code'] ?? '-'}',
            subtitle: '${pass['description'] ?? '-'}',
          ),
          const SizedBox(height: 16),
          Text(
            formatAmount(pass['pass_price']),
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _infoGrid([
            _infoBox('Discount', '${pass['discount_value'] ?? 0}%'),
            _infoBox('Validity', '${pass['validity_days'] ?? 0} Days'),
            _infoBox(
              'Total Trips',
              '${pass['max_usage_total'] ?? ''}'.isEmpty
                  ? 'Unlimited'
                  : '${pass['max_usage_total']}',
            ),
            _infoBox(
              'Trips / Day',
              '${pass['max_usage_per_day'] ?? ''}'.isEmpty
                  ? 'Unlimited'
                  : '${pass['max_usage_per_day']}',
            ),
          ]),
          const SizedBox(height: 14),
          _infoGrid([
            _infoBox('Min Fare', formatAmount(pass['min_fare_amount'])),
            _infoBox('Max Discount', formatAmount(pass['max_discount_amount'])),
          ]),
          const SizedBox(height: 14),
          _fullInfoBox(
            'Applicable Routes',
            '${pass['applicable_routes'] ?? 'ALL'}',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => buyTripPass(pass),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6B46C1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Buy Pass',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _myPasses() {
    if (myPasses.isEmpty) {
      return _emptyBox('No pass purchased yet.');
    }

    return Column(
      children: myPasses.map(_myPassCard).toList(),
    );
  }

  Widget _myPassCard(
    Map<String, dynamic> pass,
  ) {
    final status = '${pass['computed_status'] ?? pass['status'] ?? '-'}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _passHeader(
            title: '${pass['pass_name'] ?? '-'}',
            trailing: status,
          ),
          const SizedBox(height: 8),
          Text(
            'Purchased on ${formatDisplayDateTime(pass['purchase_date'])} • Valid till ${formatDisplayDateTime(pass['expiry_date'])}',
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _infoGrid([
            _infoBox('Purchase Amount', formatAmount(pass['purchase_amount'])),
            _infoBox('Discount', '${pass['discount_value'] ?? 0}%'),
          ]),
          const SizedBox(height: 14),
          _infoGrid([
            _infoBox('Total Usage', '${pass['usage_count'] ?? 0}'),
            _infoBox('Remaining Trips', '${pass['remaining_trips'] ?? '-'}'),
            _infoBox('Today\'s Usage', '${pass['today_usage_count'] ?? 0}'),
            _infoBox(
              'Today\'s Remaining',
              '${pass['remaining_trips_today'] ?? '-'}',
            ),
          ]),
          const SizedBox(height: 14),
          _fullInfoBox(
            'Payment Type',
            '${pass['payment_type'] ?? '-'}',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => openPassDetails(
                '${pass['user_pass_id'] ?? ''}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6B46C1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageHistory() {
    if (usageHistory.isEmpty) {
      return _emptyBox('No pass usage found.');
    }

    return Column(
      children: usageHistory.map(_usageCard).toList(),
    );
  }

  Widget _usageCard(
    Map<String, dynamic> item,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniRow('Booking ID', '${item['booking_id'] ?? '-'}'),
          _miniRow('Travel Date', formatDisplayDateTime(item['travel_date'])),
          _miniRow('Route', '${item['route_id'] ?? '-'}'),
          _miniRow('From', '${item['from_stop'] ?? '-'}'),
          _miniRow('To', '${item['to_stop'] ?? '-'}'),
          _miniRow('Original Fare', formatAmount(item['original_fare'])),
          _miniRow('Discount', formatAmount(item['discount_amount'])),
          _miniRow('Final Fare', formatAmount(item['final_fare'])),
          _miniRow('Used At', formatDisplayDateTime(item['used_at'])),
        ],
      ),
    );
  }

  Widget _passHeader({
    required String title,
    required String trailing,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xffF3EDFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoGrid(List<Widget> children) {
    return LayoutBuilder(
        builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map(
                (child) => SizedBox(
                    width: itemWidth,
                    child: child,
                ),
                )
                .toList(),
        );
        },
    );
    }

  Widget _infoBox(
    String label,
    String value,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 430
          ? (MediaQuery.of(context).size.width - 62) / 2
          : 180,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xff111827),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullInfoBox(
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff6B7280),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff111827),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xff6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}