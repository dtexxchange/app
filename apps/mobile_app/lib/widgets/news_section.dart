import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsSection extends StatefulWidget {
  final List<dynamic> newsList;

  const NewsSection({super.key, required this.newsList});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _setupAutoScroll();
  }

  @override
  void didUpdateWidget(NewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newsList.length != oldWidget.newsList.length) {
      _setupAutoScroll();
    }
  }

  void _setupAutoScroll() {
    _timer?.cancel();
    if (widget.newsList.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.newsList.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _showNewsDetail(BuildContext context, Map<String, dynamic> news) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final onSurface = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final textDim = theme.colorScheme.onSurfaceVariant;
    final hasLink = news['link'] != null && (news['link'] as String).isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.campaign, color: primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    news['title'] ?? 'Notice',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              news['description'] ?? '',
              style: GoogleFonts.inter(
                color: textDim,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            if (hasLink)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(news['link']);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Visit Website',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_new, size: 18),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newsList.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final bgCard = theme.cardColor;
    final onSurface = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final textDim = theme.colorScheme.onSurfaceVariant;

    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);

    return Container(
      height: 95 * widthScale,
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.newsList.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final news = widget.newsList[index];
              final hasLink =
                  news['link'] != null && (news['link'] as String).isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bgCard, bgCard.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: primary.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: () => _showNewsDetail(context, news),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary,
                                        primary.withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              news['title'] ?? 'Notice',
                                              style: GoogleFonts.outfit(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (hasLink) ...[
                                                  Icon(
                                                    Icons.open_in_new,
                                                    color: primary,
                                                    size: 10,
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  'NEWS',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: primary,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        news['description'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: textDim,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
