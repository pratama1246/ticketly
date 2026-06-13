import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<EventModel> events;

  const EventListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount = 2;
    double childAspectRatio = 0.66;

    if (screenWidth > 1024) {
      crossAxisCount = 5;
      childAspectRatio = 0.78;
    } else if (screenWidth > 768) {
      crossAxisCount = 4;
      childAspectRatio = 0.74;
    } else if (screenWidth > 480) {
      crossAxisCount = 3;
      childAspectRatio = 0.70;
    } else if (screenWidth < 360) {
      crossAxisCount = 2;
      childAspectRatio = 0.62;
    }

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title.split(' ').first), // e.g. "Konser", "Festival"
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.sectionHeadingStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyStyle,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: 8.0,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(slug: event.slug),
                        ),
                      );
                    },
                  );
                },
                childCount: events.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}
