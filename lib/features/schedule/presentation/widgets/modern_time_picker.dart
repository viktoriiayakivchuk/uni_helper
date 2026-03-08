import 'package:flutter/material.dart';

class ModernTimePickerWidget extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const ModernTimePickerWidget({
    super.key,
    required this.title,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<ModernTimePickerWidget> createState() => _ModernTimePickerWidgetState();
}

class _ModernTimePickerWidgetState extends State<ModernTimePickerWidget> {
  late int selectedHour;
  late int selectedMinute;
  late PageController _hourController;
  late PageController _minuteController;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
    _hourController = PageController(initialPage: selectedHour);
    _minuteController = PageController(initialPage: selectedMinute ~/ 5);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Перетягування індикатор
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Заголовок
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5A40),
            ),
          ),
          const SizedBox(height: 32),

          // Вибирач часу і хвилин
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5A40).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2D5A40).withOpacity(0.15),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Години
                SizedBox(
                  width: 80,
                  height: 200,
                  child: PageView.builder(
                    controller: _hourController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() {
                        selectedHour = index.clamp(0, 23);
                      });
                    },
                    itemCount: 24,
                    itemBuilder: (context, index) {
                      final isSelected = selectedHour == index;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 56 : 28,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w300,
                            color: isSelected
                                ? const Color(0xFF2D5A40)
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Роздільник
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2D5A40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2D5A40),
                        ),
                      ),
                    ],
                  ),
                ),

                // Хвилини
                SizedBox(
                  width: 70,
                  height: 180,
                  child: PageView.builder(
                    controller: _minuteController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() => selectedMinute = (index * 5) % 60);
                    },
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final minute = (index * 5) % 60;
                      return Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: selectedMinute == minute ? 48 : 32,
                            fontWeight: selectedMinute == minute
                                ? FontWeight.w900
                                : FontWeight.w400,
                            color: selectedMinute == minute
                                ? const Color(0xFF2D5A40)
                                : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Поточний час передпросмотр
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5A40).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5A40),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки дій
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Скасувати',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onTimeSelected(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A40),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Обрати',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
