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

  /// Event ID for color theming (defaults to EVENTID)
  final int? eventId;

  /// Whether to show refresh button in app bar
  final bool showRefreshButton;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? EVENTID;
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

  /// Event ID for color theming (defaults to EVENTID)
  final int? eventId;

  /// Optional action widgets (like buttons)
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? EVENTID;
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
    this.onTap,
  });

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Event ID for color theming (defaults to EVENTID)
  final int? eventId;

  /// Optional leading widget
  final Widget? leading;

  /// Optional trailing widget
  final Widget? trailing;

  /// Optional tap handler
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveEventId = eventId ?? EVENTID;
    final colorIndex = (effectiveEventId - 1).clamp(0, competitionColor.length - 1);

    return Container(
      color: competitionColor[colorIndex],
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
            ),
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