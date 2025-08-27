import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

import '../../../shared/theme/app_theme.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const _iconList = [
    UniconsLine.home,
    UniconsLine.receipt_alt,
    UniconsLine.plus,
    UniconsLine.shopping_basket,
    UniconsLine.setting,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bottomBarBgColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final itemCount = _iconList.length;
          final itemWidth = barWidth / itemCount;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Cerchio verde animato sotto l'icona selezionata
              AnimatedPositioned(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: selectedIndex * itemWidth + itemWidth / 2 - 24,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.selectedBg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Row delle icone sopra il cerchio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(itemCount, (index) {
                  final icon = _iconList[index];
                  final selected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => onItemTapped(index),
                    behavior: HitTestBehavior.translucent,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Icon(
                          icon,
                          color: selected ? AppTheme.grey : AppTheme.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
