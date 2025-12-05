import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

DateTime kFirstDay = DateTime(1970, 1, 1);
DateTime kLastDay = DateTime(2100, 1, 1);

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59);
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameMonth(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month;
}

class FlutterFlowCalendar extends StatefulWidget {
  const FlutterFlowCalendar({
    super.key,
    required this.color,
    this.events,
    this.onChange,
    this.initialDate,
    this.weekFormat = false,
    this.weekStartsMonday = false,
    this.iconColor,
    this.dateStyle,
    this.dayOfWeekStyle,
    this.inactiveDateStyle,
    this.selectedDateStyle,
    this.titleStyle,
    this.rowHeight,
    this.locale,
  });

  final bool weekFormat;
  final bool weekStartsMonday;
  final Color color;
  final void Function(DateTimeRange?)? onChange;
  final DateTime? initialDate;
  final Color? iconColor;
  final TextStyle? dateStyle;
  final TextStyle? dayOfWeekStyle;
  final TextStyle? inactiveDateStyle;
  final TextStyle? selectedDateStyle;
  final TextStyle? titleStyle;
  final double? rowHeight;
  final String? locale;
  final Map<DateTime, List<dynamic>>? events;

  @override
  State<StatefulWidget> createState() => _FlutterFlowCalendarState();
}

class _FlutterFlowCalendarState extends State<FlutterFlowCalendar> {
  late DateTime focusedDay;
  late DateTime selectedDay;
  late DateTimeRange selectedRange;
  // Cached events keyed by YYYYMMDD -> list, to avoid allocating DateTime keys
  late Map<int, List<dynamic>> _eventsCache;

