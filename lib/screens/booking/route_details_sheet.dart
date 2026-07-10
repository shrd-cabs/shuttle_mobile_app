// ===============================================================
// route_details_sheet.dart
// ---------------------------------------------------------------
// Professional Route & Stops bottom sheet.
//
// PURPOSE
// ---------------------------------------------------------------
// Displays scheduled route information before the customer selects
// or books a route.
//
// FEATURES
// ---------------------------------------------------------------
// - Uses the existing getRouteDetails backend API
// - Opens as a draggable bottom sheet
// - Matches the web application's purple visual style
// - Shows pickup and drop-off details
// - Shows journey duration, stop count, and bus number
// - Shows the selected journey timeline
// - Expands to show the complete bus route
// - Handles loading, errors, and retry
//
// IMPORTANT
// ---------------------------------------------------------------
// This sheet does not:
// - Select a route
// - Change booking state
// - Start payment
// - Depend on Live Tracking
// ===============================================================

import 'package:flutter/material.dart';

import '../../models/route_details_model.dart';
import '../../models/route_model.dart';
import '../../models/stop_model.dart';
import '../../services/route_details_service.dart';


// ===============================================================
// PUBLIC BOTTOM-SHEET FUNCTION
// ---------------------------------------------------------------
// Call this function from booking_screen.dart.
//
// One-way / onward:
//   fromStop: selected pickup
//   toStop: selected destination
//
// Return:
//   fromStop: original destination
//   toStop: original pickup
// ===============================================================
Future<void> showRouteDetailsSheet({
  required BuildContext context,
  required RouteModel route,
  required StopModel fromStop,
  required StopModel toStop,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (sheetContext) {
      return RouteDetailsSheet(
        route: route,
        fromStop: fromStop,
        toStop: toStop,
      );
    },
  );
}


// ===============================================================
// ROUTE DETAILS SHEET
// ===============================================================
class RouteDetailsSheet extends StatefulWidget {
  final RouteModel route;
  final StopModel fromStop;
  final StopModel toStop;

  const RouteDetailsSheet({
    super.key,
    required this.route,
    required this.fromStop,
    required this.toStop,
  });

  @override
  State<RouteDetailsSheet> createState() {
    return _RouteDetailsSheetState();
  }
}


// ===============================================================
// ROUTE DETAILS SHEET STATE
// ===============================================================
class _RouteDetailsSheetState extends State<RouteDetailsSheet> {
  final RouteDetailsService routeDetailsService =
      RouteDetailsService();

  RouteDetailsModel? routeDetails;

  bool isLoading = true;
  bool showCompleteRoute = false;

  String errorMessage = '';


  // =============================================================
  // INITIALIZATION
  // =============================================================
  @override
  void initState() {
    super.initState();
    loadRouteDetails();
  }


