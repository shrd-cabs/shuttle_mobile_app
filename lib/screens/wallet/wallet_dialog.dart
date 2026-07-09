// ===============================================================
// wallet_dialog.dart
// ---------------------------------------------------------------
// Wallet Dialog
//
// PURPOSE
// ---------------------------------------------------------------
// Shows wallet balance, add-money UI and recent transactions.
// Handles Razorpay wallet top-up.
// ===============================================================

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/wallet_transaction_model.dart';
import '../../services/storage_service.dart';
import '../../services/wallet_service.dart';

class WalletDialog extends StatefulWidget {
  final Future<void> Function()? onWalletUpdated;

  const WalletDialog({
    super.key,
    this.onWalletUpdated,
  });

  @override
  State<WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<WalletDialog> {
  final walletService = WalletService();
  final storageService = StorageService();
  final amountController = TextEditingController();

  late Razorpay razorpay;

  bool isLoading = true;
  bool isProcessing = false;

  String processingMessage = 'Please wait...';

  double walletBalance = 0;
  double pendingAmount = 0;

  String email = '';
  String name = '';
  String phone = '';

  List<WalletTransactionModel> transactions = [];

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

    loadWallet();
  }

  @override
  void dispose() {
    razorpay.clear();
    amountController.dispose();
    super.dispose();
  }

  Future<void> loadWallet() async {
    try {
      final user = await storageService.getCurrentUser();

      if (user == null) {
        throw Exception('Please login again');
      }

      email = '${user['email'] ?? ''}';
      name = '${user['name'] ?? 'User'}';
      phone = '${user['phone'] ?? ''}';

      final balance = await walletService.getWalletBalance(
        email: email,
      );

      final txnList = await walletService.getWalletTransactions(
        email: email,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        walletBalance = balance;
        transactions = txnList;
        isLoading = false;
      });

      user['wallet_balance'] = balance;
      await storageService.saveCurrentUser(user);

      if (widget.onWalletUpdated != null) {
        await widget.onWalletUpdated!();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> handleAddMoney() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;

    if (amount <= 0) {
      showMessage('Please enter a valid amount');
      return;
    }

    if (email.isEmpty) {
      showMessage('Please login again');
      return;
    }

    try {
      setState(() {
        isProcessing = true;
        processingMessage = 'Creating secure wallet order...';
        pendingAmount = amount;
      });

      final order = await walletService.createWalletOrder(
        amount: amount,
      );

      if (!mounted) return;

      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': order['amount'],
        'currency': order['currency'] ?? 'INR',
        'order_id': order['id'],
        'name': 'SHRD Shuttle',
        'description': 'Wallet Top-up',
        'prefill': {
          'name': name,
          'email': email,
          'contact': phone,
        },
        'notes': {
          'purpose': 'wallet_topup',
          'email': email,
        },
        'theme': {
          'color': '#6B46C1',
        },
      };

      setState(() {
        processingMessage = 'Opening Razorpay...';
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() => isProcessing = false);

      try {
        razorpay.open(options);
      } catch (_) {
        showMessage(
          'Unable to start payment right now. Please try again.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => isProcessing = false);
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    try {
      setState(() {
        isProcessing = true;
        processingMessage = 'Verifying wallet payment...';
      });

      await walletService.verifyWalletPayment(
        email: email,
        amount: pendingAmount,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      amountController.clear();

      setState(() {
        processingMessage = 'Refreshing wallet balance...';
      });

      await loadWallet();

      if (!mounted) return;

      setState(() => isProcessing = false);

      showMessage(
        '₹${pendingAmount.toStringAsFixed(0)} added to wallet successfully',
      );

      pendingAmount = 0;
    } catch (_) {
      if (!mounted) return;

      setState(() => isProcessing = false);

      showMessage(
        'Payment successful, but wallet update failed. Please contact support.',
      );
    }
  }

  void handlePaymentError(
    PaymentFailureResponse response,
  ) {
    setState(() => isProcessing = false);

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

  void setAmount(int amount) {
    amountController.text = amount.toString();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isProcessing,
          child: Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: isLoading
                    ? const SizedBox(
                        height: 280,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context),
                          const SizedBox(height: 18),
                          _balanceCard(),
                          const SizedBox(height: 22),
                          _addMoneySection(),
                          const SizedBox(height: 24),
                          _transactionsSection(),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (isProcessing) _screenLoader(),
      ],
    );
  }

  Widget _screenLoader() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        child: Center(
          child: Container(
            width: 270,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xff6B46C1),
                ),
                const SizedBox(height: 18),
                Text(
                  processingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please do not close or touch the screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'My Wallet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
        ),
        IconButton(
          onPressed: isProcessing ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xff6B46C1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${walletBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addMoneySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Money',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _amountChip(100),
            _amountChip(200),
            _amountChip(500),
            _amountChip(1000),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: amountController,
          enabled: !isProcessing,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixText: '₹ ',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isProcessing ? null : handleAddMoney,
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
                    'Proceed to Add Money',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _amountChip(int amount) {
    return InkWell(
      onTap: isProcessing ? null : () => setAmount(amount),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xffF3EDFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xff6B46C1).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          '₹$amount',
          style: const TextStyle(
            color: Color(0xff6B46C1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _transactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No transactions found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...transactions.map(_transactionItem),
      ],
    );
  }

  Widget _transactionItem(WalletTransactionModel txn) {
    final amountColor = txn.isCredit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: amountColor.withValues(alpha: 0.12),
            child: Icon(
              txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txn.createdAt.isEmpty ? '-' : txn.createdAt,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            txn.amountLabel,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}