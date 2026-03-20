import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LatestNewsScreen extends StatelessWidget {
  const LatestNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Stack(
        children: [
          // G.O.A.T Background Watermark (Messi)
          Positioned(
            right: isTablet ? 0 : -100,
            bottom: 0,
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://cdn.prod.website-files.com/6267f33d7b3e4040f7d4d4-messi-efootball.png',
                height: isTablet ? 800 : 600,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          
          // Rainbow Glow Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withOpacity(0.015),
                      Colors.blue.withOpacity(0.015),
                      Colors.green.withOpacity(0.015),
                      Colors.yellow.withOpacity(0.015),
                      Colors.orange.withOpacity(0.015),
                      Colors.red.withOpacity(0.015),
                    ],
                  ),
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isTablet ? 240.0 : 180.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryPurple,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "EFOOTBALL™ 2025/26",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      color: Colors.white, 
                      letterSpacing: 2,
                      fontSize: isTablet ? 24 : 18,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.headerGradient,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroNewsCard(isTablet),
                        const SizedBox(height: 48),
                        Text(
                          "WORLD NEWS",
                          style: GoogleFonts.outfit(
                            fontSize: 20, 
                            fontWeight: FontWeight.w900, 
                            color: AppTheme.primaryPurple,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? (size.width - 1160) / 2 : 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildNewsItem(index, isTablet),
                    childCount: 6,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroNewsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isTablet 
        ? Row(
            children: [
              Expanded(
                flex: 6,
                child: _buildHeroImage(),
              ),
              Expanded(
                flex: 7,
                child: _buildHeroContent(isTablet),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(),
              _buildHeroContent(isTablet),
            ],
          ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.hub, size: 240, color: Colors.white.withOpacity(0.2)),
            ),
          ),
          const Center(
            child: Icon(Icons.auto_awesome, size: 140, color: AppTheme.accentGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 40.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "TODAY: MARCH 20, 2026",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "eFootball™ v5.3.0 Live: The Spring Resurrection Patch",
            style: GoogleFonts.outfit(
              fontSize: isTablet ? 32 : 26, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.primaryPurple, 
              height: 1.1
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Today's major update introduces the new 'Strategic Counter' playstyle and recalibrates the Physical Contact stats for all defenders. Experience the next era of football control on 3/20/2026.",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
            maxLines: isTablet ? 4 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(int index, bool isTablet) {
    final news = [
      {
        "title": "v5.3.0 Patch Notes: Physical Contact Recalibration & New Epic Draws",
        "tag": "TODAY'S UPDATE",
        "time": "MAR 20, 2026",
        "icon": Icons.auto_awesome
      },
      {
        "title": "Konami Announces 'Leo Messi: The 8th Wonder' Limited Edition Card",
        "tag": "EXCLUSIVE",
        "time": "MAR 19, 2026",
        "icon": Icons.star_purple500
      },
      {
        "title": "Tour Rally & Squad Challenge: Win Guaranteed Headliners",
        "tag": "LIVE EVENT",
        "time": "ONGOING",
        "icon": Icons.military_tech
      },
      {
        "title": "Campaign Hub Shop: New Exchange System for Epic Player Packs",
        "tag": "FEATURE",
        "time": "NEW",
        "icon": Icons.shopping_basket
      },
      {
        "title": "Konami Reveals v6.0.0 Roadmap: Master League Integration",
        "tag": "ROADMAP",
        "time": "FUTURE",
        "icon": Icons.map
      },
      {
        "title": "Show Time: Daily Free Draw Event Now Active for All Users",
        "tag": "REWARDS",
        "time": "LIMITED",
        "icon": Icons.card_giftcard
      }
    ];

    final item = news[index % news.length];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1160),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: EdgeInsets.all(isTablet ? 24 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 120 : 80,
              height: isTablet ? 120 : 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(item["icon"] as IconData, color: AppTheme.primaryPurple, size: isTablet ? 48 : 36),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["tag"] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 11, 
                      fontWeight: FontWeight.w900, 
                      color: AppTheme.accentGreen, 
                      letterSpacing: 2
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["title"] as String,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      fontSize: isTablet ? 20 : 16, 
                      color: AppTheme.primaryPurple, 
                      height: 1.2
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${item["time"]} • Official eFootball™ 2025/26 Update",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
