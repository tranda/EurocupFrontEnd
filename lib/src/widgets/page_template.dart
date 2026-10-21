import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';

/// Reusable page template widget that provides consistent styling
/// based on the race results views pattern
class PageTemplate extends StatelessWidget {
  const PageTemplate({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.headerWidget,
    this.onRefresh,
    this.isRefreshing = false,
    this.emptyMessage = 'No items available',
    this.eventId,
    this.showRefreshButton = true,
  });

  /// Page title for the app bar
  final String title;

  /// List of items to display
  final List<dynamic> items;

  /// Builder function for individual items
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;

  /// Optional custom header widget to show at the top
  final Widget? headerWidget;

  /// Refresh function
  final Future<void> Function()? onRefresh;

  /// Whether currently refreshing
  final bool isRefreshing;

  /// Message to show when items list is empty
  final String emptyMessage;

  /// Event ID for color theming
  final int? eventId;

  /// Whether to show refresh button in app bar
  final bool showRefreshButton;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? 1;
    final colorIndex = (effectiveEventId - 1).clamp(0, competitionColor.length - 1);

    return Scaffold(
      appBar: showRefreshButton
          ? appBarWithAction(
              isRefreshing ? null : onRefresh,
              title: title,
              icon: isRefreshing ? Icons.hourglass_empty : Icons.refresh,
            )
          : appBar(title: title),
      body: Container(
        decoration: bckDecoration(),
        child: _buildBody(context, colorIndex),
      ),
    );
  }

  Widget _buildBody(BuildContext context, int colorIndex) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          children: [
            if (headerWidget != null) headerWidget!,
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final totalItems = (headerWidget != null ? 1 : 0) + items.length;

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // Show header widget if provided and this is the first item
          if (headerWidget != null && index == 0) {
            return headerWidget!;
          }

          // Adjust index for items (subtract 1 if header is present)
          final itemIndex = headerWidget != null ? index - 1 : index;
          final item = items[itemIndex];

          return itemBuilder(context, item, itemIndex);
        },
      ),
    );
  }
}

/// Header widget that follows the race results styling pattern
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eventId,
    this.actions,
  });

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Event ID for color theming
  final int? eventId;

  /// Optional action widgets (like buttons)
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? 1;
    final colorIndex = (effectiveEventId - 1).clamp(0, competitionColor.length - 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Colored header widget that follows the race results list pattern
class ColoredPageHeader extends StatelessWidget {
  const ColoredPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eventId,
    this.leading,
    this.trailing,
    this.titleBadge,
    this.onTap,
  });

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Event ID for color theming
  final int? eventId;

  /// Optional leading widget
  final Widget? leading;

  /// Optional trailing widget
  final Widget? trailing;

  /// Optional widget shown right after the title (e.g. a competition badge)
  final Widget? titleBadge;

  /// Optional tap handler
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? 1;
    final colorIndex = (effectiveEventId - 1).clamp(0, competitionColor.length - 1);

    return Container(
      color: competitionColor[colorIndex],
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              if (titleBadge != null) ...[
                const SizedBox(width: 10),
                titleBadge!,
              ],
            ],
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}

/// List item widget with consistent styling
class PageListItem extends StatelessWidget {
  const PageListItem({
    super.key,
    required this.child,
    this.showBorder = true,
    this.onTap,
  });

  /// The child widget to display
  final Widget child;

  /// Whether to show bottom border
  final bool showBorder;

  /// Optional tap handler
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: child,
            )
          : child,
    );
  }
}
// ---------------------------------------------------------------------------
// Style C building blocks (the Current Entries look), shared by list pages:
//   PageTitleBlock  → white block with big title + filters (dropdown, chips)
//   ColoredPageHeader → event-coloured section bar grouping the rows
//   PageListItem + ListTile(title: displaySmall) → the rows
//   CountryBadge    → "🇷🇸 SRB" chip in front of club/team names
// ---------------------------------------------------------------------------

const Color pageBlue = Color.fromARGB(255, 0, 80, 150);

/// White block at the top of a list page: big bold title, then any filters.
class PageTitleBlock extends StatelessWidget {
  const PageTitleBlock({super.key, required this.title, this.children = const []});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          for (final child in children) ...[const SizedBox(height: 12), child],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Outlined field look used by the "Select Event" dropdown.
InputDecoration pageFieldDecoration(String label) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: pageBlue, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
    fillColor: Colors.white,
    filled: true,
    border: border(Colors.grey, 1.0),
    enabledBorder: border(Colors.grey, 1.0),
    focusedBorder: border(pageBlue, 2.0),
  );
}

/// Flag + 3-letter country code chip, as on Current Entries.
class CountryBadge extends StatelessWidget {
  const CountryBadge({super.key, required this.country});

  final String? country;

  @override
  Widget build(BuildContext context) {
    if (country == null || country!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '${getCountryFlag(country)} ${getCountryCode(country)}',
        style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Small rounded chip for statuses ("active", "expired", "2 MB").
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color = Colors.blue});

  final String label;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.shade800)),
    );
  }
}

/// Spacer between sections, as Current Entries uses.
const Widget pageSectionGap = Divider(height: smallSpace);
