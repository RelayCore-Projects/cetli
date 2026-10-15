String _two(int n) => n.toString().padLeft(2, '0');

/// en_GB date: 16/10/2026
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
