// ===============================================================
// booking_screen.dart
// ---------------------------------------------------------------
// Book Seat Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Displays booking form, loads stops, searches routes,
// renders available routes and updates booking summary.
// ===============================================================

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/payment_summary_model.dart';
import '../../models/route_model.dart';
import '../../models/selected_booking_model.dart';
import '../../models/stop_model.dart';
import '../../services/payment_service.dart';
import '../../services/route_service.dart';
import '../../services/storage_service.dart';
import '../../services/stops_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final stopsService = StopsService();
  final routeService = RouteService();
  final paymentService = PaymentService();
  final storageService = StorageService();

  late Razorpay razorpay;

  List<String> pendingBookingIds = [];
  PaymentSummaryModel? pendingSummary;
  Map<String, dynamic>? pendingUser;

  bool isPreparingPayment = false;
  bool isLoadingStops = true;
  bool isSearching = false;
  bool isRazorpayReady = false;

  String loadingMessage = 'Please wait...';

  String tripType = 'oneway';
  int passengers = 1;
  DateTime selectedDate = DateTime.now();

  List<StopModel> stops = [];
  StopModel? fromStop;
  StopModel? toStop;

  List<RouteModel> routes = [];
  List<RouteModel> onwardRoutes = [];
  List<RouteModel> returnRoutes = [];

  RouteModel? selectedRoute;
  RouteModel? selectedOnwardRoute;
  RouteModel? selectedReturnRoute;

  @override
  void initState() {
    super.initState();
    initializeRazorpay();
    loadStops();
  }

  @override
  void dispose() {
    if (isRazorpayReady) {
      razorpay.clear();
    }
    super.dispose();
  }

  void initializeRazorpay() {
    try {
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

      isRazorpayReady = true;
    } catch (error) {
      isRazorpayReady = false;
      debugPrint('Razorpay initialization failed: $error');
    }
  }

  Future<void> loadStops() async {
    try {
      final data = await stopsService.getStops();

      if (!mounted) return;

      setState(() {
        stops = data;
        isLoadingStops = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => isLoadingStops = false);
      showMessage('Unable to load stops');
    }
  }

  Future<void> checkAvailability() async {
    if (fromStop == null || toStop == null) {
      showMessage('Please select From and To stops');
      return;
    }

    if (fromStop!.stopId == toStop!.stopId) {
      showMessage('From and To stops cannot be same');
      return;
    }

    setState(() {
      isSearching = true;
      clearRoutesOnly();
    });

    try {
      final result = await routeService.searchRoutes(
        tripType: tripType,
        travelDate: apiDate,
        fromStop: fromStop!.stopName,
        toStop: toStop!.stopName,
        seatsRequired: passengers,
      );

      if (!mounted) return;

      setState(() {
        isSearching = false;
        routes = result.routes;
        onwardRoutes = result.onwardRoutes;
        returnRoutes = result.returnRoutes;
      });

      if (!result.success) {
        showMessage(result.message);
        return;
      }

      if (tripType == 'oneway' && routes.isEmpty) {
        showMessage('No trips available');
        return;
      }

      if (tripType == 'roundtrip' &&
          (onwardRoutes.isEmpty || returnRoutes.isEmpty)) {
        showMessage('Round trip routes not available');
        return;
      }

      showMessage('Routes found successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() => isSearching = false);
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> proceedToPayment() async {
    final user = await storageService.getCurrentUser();

    if (user == null) {
      showMessage('Please login again');
      return;
    }

    final booking = SelectedBookingModel(
      tripType: tripType == 'roundtrip' ? 'ROUNDTRIP' : 'ONEWAY',
      travelDate: apiDate,
      pax: passengers,
      fromStop: fromStop?.stopName ?? '',
      toStop: toStop?.stopName ?? '',
      oneWayRoute: selectedRoute,
      onwardRoute: selectedOnwardRoute,
      returnRoute: selectedReturnRoute,
    );

    if (!booking.isValid) {
      showMessage(
        tripType == 'roundtrip'
            ? 'Please select onward and return routes'
            : 'Please select a route first',
      );
      return;
    }

    setState(() {
      isPreparingPayment = true;
      loadingMessage = 'Preparing payment summary...';
    });

    try {
      final summary = await paymentService.preparePaymentSummary(
        booking: booking,
        userEmail: '${user['email'] ?? ''}',
      );

      if (!mounted) return;

      setState(() => isPreparingPayment = false);
      showPaymentSummary(summary);
    } catch (error) {
      if (!mounted) return;

      setState(() => isPreparingPayment = false);
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void showPaymentSummary(PaymentSummaryModel summary) {
    PaymentSummaryModel currentSummary = summary;
    bool modalProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submitPayment() async {
              if (modalProcessing) return;

              final user = await storageService.getCurrentUser();

              if (user == null) {
                showMessage('Please login again');
                return;
              }

              setModalState(() => modalProcessing = true);

              try {
                if (!mounted) return;

                Navigator.pop(context);

                setState(() {
                  isPreparingPayment = true;
                  loadingMessage = currentSummary.onlineAmount == 0 &&
                          currentSummary.walletUsed > 0
                      ? 'Confirming wallet booking...'
                      : 'Creating secure payment order...';
                });

                final bookingIds = await paymentService.createHoldBooking(
                  booking: currentSummary.booking,
                  user: user,
                );

                if (!mounted) return;

                if (currentSummary.walletUsed > 0 &&
                    currentSummary.onlineAmount == 0) {
                  final walletResponse =
                      await paymentService.processWalletBookingPayment(
                    bookingIds: bookingIds,
                    tripType: currentSummary.booking.tripType,
                    email: '${user['email'] ?? ''}',
                    amount: currentSummary.finalAmount,
                    summary: currentSummary,
                  );

                  if (!mounted) return;

                  setState(() => isPreparingPayment = false);

                  if (walletResponse['success'] == true) {
                    clearSelection();
                    showMessage('Booking Confirmed via Wallet!');
                  } else {
                    showMessage(
                      walletResponse['error'] ?? 'Wallet payment failed',
                    );
                  }

                  return;
                }

                pendingBookingIds = bookingIds;
                pendingSummary = currentSummary;
                pendingUser = user;

                final order = await paymentService.createOrder(
                  amount: currentSummary.onlineAmount,
                );

                if (!mounted) return;

                final options = {
                  'key': AppConstants.razorpayKeyId,
                  'amount': order['amount'],
                  'order_id': order['id'],
                  'name': AppConstants.appName,
                  'description': currentSummary.booking.tripType == 'ROUNDTRIP'
                      ? 'Round Trip Seat Booking'
                      : 'Seat Booking',
                  'prefill': {
                    'contact': user['phone'],
                    'email': user['email'],
                  },
                  'theme': {
                    'color': '#6B46C1',
                  },
                };

                if (!isRazorpayReady) {
                  setState(() => isPreparingPayment = false);
                  showMessage(
                    'Payment gateway is unavailable right now. Please try again later.',
                  );
                  return;
                }

                setState(() {
                  loadingMessage = 'Opening Razorpay...';
                });

                await Future.delayed(const Duration(milliseconds: 300));

                setState(() => isPreparingPayment = false);

                try {
                  razorpay.open(options);
                } catch (_) {
                  showMessage(
                    'Unable to start payment right now. Please try again.',
                  );
                }
              } catch (error) {
                if (!mounted) return;

                setState(() => isPreparingPayment = false);
                showMessage(error.toString().replaceFirst('Exception: ', ''));
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.86,
              minChildSize: 0.55,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffFAF7FF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paymentSheetHandle(),
                        const SizedBox(height: 18),
                        const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Review your booking before payment',
                          style: TextStyle(
                            color: Color(0xff4B5563),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _paymentTripCard(currentSummary),
                        const SizedBox(height: 16),
                        _paymentFareCard(currentSummary),
                        const SizedBox(height: 16),
                        _paymentWalletCard(
                          currentSummary: currentSummary,
                          onChanged: modalProcessing
                              ? null
                              : (value) {
                                  setModalState(() {
                                    currentSummary = currentSummary.copyWith(
                                      useWallet: value ?? false,
                                    );
                                  });
                                },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: modalProcessing ? null : submitPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff6B46C1),
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor:
                                  const Color(0xff6B46C1).withValues(alpha: .3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: modalProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(
                                    currentSummary.onlineAmount == 0 &&
                                            currentSummary.walletUsed > 0
                                        ? 'Pay via Wallet'
                                        : 'Proceed to Pay',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _paymentSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _paymentTripCard(PaymentSummaryModel summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Journey Details'),
          const SizedBox(height: 14),
          _paymentRow('Trip Type', summary.booking.tripType),
          const SizedBox(height: 10),
          if (summary.booking.tripType == 'ROUNDTRIP') ...[
            _journeyBlock(
              title: 'Onward',
              route:
                  '${summary.booking.fromStop} → ${summary.booking.toStop}',
              time:
                  '${summary.booking.onwardRoute?.arrivalTime ?? '-'} → ${summary.booking.onwardRoute?.reachingTime ?? '-'}',
            ),
            const SizedBox(height: 12),
            _journeyBlock(
              title: 'Return',
              route:
                  '${summary.booking.toStop} → ${summary.booking.fromStop}',
              time:
                  '${summary.booking.returnRoute?.arrivalTime ?? '-'} → ${summary.booking.returnRoute?.reachingTime ?? '-'}',
            ),
          ] else
            _journeyBlock(
              title: 'One Way',
              route:
                  '${summary.booking.fromStop} → ${summary.booking.toStop}',
              time:
                  '${summary.booking.oneWayRoute?.arrivalTime ?? '-'} → ${summary.booking.oneWayRoute?.reachingTime ?? '-'}',
            ),
        ],
      ),
    );
  }

  Widget _paymentFareCard(PaymentSummaryModel summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Fare Details'),
          const SizedBox(height: 14),
          _paymentRow('Total Fare', formatAmount(summary.originalAmount)),
          _paymentRow(
            'Pass',
            summary.passApplied
                ? '${summary.passDetails?['pass_name'] ?? 'Pass Applied'}'
                : 'No Pass Applied',
          ),
          _paymentRow(
            'Pass Discount',
            summary.passDiscountAmount > 0
                ? '- ${formatAmount(summary.passDiscountAmount)}'
                : formatAmount(0),
            valueColor: summary.passDiscountAmount > 0
                ? Colors.green.shade700
                : null,
          ),
          const Divider(height: 22),
          _paymentRow(
            'Fare After Pass',
            formatAmount(summary.finalAmount),
            boldValue: true,
          ),
        ],
      ),
    );
  }

  Widget _paymentWalletCard({
    required PaymentSummaryModel currentSummary,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Wallet & Payment'),
          const SizedBox(height: 14),
          _paymentRow(
            'Wallet Balance',
            formatAmount(currentSummary.walletBalance),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: currentSummary.useWallet,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Use wallet balance',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff1F2937),
              ),
            ),
            onChanged: onChanged,
          ),
          _paymentRow(
            'Wallet Used',
            formatAmount(currentSummary.walletUsed),
          ),
          const Divider(height: 22),
          _paymentRow(
            'Pay Online',
            formatAmount(currentSummary.onlineAmount),
            boldValue: true,
          ),
        ],
      ),
    );
  }

  Widget _journeyBlock({
    required String title,
    required String route,
    required String time,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            route,
            style: const TextStyle(
              color: Color(0xff111827),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Color(0xff64748B),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void selectOneWayRoute(RouteModel route) {
    setState(() => selectedRoute = route);
    showMessage('Route selected successfully');
  }

  void selectOnwardRoute(RouteModel route) {
    setState(() => selectedOnwardRoute = route);
    showMessage('Onward route selected');
  }

  void selectReturnRoute(RouteModel route) {
    setState(() => selectedReturnRoute = route);
    showMessage('Return route selected');
  }

  void swapStops() {
    setState(() {
      final temp = fromStop;
      fromStop = toStop;
      toStop = temp;
      clearRoutesOnly();
    });
  }

  void clearSelection() {
    setState(() {
      tripType = 'oneway';
      passengers = 1;
      selectedDate = DateTime.now();
      fromStop = null;
      toStop = null;
      clearRoutesOnly();
    });
  }

  void clearRoutesOnly() {
    routes = [];
    onwardRoutes = [];
    returnRoutes = [];
    selectedRoute = null;
    selectedOnwardRoute = null;
    selectedReturnRoute = null;
  }

  Future<void> handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    final summary = pendingSummary;
    final user = pendingUser;

    if (summary == null || user == null || pendingBookingIds.isEmpty) {
      showMessage('Payment successful, but booking data missing');
      return;
    }

    setState(() {
      isPreparingPayment = true;
      loadingMessage = 'Confirming your booking...';
    });

    try {
      Map<String, dynamic> result;

      if (summary.walletUsed > 0 && summary.onlineAmount > 0) {
        result = await paymentService.verifyMixedBookingPayment(
          bookingIds: pendingBookingIds,
          tripType: summary.booking.tripType,
          email: '${user['email'] ?? ''}',
          walletAmount: summary.walletUsed,
          onlineAmount: summary.onlineAmount,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
          summary: summary,
        );
      } else {
        result = await paymentService.confirmBooking(
          bookingIds: pendingBookingIds,
          tripType: summary.booking.tripType,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
          summary: summary,
        );
      }

      if (!mounted) return;

      setState(() => isPreparingPayment = false);

      if (result['success'] == true) {
        pendingBookingIds = [];
        pendingSummary = null;
        pendingUser = null;

        clearSelection();

        showMessage('Booking Confirmed!');
      } else {
        showMessage(result['error'] ?? 'Booking confirmation failed');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => isPreparingPayment = false);
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void handlePaymentError(
    PaymentFailureResponse response,
  ) {
    setState(() => isPreparingPayment = false);

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

  Future<void> pickDate() async {
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        clearRoutesOnly();
      });
    }
  }

  String get apiDate {
    final y = selectedDate.year.toString();
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get formattedDate {
    final d = selectedDate.day.toString().padLeft(2, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final y = selectedDate.year.toString();
    return '$d / $m / $y';
  }

  String get summaryJourney {
    if (tripType == 'roundtrip') {
      final onward = selectedOnwardRoute == null
          ? 'Not selected'
          : '${selectedOnwardRoute!.arrivalTime} → ${selectedOnwardRoute!.reachingTime}';

      final ret = selectedReturnRoute == null
          ? 'Not selected'
          : '${selectedReturnRoute!.arrivalTime} → ${selectedReturnRoute!.reachingTime}';

      return 'Onward: $onward\nReturn: $ret';
    }

    if (selectedRoute == null) return 'Not selected';

    return '${selectedRoute!.arrivalTime} → ${selectedRoute!.reachingTime}';
  }

  String get summaryAmount {
    if (tripType == 'roundtrip') {
      final total = (selectedOnwardRoute?.totalAmount ?? 0) +
          (selectedReturnRoute?.totalAmount ?? 0);

      return total > 0 ? formatAmount(total) : 'Not selected';
    }

    return selectedRoute == null
        ? 'Not selected'
        : formatAmount(selectedRoute!.totalAmount);
  }

  String get summaryRoute {
    if (tripType == 'roundtrip') {
      final onward = selectedOnwardRoute?.routeName ?? 'Not selected';
      final ret = selectedReturnRoute?.routeName ?? 'Not selected';

      return 'Onward: $onward\nReturn: $ret';
    }

    return selectedRoute?.routeName ?? 'Not selected';
  }

  String formatAmount(dynamic amount) {
    final value = double.tryParse('$amount') ?? 0;

    if (value % 1 == 0) {
      return '₹${value.toStringAsFixed(0)}';
    }

    return '₹${value.toStringAsFixed(2)}';
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
          absorbing: isPreparingPayment,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Book Your Seat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333333),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _label('Trip Type'),
                Row(
                  children: [
                    _tripTypeButton('One Way', 'oneway'),
                    _tripTypeButton('Round Trip', 'roundtrip'),
                  ],
                ),
                const SizedBox(height: 20),
                _label('Trip Date'),
                GestureDetector(
                  onTap: pickDate,
                  child: _inputBox(formattedDate, Icons.calendar_today),
                ),
                const SizedBox(height: 20),
                _label('From'),
                _stopDropdown(
                  hint: 'Type and search pickup stop',
                  selectedStop: fromStop,
                  onSelected: (stop) {
                    setState(() {
                      fromStop = stop;
                      clearRoutesOnly();
                    });
                  },
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: swapStops,
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        '⇅',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _label('To'),
                _stopDropdown(
                  hint: 'Type and search drop stop',
                  selectedStop: toStop,
                  onSelected: (stop) {
                    setState(() {
                      toStop = stop;
                      clearRoutesOnly();
                    });
                  },
                ),
                const SizedBox(height: 20),
                _label('Number of Passengers'),
                DropdownButtonFormField<int>(
                  value: passengers,
                  items: [1, 2, 3, 4]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        passengers = value;
                        clearRoutesOnly();
                      });
                    }
                  },
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSearching ? null : checkAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6B46C1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: isSearching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Check Availability',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                _routesSection(),
                const SizedBox(height: 28),
                _bookingSummary(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'Proceed to Payment',
                        true,
                        isPreparingPayment ? null : proceedToPayment,
                        loading: isPreparingPayment,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        'Clear Selection',
                        false,
                        isPreparingPayment ? null : clearSelection,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isPreparingPayment) _screenLoader(),
      ],
    );
  }

  Widget _screenLoader() {
    return Positioned.fill(
      child: Container(
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
                  loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please do not close or touch the screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _routesSection() {
    if (tripType == 'roundtrip') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onwardRoutes.isNotEmpty)
            _routeList('Onward Route', onwardRoutes, true),
          if (returnRoutes.isNotEmpty)
            _routeList('Return Route', returnRoutes, false),
        ],
      );
    }

    if (routes.isEmpty) return const SizedBox();

    return _routeList('Select Available Route', routes, true);
  }

  Widget _routeList(
    String title,
    List<RouteModel> list,
    bool isOnwardOrOneWay,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...list.map(
          (route) {
            final selected = tripType == 'oneway'
                ? selectedRoute?.routeId == route.routeId
                : isOnwardOrOneWay
                    ? selectedOnwardRoute?.routeId == route.routeId
                    : selectedReturnRoute?.routeId == route.routeId;

            return _routeCard(
              route,
              selected,
              () {
                if (tripType == 'oneway') {
                  selectOneWayRoute(route);
                } else if (isOnwardOrOneWay) {
                  selectOnwardRoute(route);
                } else {
                  selectReturnRoute(route);
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _routeCard(
    RouteModel route,
    bool selected,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffF3EDFF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xff6B46C1) : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.routeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Journey: ${route.arrivalTime} → ${route.reachingTime}'),
          Text('Available Seats: ${route.availableSeats}'),
          Text('Fare per Seat: ${formatAmount(route.farePerSeat)}'),
          Text('Total: ${formatAmount(route.totalAmount)}'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selected ? Colors.green : const Color(0xff6B46C1),
                foregroundColor: Colors.white,
              ),
              child: Text(
                selected ? 'Selected ✓' : 'Select Route',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopDropdown({
    required String hint,
    required StopModel? selectedStop,
    required Function(StopModel) onSelected,
  }) {
    if (isLoadingStops) {
      return const TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Loading stops...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
      );
    }

    return Autocomplete<StopModel>(
      displayStringForOption: (stop) => stop.stopName,
      optionsBuilder: (value) {
        final search = value.text.trim().toLowerCase();

        if (search.isEmpty) return stops;

        return stops.where((stop) {
          return stop.stopName.toLowerCase().contains(search) ||
              stop.stopId.toLowerCase().contains(search);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        if (selectedStop != null && controller.text != selectedStop.stopName) {
          controller.text = selectedStop.stopName;
        }

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputDecoration(hint: hint),
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff333333),
        ),
      ),
    );
  }

  Widget _tripTypeButton(String text, String value) {
    final active = tripType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          tripType = value;
          clearRoutesOnly();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0xff6B46C1) : Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.horizontal(
            left: value == 'oneway' ? const Radius.circular(18) : Radius.zero,
            right:
                value == 'roundtrip' ? const Radius.circular(18) : Radius.zero,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _inputBox(String hint, IconData? icon) {
    return AbsorbPointer(
      child: TextField(
        readOnly: true,
        decoration: _inputDecoration(
          hint: hint,
          suffixIcon: icon == null ? null : Icon(icon, size: 18),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _bookingSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Passengers', '$passengers'),
          _summaryRow('Trip Date', formattedDate),
          _summaryRow('Journey Time', summaryJourney, multiLine: true),
          _summaryRow('Total Amount', summaryAmount),
          _summaryRow('Route Name', summaryRoute, multiLine: true),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    bool multiLine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: multiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff6B46C1),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xff1F2937),
                    height: 1.45,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff6B46C1),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xff1F2937),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _actionButton(
    String text,
    bool primary,
    VoidCallback? onPressed, {
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              primary ? const Color(0xff6B46C1) : Colors.grey.shade200,
          foregroundColor: primary ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _paymentRow(
    String title,
    String value, {
    Color? valueColor,
    bool boldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff1F2937),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xff1F2937),
                fontWeight: boldValue ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xff6B46C1),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}