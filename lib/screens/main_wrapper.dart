import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/theme.dart';

class MainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({super.key, required this.navigationShell});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _hideAnimController;
  late Animation<Offset> _hideAnim;

  @override
  void initState() {
    super.initState();
    _hideAnimController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 300),
    );
    _hideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.5)).animate(
      CurvedAnimation(parent: _hideAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hideAnimController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
             if (_hideAnimController.isCompleted) _hideAnimController.reverse();
          } else if (notification.direction == ScrollDirection.reverse) {
             if (_hideAnimController.isDismissed) _hideAnimController.forward();
          }
          return true;
        },
        child: widget.navigationShell,
      ),
      bottomNavigationBar: SlideTransition(
        position: _hideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                     ? AppTheme.surface.withValues(alpha: 0.6)
                     : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                     color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Theme(
                  data: ThemeData(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: widget.navigationShell.currentIndex,
                    onTap: (index) => _onTap(context, index),
                    backgroundColor: Colors.transparent,
                    selectedItemColor: AppTheme.primary,
                    unselectedItemColor: isDark 
                       ? AppTheme.textMuted.withValues(alpha: 0.6)
                       : Colors.black45,
                    showSelectedLabels: true,
                    showUnselectedLabels: false,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    iconSize: 24,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.home)),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.map)),
                        label: 'Map',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.users)),
                        label: 'Community',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.zap)),
                        label: 'Tools',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.settings)),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