  @override
  void initState() {
    super.initState();
    focusedDay = widget.initialDate ?? DateTime.now();
    selectedDay = widget.initialDate ?? DateTime.now();
    selectedRange = DateTimeRange(
      start: selectedDay.startOfDay,
      end: selectedDay.endOfDay,
    );
    _buildEventsCache();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => setSelectedDay(selectedRange.start));
  }

  @override
  void didUpdateWidget(covariant FlutterFlowCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _buildEventsCache();
    }
  }

  void _buildEventsCache() {
    final Map<int, List<dynamic>> map = {};
    if (widget.events != null) {
      widget.events!.forEach((key, value) {
        // normalize key to YYYYMMDD integer to avoid DateTime allocations
        final int k = key.year * 10000 + key.month * 100 + key.day;
        map[k] = value;
      });
    }
    _eventsCache = map;
  }

  CalendarFormat get calendarFormat =>
      widget.weekFormat ? CalendarFormat.week : CalendarFormat.month;

  StartingDayOfWeek get startingDayOfWeek => widget.weekStartsMonday
      ? StartingDayOfWeek.monday
      : StartingDayOfWeek.sunday;

  Color get color => widget.color;

  // TODO: migrate to `withValues()` once Flutter SDK and design tokens are aligned
  // ignore: deprecated_member_use
  Color get lightColor => widget.color.withOpacity(0.85);

  // ignore: deprecated_member_use
  Color get lighterColor => widget.color.withOpacity(0.60);

  void setSelectedDay(
    DateTime? newSelectedDay, [
    DateTime? newSelectedEnd,
  ]) {
    final newRange = newSelectedDay == null
        ? null
        : DateTimeRange(
            start: newSelectedDay.startOfDay,
            end: newSelectedEnd ?? newSelectedDay.endOfDay,
          );
    setState(() {
      selectedDay = newSelectedDay ?? selectedDay;
      selectedRange = newRange ?? selectedRange;
      if (widget.onChange != null) {
        widget.onChange!(newRange);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CalendarHeader(
            focusedDay: focusedDay,
            onLeftChevronTap: () => setState(
              () => focusedDay = widget.weekFormat
                  ? _previousWeek(focusedDay)
                  : _previousMonth(focusedDay),
            ),
            onRightChevronTap: () => setState(
              () => focusedDay = widget.weekFormat
                  ? _nextWeek(focusedDay)
                  : _nextMonth(focusedDay),
            ),
            onTodayButtonTap: () => setState(() => focusedDay = DateTime.now()),
            titleStyle: widget.titleStyle,
            iconColor: widget.iconColor,
            locale: widget.locale,
          ),
          TableCalendar(
            focusedDay: focusedDay,
            eventLoader: (date) {
              // fast lookup via integer keys
              if (_eventsCache.isEmpty) return <dynamic>[];
              final int k = date.year * 10000 + date.month * 100 + date.day;
              return _eventsCache[k] ?? <dynamic>[];
            },
            selectedDayPredicate: (date) => isSameDay(selectedDay, date),
            firstDay: kFirstDay,
            lastDay: kLastDay,
            calendarFormat: calendarFormat,
            headerVisible: false,
            locale: widget.locale,
            rowHeight:
                widget.rowHeight ?? MediaQuery.of(context).size.width / 7,
            calendarStyle: CalendarStyle(
              weekendTextStyle: widget.dateStyle ??
                  const TextStyle(color: Color(0xFF5A5A5A)),
              holidayTextStyle: widget.dateStyle ??
                  const TextStyle(color: Color(0xFF5C6BC0)),
              selectedTextStyle:
                  const TextStyle(color: Color(0xFFFAFAFA), fontSize: 16.0)
                      .merge(widget.selectedDateStyle),
              todayTextStyle:
                  const TextStyle(color: Color(0xFFFAFAFA), fontSize: 16.0)
                      .merge(widget.selectedDateStyle),
              outsideTextStyle: const TextStyle(color: Color(0xFF9E9E9E))
                  .merge(widget.inactiveDateStyle),
              selectedDecoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: lighterColor,
                shape: BoxShape.circle,
              ),
              // Disable the default small dot markers; we keep the outer outline
              // ring drawn in the custom builders for days with events.
              markerDecoration: const BoxDecoration(),
              markersMaxCount: 0,
              canMarkersOverflow: true,
            ),
            // Custom builders so we can draw a light outline around each day
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                final int k = date.year * 10000 + date.month * 100 + date.day;
                final bool hasEvents = _eventsCache[k] != null && _eventsCache[k]!.isNotEmpty;
                final Color accent = widget.color;
                // Outer ring for event days to make it clearly visible across themes
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (hasEvents)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withOpacity(0.95), width: 2.4),
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: Text(
                            '${date.day}',
                            style: widget.dateStyle ?? const TextStyle(color: Color(0xFF5A5A5A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              outsideBuilder: (context, date, _) {
                final int k = date.year * 10000 + date.month * 100 + date.day;
                final bool hasEvents = _eventsCache[k] != null && _eventsCache[k]!.isNotEmpty;
                final Color accent = widget.color;
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (hasEvents)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withOpacity(0.7), width: 2.0),
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: Text(
                            '${date.day}',
                            style: (widget.inactiveDateStyle) ?? const TextStyle(color: Color(0xFF9E9E9E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              todayBuilder: (context, date, _) => Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lighterColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: lighterColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Color(0xFFFAFAFA), fontSize: 16.0).merge(widget.selectedDateStyle),
                  ),
                ),
              ),
              selectedBuilder: (context, date, _) => Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.9)),
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Color(0xFFFAFAFA), fontSize: 16.0).merge(widget.selectedDateStyle),
                  ),
                ),
              ),
            ),
            availableGestures: AvailableGestures.horizontalSwipe,
            startingDayOfWeek: startingDayOfWeek,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(color: Color(0xFF616161))
                  .merge(widget.dayOfWeekStyle),
              weekendStyle: const TextStyle(color: Color(0xFF616161))
                  .merge(widget.dayOfWeekStyle),
            ),
            onDaySelected: (newSelectedDay, _) {
              if (!isSameDay(selectedDay, newSelectedDay)) {
                setSelectedDay(newSelectedDay);
                if (!isSameMonth(focusedDay, newSelectedDay)) {
                  setState(() => focusedDay = newSelectedDay);
                }
              }
            },
          ),
        ],
      );
}

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.focusedDay,
    required this.onLeftChevronTap,
    required this.onRightChevronTap,
    required this.onTodayButtonTap,
    this.iconColor,
    this.titleStyle,
    this.locale,
  });

  final DateTime focusedDay;
  final VoidCallback onLeftChevronTap;
  final VoidCallback onRightChevronTap;
  final VoidCallback onTodayButtonTap;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final String? locale;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(),
        margin: const EdgeInsets.all(0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const SizedBox(
              width: 20,
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(focusedDay),
                style: const TextStyle(fontSize: 17).merge(titleStyle),
              ),
            ),
            CustomIconButton(
              icon: Icon(Icons.calendar_today, color: iconColor),
              onTap: onTodayButtonTap,
            ),
            CustomIconButton(
              icon: Icon(Icons.chevron_left, color: iconColor),
              onTap: onLeftChevronTap,
            ),
            CustomIconButton(
              icon: Icon(Icons.chevron_right, color: iconColor),
              onTap: onRightChevronTap,
            ),
          ],
        ),
      );
}

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 4),
    this.padding = const EdgeInsets.all(10),
  });

  final Icon icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: padding,
            child: Icon(
              icon.icon,
              color: icon.color,
              size: icon.size,
            ),
          ),
        ),
      );
}

DateTime _previousWeek(DateTime week) {
  return week.subtract(const Duration(days: 7));
}

DateTime _nextWeek(DateTime week) {
  return week.add(const Duration(days: 7));
}

DateTime _previousMonth(DateTime month) {
  if (month.month == 1) {
    return DateTime(month.year - 1, 12);
  } else {
    return DateTime(month.year, month.month - 1);
  }
}

DateTime _nextMonth(DateTime month) {
  if (month.month == 12) {
    return DateTime(month.year + 1, 1);
  } else {
    return DateTime(month.year, month.month + 1);
  }
}
