import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

// ─── Table Status Enum ───────────────────────────────────────────────────────

enum TableStatus { available, occupied, reserved, cleaning }

// ─── Table Model ─────────────────────────────────────────────────────────────

class CafeTable {
  final int number;
  final int capacity;
  TableStatus status;
  String? occupiedBy;
  DateTime? occupiedAt;
  double? billAmount;

  CafeTable({
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
    this.occupiedBy,
    this.occupiedAt,
    this.billAmount,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final tablesProvider = StateNotifierProvider<TablesNotifier, List<CafeTable>>((ref) {
  return TablesNotifier();
});

class TablesNotifier extends StateNotifier<List<CafeTable>> {
  TablesNotifier()
      : super([
          CafeTable(number: 1, capacity: 2),
          CafeTable(number: 2, capacity: 2, status: TableStatus.occupied, occupiedBy: 'Walk-in', occupiedAt: DateTime.now().subtract(const Duration(minutes: 25)), billAmount: 1450),
          CafeTable(number: 3, capacity: 4, status: TableStatus.reserved, occupiedBy: 'Ali Hassan'),
          CafeTable(number: 4, capacity: 4),
          CafeTable(number: 5, capacity: 6, status: TableStatus.occupied, occupiedBy: 'Walk-in', occupiedAt: DateTime.now().subtract(const Duration(minutes: 8)), billAmount: 2800),
          CafeTable(number: 6, capacity: 6),
          CafeTable(number: 7, capacity: 2),
          CafeTable(number: 8, capacity: 4),
          CafeTable(number: 9, capacity: 2, status: TableStatus.occupied, occupiedBy: 'Sara Ahmed', occupiedAt: DateTime.now().subtract(const Duration(minutes: 42)), billAmount: 950),
          CafeTable(number: 10, capacity: 8),
          CafeTable(number: 11, capacity: 4, status: TableStatus.reserved, occupiedBy: 'Usman Malik'),
          CafeTable(number: 12, capacity: 2),
        ]);

  void updateStatus(int tableNumber, TableStatus newStatus, {String? occupiedBy}) {
    state = state.map((t) {
      if (t.number == tableNumber) {
        return CafeTable(
          number: t.number,
          capacity: t.capacity,
          status: newStatus,
          occupiedBy: (newStatus == TableStatus.occupied || newStatus == TableStatus.reserved)
              ? (occupiedBy != null && occupiedBy.trim().isNotEmpty ? occupiedBy : (newStatus == TableStatus.occupied ? 'Walk-in' : 'Reserved Guest'))
              : null,
          occupiedAt: newStatus == TableStatus.occupied ? DateTime.now() : null,
          billAmount: newStatus == TableStatus.available ? null : t.billAmount,
        );
      }
      return t;
    }).toList();
  }

  void clearTable(int tableNumber) {
    updateStatus(tableNumber, TableStatus.cleaning);
    // Auto-transition to available after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (state.any((t) => t.number == tableNumber && t.status == TableStatus.cleaning)) {
        updateStatus(tableNumber, TableStatus.available);
      }
    });
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _cleaningRotateController;
  late AnimationController _shimmerController;
  // Track cleaning start times for countdown
  final Map<int, DateTime> _cleaningStartTimes = {};
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cleaningRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Refresh countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cleaningRotateController.dispose();
    _shimmerController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return const Color(0xFF27AE60);
      case TableStatus.occupied:
        return const Color(0xFFE74C3C);
      case TableStatus.reserved:
        return const Color(0xFFF39C12);
      case TableStatus.cleaning:
        return const Color(0xFF3498DB);
    }
  }

  IconData _statusIcon(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return Icons.check_circle_rounded;
      case TableStatus.occupied:
        return Icons.people_rounded;
      case TableStatus.reserved:
        return Icons.bookmark_rounded;
      case TableStatus.cleaning:
        return Icons.cleaning_services_rounded;
    }
  }

  String _statusLabel(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }

  String _timeElapsed(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  void _showTableDialog(BuildContext context, CafeTable table) {
    final notifier = ref.read(tablesProvider.notifier);
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor(table.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_statusIcon(table.status), color: _statusColor(table.status), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table ${table.number}',
                          style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('${table.capacity} seats • ${_statusLabel(table.status)}',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (table.status == TableStatus.available) ...[
                Text('ACTIONS', style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Customer name (optional)',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn('Seat Customer', Icons.people_rounded, const Color(0xFFE74C3C), () {
                        notifier.updateStatus(table.number, TableStatus.occupied, occupiedBy: nameController.text.isEmpty ? 'Walk-in' : nameController.text);
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn('Reserve', Icons.bookmark_rounded, const Color(0xFFF39C12), () {
                        notifier.updateStatus(table.number, TableStatus.reserved, occupiedBy: nameController.text.isEmpty ? 'Reserved' : nameController.text);
                        Navigator.pop(ctx);
                      }),
                    ),
                  ],
                ),
              ] else if (table.status == TableStatus.occupied) ...[
                if (table.occupiedBy != null)
                  _infoRow(Icons.person_rounded, 'Guest', table.occupiedBy!),
                if (table.occupiedAt != null)
                  _infoRow(Icons.timer_rounded, 'Duration', _timeElapsed(table.occupiedAt)),
                if (table.billAmount != null)
                  _infoRow(Icons.payments_rounded, 'Current Bill', 'PKR ${table.billAmount!.toStringAsFixed(0)}'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn('New Order', Icons.add_rounded, AppTheme.primaryColor, () {
                        Navigator.pop(ctx);
                        final nameParam = table.occupiedBy != null ? '?customerName=${Uri.encodeComponent(table.occupiedBy!)}' : '';
                        context.push('/new-order$nameParam');
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn('Clear Table', Icons.cleaning_services_rounded, const Color(0xFF3498DB), () {
                        notifier.clearTable(table.number);
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                      }),
                    ),
                  ],
                ),
              ] else if (table.status == TableStatus.reserved) ...[
                if (table.occupiedBy != null)
                  _infoRow(Icons.person_rounded, 'Reserved For', table.occupiedBy!),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn('Seat Now', Icons.people_rounded, const Color(0xFFE74C3C), () {
                        notifier.updateStatus(table.number, TableStatus.occupied, occupiedBy: table.occupiedBy);
                        Navigator.pop(ctx);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn('Cancel', Icons.cancel_rounded, Colors.grey, () {
                        notifier.updateStatus(table.number, TableStatus.available);
                        Navigator.pop(ctx);
                      }),
                    ),
                  ],
                ),
              ] else ...[
                // Cleaning state dialog content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF3498DB).withOpacity(0.08), const Color(0xFF2980B9).withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      RotationTransition(
                        turns: _cleaningRotateController,
                        child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF3498DB), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cleaning In Progress',
                                style: GoogleFonts.hankenGrotesk(
                                    color: const Color(0xFF3498DB),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Table will be ready shortly',
                                style: GoogleFonts.hankenGrotesk(
                                    color: const Color(0xFF3498DB).withOpacity(0.7),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _actionBtn('Mark as Available', Icons.check_circle_rounded, const Color(0xFF27AE60), () {
                  ref.read(tablesProvider.notifier).updateStatus(table.number, TableStatus.available);
                  Navigator.pop(ctx);
                  HapticFeedback.mediumImpact();
                }),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('$label:', style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.hankenGrotesk(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tablesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final available = tables.where((t) => t.status == TableStatus.available).length;
    final occupied = tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved = tables.where((t) => t.status == TableStatus.reserved).length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgColor : const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Floor Plan', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => context.push('/new-order'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Order'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Legend / Summary Bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _legendChip(Icons.check_circle_rounded, '$available Available', const Color(0xFF27AE60)),
                const SizedBox(width: 8),
                _legendChip(Icons.people_rounded, '$occupied Occupied', const Color(0xFFE74C3C)),
                const SizedBox(width: 8),
                _legendChip(Icons.bookmark_rounded, '$reserved Reserved', const Color(0xFFF39C12)),
              ],
            ),
          ),

          // ── Table Grid ─────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.73,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return _buildTableCard(table, theme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(CafeTable table, ThemeData theme, bool isDark) {
    final color = _statusColor(table.status);
    final isOccupied = table.status == TableStatus.occupied;
    final isCleaning = table.status == TableStatus.cleaning;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showTableDialog(context, table);
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = isOccupied ? (1.0 + _pulseController.value * 0.04) : 1.0;
          return Transform.scale(
            scale: pulse,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status color accent top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
              ),

              // Cleaning animated overlay
              if (isCleaning)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.5 + _shimmerController.value * 3, -0.3),
                              end: Alignment(-0.5 + _shimmerController.value * 3, 0.3),
                              colors: [
                                const Color(0xFF3498DB).withOpacity(0.04),
                                const Color(0xFF3498DB).withOpacity(0.14),
                                const Color(0xFF3498DB).withOpacity(0.04),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RotationTransition(
                                  turns: _cleaningRotateController,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3498DB).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cleaning_services_rounded,
                                      color: Color(0xFF3498DB),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'CLEANING',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF3498DB),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'T${table.number}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                        Icon(_statusIcon(table.status), color: color, size: 18),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              '${table.capacity} seats',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(table.status).toUpperCase(),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (table.occupiedBy != null && table.occupiedBy!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 10, color: color),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  table.occupiedBy!,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : AppTheme.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isOccupied && table.occupiedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _timeElapsed(table.occupiedAt),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: const Color(0xFFE74C3C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