  // =============================================================
  // LOAD ROUTE DETAILS
  // =============================================================
  Future<void> loadRouteDetails() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      showCompleteRoute = false;
    });

    try {
      final result =
          await routeDetailsService.getRouteDetails(
        routeId: widget.route.routeId,
        fromStopId: widget.fromStop.stopId,
        toStopId: widget.toStop.stopId,
        fromStopName: widget.fromStop.stopName,
        toStopName: widget.toStop.stopName,
      );

      if (!mounted) return;

      setState(() {
        routeDetails = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }


  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xffF8FAFC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: _buildBody(
                  scrollController,
                ),
              ),

              if (!isLoading && errorMessage.isEmpty)
                _buildFooter(),
            ],
          ),
        );
      },
    );
  }


  // =============================================================
  // HEADER
  // =============================================================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        14,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff6B46C1),
            Color(0xff553C9A),
          ],
        ),
      ),
      child: Column(
        children: [
          // Bottom-sheet drag handle.
          Container(
            width: 46,
            height: 5,
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(
                99,
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCHEDULED ROUTE',
                      style: TextStyle(
                        color: Color(0xffDDD6FE),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.route.routeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review scheduled stops before selecting this route.',
                      style: TextStyle(
                        color: Color(0xffEDE9FE),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                ),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }


  // =============================================================
  // BODY
  // =============================================================
  Widget _buildBody(
    ScrollController scrollController,
  ) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    final details = routeDetails;

    if (details == null) {
      return _buildErrorState(
        customMessage:
            'Route details are unavailable.',
      );
    }

    final journeyMatched =
        details.hasMatchedJourney;

    final displayedStops =
        details.displayedStops;

    final pickupName = journeyMatched
        ? details.journey.fromStopName
        : widget.fromStop.stopName;

    final dropName = journeyMatched
        ? details.journey.toStopName
        : widget.toStop.stopName;

    final pickupTime = _formatTime(
      journeyMatched
          ? details.journey.pickupTime
          : widget.route.arrivalTime,
    );

    final dropTime = _formatTime(
      journeyMatched
          ? details.journey.dropTime
          : widget.route.reachingTime,
    );

    final durationMinutes = journeyMatched
        ? details.journey.durationMinutes
        : details.route.durationMinutes;

    final busNumber =
        _firstNonEmpty([
      widget.route.busNumber,
      details.route.busNumber,
      details.route.busId,
      '-',
    ]);

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildJourneyHero(
                  pickupName: pickupName,
                  dropName: dropName,
                  pickupTime: pickupTime,
                  dropTime: dropTime,
                ),

                const SizedBox(height: 14),

                _buildSummaryCards(
                  durationLabel:
                      _formatDuration(
                    durationMinutes,
                  ),
                  stopCount:
                      displayedStops.length,
                  busNumber: busNumber,
                ),

                if (!journeyMatched) ...[
                  const SizedBox(height: 14),
                  _buildJourneyWarning(
                    details.journey.warning,
                  ),
                ],

                const SizedBox(height: 22),

                _buildTimelineHeading(
                  journeyMatched:
                      journeyMatched,
                  stopCount:
                      displayedStops.length,
                ),

                const SizedBox(height: 12),

                _buildTimeline(
                  stops: displayedStops,
                  fullRouteMode: false,
                ),

                if (details
                    .hasAdditionalFullRouteStops) ...[
                  const SizedBox(height: 16),
                  _buildCompleteRouteToggle(
                    totalStops:
                        details.stops.length,
                  ),

                  AnimatedCrossFade(
                    duration: const Duration(
                      milliseconds: 240,
                    ),
                    crossFadeState: showCompleteRoute
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild:
                        const SizedBox.shrink(),
                    secondChild: Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 18,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Bus Route',
                            style: TextStyle(
                              color:
                                  Color(0xff553C9A),
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTimeline(
                            stops: details.stops,
                            fullRouteMode: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }


  // =============================================================
  // JOURNEY HERO
  // =============================================================
  Widget _buildJourneyHero({
    required String pickupName,
    required String dropName,
    required String pickupTime,
    required String dropTime,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildEndpoint(
              label: 'PICKUP',
              time: pickupTime,
              stopName: pickupName,
              alignRight: false,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildBusConnector(),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildEndpoint(
              label: 'DROP-OFF',
              time: dropTime,
              stopName: dropName,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }


  // =============================================================
  // ENDPOINT
  // =============================================================
  Widget _buildEndpoint({
    required String label,
    required String time,
    required String stopName,
    required bool alignRight,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignRight
              ? TextAlign.right
              : TextAlign.left,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          time.isEmpty ? '--:--' : time,
          textAlign: alignRight
              ? TextAlign.right
              : TextAlign.left,
          style: const TextStyle(
            color: Color(0xff111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stopName,
          textAlign: alignRight
              ? TextAlign.right
              : TextAlign.left,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff475569),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  // =============================================================
  // BUS CONNECTOR
  // =============================================================
  Widget _buildBusConnector() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xffC4B5FD),
              borderRadius: BorderRadius.circular(
                99,
              ),
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffF3EFFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xffDDD2FF),
            ),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 18,
            color: Color(0xff6B46C1),
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xffC4B5FD),
              borderRadius: BorderRadius.circular(
                99,
              ),
            ),
          ),
        ),
      ],
    );
  }


  // =============================================================
    // SUMMARY CARDS
    // -------------------------------------------------------------
    // Displays journey duration, stop count and bus number.
    //
    // IMPORTANT:
    // Do not use CrossAxisAlignment.stretch in a Row placed inside
    // an unbounded vertical scroll area. That causes RenderFlex
    // layout failures because Flutter cannot determine the Row height.
    // =============================================================
    Widget _buildSummaryCards({
    required String durationLabel,
    required int stopCount,
    required String busNumber,
    }) {
    return LayoutBuilder(
        builder: (context, constraints) {
        // Stack cards only on very narrow screens.
        final useSingleColumn =
            constraints.maxWidth < 350;

        final cards = <Widget>[
            _buildStatCard(
            icon: Icons.schedule_rounded,
            label: 'Journey time',
            value: durationLabel,
            ),
            _buildStatCard(
            icon: Icons.location_on_outlined,
            label: 'Journey stops',
            value: '$stopCount',
            ),
            _buildStatCard(
            icon: Icons.directions_bus_outlined,
            label: 'Bus number',
            value: busNumber,
            ),
        ];

        if (useSingleColumn) {
            return Column(
            children: [
                for (
                int index = 0;
                index < cards.length;
                index++
                ) ...[
                SizedBox(
                    width: double.infinity,
                    child: cards[index],
                ),
                if (index != cards.length - 1)
                    const SizedBox(height: 9),
                ],
            ],
            );
        }

        return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
            for (
                int index = 0;
                index < cards.length;
                index++
            ) ...[
                Expanded(
                child: cards[index],
                ),
                if (index != cards.length - 1)
                const SizedBox(width: 9),
            ],
            ],
        );
        },
    );
    }


  // =============================================================
  // STAT CARD
  // =============================================================
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(
        borderRadius: 13,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xff6B46C1),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }


  // =============================================================
  // JOURNEY WARNING
  // =============================================================
  Widget _buildJourneyWarning(
    String warning,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffFFF8E8),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(0xffF4D48B),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xff8A5A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Showing the complete route',
                  style: TextStyle(
                    color: Color(0xff8A5A00),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  warning.trim().isNotEmpty
                      ? warning
                      : 'The selected journey could not be matched exactly.',
                  style: const TextStyle(
                    color: Color(0xff6D5200),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // =============================================================
  // TIMELINE HEADING
  // =============================================================
  Widget _buildTimelineHeading({
    required bool journeyMatched,
    required int stopCount,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                journeyMatched
                    ? 'YOUR JOURNEY'
                    : 'COMPLETE ROUTE',
                style: const TextStyle(
                  color: Color(0xff6B46C1),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$stopCount scheduled '
                '${stopCount == 1 ? 'stop' : 'stops'}',
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffEDE9FE),
            borderRadius: BorderRadius.circular(
              99,
            ),
          ),
          child: const Text(
            'Scheduled times',
            style: TextStyle(
              color: Color(0xff5B21B6),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }


  // =============================================================
  // TIMELINE
  // =============================================================
  Widget _buildTimeline({
    required List<RouteDetailsStop> stops,
    required bool fullRouteMode,
  }) {
    return Column(
      children: List.generate(
        stops.length,
        (index) {
          return _buildStopTimelineItem(
            stop: stops[index],
            index: index,
            totalStops: stops.length,
            fullRouteMode: fullRouteMode,
          );
        },
      ),
    );
  }


  // =============================================================
  // ONE TIMELINE STOP
  // =============================================================
  Widget _buildStopTimelineItem({
    required RouteDetailsStop stop,
    required int index,
    required int totalStops,
    required bool fullRouteMode,
  }) {
    final isFirst = index == 0;
    final isLast = index == totalStops - 1;

    final isPickup =
        stop.isPickup ||
        (!fullRouteMode && isFirst);

    final isDrop =
        stop.isDrop ||
        (!fullRouteMode && isLast);

    final isJourneyStop =
        fullRouteMode &&
        stop.isJourneyStop &&
        !isPickup &&
        !isDrop;

    final markerColor = isPickup
        ? const Color(0xff6B46C1)
        : isDrop
            ? const Color(0xff16A34A)
            : isJourneyStop
                ? const Color(0xff8B5CF6)
                : const Color(0xffF1F5F9);

    final markerBorderColor = isPickup
        ? const Color(0xff6B46C1)
        : isDrop
            ? const Color(0xff16A34A)
            : isJourneyStop
                ? const Color(0xff8B5CF6)
                : const Color(0xffE2E8F0);

    final markerTextColor =
        isPickup || isDrop
            ? Colors.white
            : isJourneyStop
                ? const Color(0xff6B46C1)
                : const Color(0xff64748B);

    final cardColor = isPickup
        ? const Color(0xffFAF8FF)
        : isDrop
            ? const Color(0xffF0FDF4)
            : Colors.white;

    final cardBorderColor = isPickup
        ? const Color(0xffC4B5FD)
        : isDrop
            ? const Color(0xffBBF7D0)
            : const Color(0xffE5E7EB);

    final badgeColor = isPickup
        ? const Color(0xffEDE9FE)
        : isDrop
            ? const Color(0xffDCFCE7)
            : isJourneyStop
                ? const Color(0xffEDE9FE)
                : const Color(0xffF1F5F9);

    final badgeTextColor = isPickup
        ? const Color(0xff5B21B6)
        : isDrop
            ? const Color(0xff166534)
            : isJourneyStop
                ? const Color(0xff5B21B6)
                : const Color(0xff475569);

    final badgeText = isPickup
        ? 'Pickup'
        : isDrop
            ? 'Drop-off'
            : isJourneyStop
                ? 'Your journey'
                : 'Scheduled';

    final markerChild = isPickup
        ? const Icon(
            Icons.circle,
            size: 9,
            color: Colors.white,
          )
        : isDrop
            ? const Icon(
                Icons.diamond_rounded,
                size: 13,
                color: Colors.white,
              )
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: markerTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerBorderColor,
                      width: 2,
                    ),
                  ),
                  child: markerChild,
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin:
                          const EdgeInsets.symmetric(
                        vertical: 3,
                      ),
                      color:
                          const Color(0xffE2E8F0),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : 12,
              ),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(13),
                border: Border.all(
                  color: cardBorderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.stopName,
                              style: const TextStyle(
                                color:
                                    Color(0xff111827),
                                fontSize: 14,
                                height: 1.35,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            if (stop.city
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .location_city_outlined,
                                    size: 13,
                                    color:
                                        Color(0xff64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      stop.city,
                                      style:
                                          const TextStyle(
                                        color: Color(
                                          0xff64748B,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        _formatTime(
                          stop.arrivalTime,
                        ),
                        style: const TextStyle(
                          color: Color(0xff553C9A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    crossAxisAlignment:
                        WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Stop ${stop.stopOrder}',
                        style: const TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius:
                              BorderRadius.circular(
                            99,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =============================================================
  // COMPLETE ROUTE TOGGLE
  // =============================================================
  Widget _buildCompleteRouteToggle({
    required int totalStops,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          showCompleteRoute =
              !showCompleteRoute;
        });
      },
      borderRadius: BorderRadius.circular(13),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffF5F0FF),
          borderRadius: BorderRadius.circular(
            13,
          ),
          border: Border.all(
            color: const Color(0xffDDD2FF),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.alt_route_rounded,
              color: Color(0xff6B46C1),
              size: 21,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    showCompleteRoute
                        ? 'Hide complete bus route'
                        : 'View complete bus route',
                    style: const TextStyle(
                      color: Color(0xff553C9A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$totalStops scheduled stops',
                    style: const TextStyle(
                      color: Color(0xff777777),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns:
                  showCompleteRoute ? 0.5 : 0,
              duration: const Duration(
                milliseconds: 220,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xff553C9A),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // FOOTER
  // =============================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        11,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xffE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Times may vary due to traffic or operating conditions.',
                style: TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 120,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff6B46C1),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor:
                      const Color(0xff6B46C1)
                          .withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // LOADING STATE
  // =============================================================
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xff6B46C1),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading route and stops',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff111827),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.route.routeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // ERROR STATE
  // =============================================================
  Widget _buildErrorState({
    String? customMessage,
  }) {
    final message =
        customMessage ?? errorMessage;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xffFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xffB91C1C),
                size: 31,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load route',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message.isEmpty
                  ? 'Please try again.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xff475569),
                    side: const BorderSide(
                      color: Color(0xffCBD5E1),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                  ),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: loadRouteDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff6B46C1),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // =============================================================
  // CARD DECORATION
  // =============================================================
  BoxDecoration _cardDecoration({
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
      border: Border.all(
        color: const Color(0xffE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.035,
          ),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }


  // =============================================================
  // FORMAT DURATION
  // =============================================================
  String _formatDuration(
    int? minutes,
  ) {
    if (minutes == null || minutes < 0) {
      return 'Scheduled';
    }

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $remainingMinutes min';
  }


  // =============================================================
  // FORMAT TIME
  // ---------------------------------------------------------------
  // Supports:
  // - 07:20
  // - 07:20:00
  // - ISO date strings
  // =============================================================
  String _formatTime(String value) {
    final text = value.trim();

    if (text.isEmpty || text == '-') {
      return '--:--';
    }

    final timeMatch = RegExp(
      r'(\d{1,2}):(\d{2})',
    ).firstMatch(text);

    if (timeMatch != null) {
      final hour = timeMatch
          .group(1)!
          .padLeft(2, '0');

      final minute =
          timeMatch.group(2)!;

      return '$hour:$minute';
    }

    return text;
  }


  // =============================================================
  // FIRST NON-EMPTY VALUE
  // =============================================================
  String _firstNonEmpty(
    List<String> values,
  ) {
    for (final value in values) {
      final cleanValue = value.trim();

      if (
          cleanValue.isNotEmpty &&
          cleanValue != '-') {
        return cleanValue;
      }
    }

    return '-';
  }
}