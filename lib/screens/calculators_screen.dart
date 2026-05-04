import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_toolspro/widgets/global_banner_ad.dart';

enum _CalcTab { gst, sip, emi, simple }
enum _GstMode { exclusive, inclusive }
enum _SipMode { sip, lumpsum }

class _SipYearPoint {
  final int year;
  final double invested;
  final double value;

  const _SipYearPoint({
    required this.year,
    required this.invested,
    required this.value,
  });
}

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  _CalcTab _tab = _CalcTab.gst;
  _GstMode _gstMode = _GstMode.exclusive;
  _SipMode _sipMode = _SipMode.sip;

  final _gstAmountController = TextEditingController();
  final _gstRateController = TextEditingController(text: '18');
  final _sipMonthlyController = TextEditingController();
  final _sipLumpsumController = TextEditingController();
  final _sipYearsController = TextEditingController(text: '10');
  final _sipRateController = TextEditingController(text: '12');
  final _emiPrincipalController = TextEditingController();
  final _emiYearsController = TextEditingController(text: '5');
  final _emiRateController = TextEditingController(text: '9');
  final _simpleExprController = TextEditingController();

  double _gstBase = 0;
  double _gstTax = 0;
  double _gstTotal = 0;

  double _sipInvested = 0;
  double _sipValue = 0;
  List<_SipYearPoint> _sipPoints = const [];

  double _emiMonthly = 0;
  double _emiInterest = 0;
  double _emiTotal = 0;

  String _simpleResult = 'Enter expression';

  @override
  void initState() {
    super.initState();
    _gstAmountController.addListener(_calculateGstLive);
    _gstRateController.addListener(_calculateGstLive);
    _sipMonthlyController.addListener(_calculateSipLive);
    _sipLumpsumController.addListener(_calculateSipLive);
    _sipYearsController.addListener(_calculateSipLive);
    _sipRateController.addListener(_calculateSipLive);
    _emiPrincipalController.addListener(_calculateEmiLive);
    _emiYearsController.addListener(_calculateEmiLive);
    _emiRateController.addListener(_calculateEmiLive);
    _simpleExprController.addListener(_calculateSimpleLive);
    _calculateGstLive();
    _calculateSipLive();
    _calculateEmiLive();
    _calculateSimpleLive();
  }

  @override
  void dispose() {
    _gstAmountController.dispose();
    _gstRateController.dispose();
    _sipMonthlyController.dispose();
    _sipLumpsumController.dispose();
    _sipYearsController.dispose();
    _sipRateController.dispose();
    _emiPrincipalController.dispose();
    _emiYearsController.dispose();
    _emiRateController.dispose();
    _simpleExprController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) => double.tryParse(controller.text.trim()) ?? 0.0;

  /// Readable labels on light theme (default ChoiceChip styling is often too faint).
  Widget _calcChip({
    required bool isDark,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final muted = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    return ChoiceChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.1,
          height: 1.2,
          color: selected ? const Color(0xFF1857E6) : muted,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFFE2EBFF),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: selected
            ? const Color(0xFF1857E6)
            : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        width: selected ? 1.5 : 1,
      ),
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.zero,
      onSelected: onSelected,
    );
  }

  String _money(num value) {
    final v = value.abs();
    String withCommas(String n) {
      final parts = n.split('.');
      final whole = parts[0];
      if (whole.length <= 3) return n;
      final last3 = whole.substring(whole.length - 3);
      var leading = whole.substring(0, whole.length - 3);
      final chunks = <String>[];
      while (leading.length > 2) {
        chunks.insert(0, leading.substring(leading.length - 2));
        leading = leading.substring(0, leading.length - 2);
      }
      if (leading.isNotEmpty) chunks.insert(0, leading);
      final joined = '${chunks.join(',')},$last3';
      return parts.length > 1 ? '$joined.${parts[1]}' : joined;
    }

    final fixed = v.toStringAsFixed(2);
    final formatted = withCommas(fixed);
    return '${value < 0 ? '-' : ''}Rs $formatted';
  }

  void _calculateGstLive() {
    final amount = _parse(_gstAmountController);
    final rate = _parse(_gstRateController);
    if (amount <= 0 || rate < 0) {
      setState(() {
        _gstBase = 0;
        _gstTax = 0;
        _gstTotal = 0;
      });
      return;
    }
    double base;
    double tax;
    double total;
    if (_gstMode == _GstMode.exclusive) {
      base = amount;
      tax = base * (rate / 100);
      total = base + tax;
    } else {
      total = amount;
      base = total * 100 / (100 + rate);
      tax = total - base;
    }
    setState(() {
      _gstBase = base;
      _gstTax = tax;
      _gstTotal = total;
    });
  }

  void _calculateSipLive() {
    final monthly = _parse(_sipMonthlyController);
    final lumpsum = _parse(_sipLumpsumController);
    final years = _parse(_sipYearsController);
    final annualRate = _parse(_sipRateController);
    final months = (years * 12).round();
    if (months <= 0) {
      setState(() {
        _sipInvested = 0;
        _sipValue = 0;
        _sipPoints = const [];
      });
      return;
    }
    final monthlyRate = annualRate / 12 / 100;
    double value = 0;
    double invested = 0;
    final points = <_SipYearPoint>[];
    if (_sipMode == _SipMode.sip) {
      for (int m = 1; m <= months; m++) {
        value = (value + monthly) * (1 + monthlyRate);
        invested += monthly;
        if (m % 12 == 0 || m == months) {
          points.add(
            _SipYearPoint(
              year: (m / 12).ceil(),
              invested: invested,
              value: value,
            ),
          );
        }
      }
    } else {
      invested = lumpsum;
      for (int y = 1; y <= years.ceil(); y++) {
        value = monthlyRate == 0 ? invested : invested * math.pow(1 + annualRate / 100, y);
        points.add(_SipYearPoint(year: y, invested: invested, value: value));
      }
      if (years < 1) {
        value = monthlyRate == 0 ? invested : invested * math.pow(1 + annualRate / 100, years);
      }
    }
    setState(() {
      _sipInvested = invested;
      _sipValue = value;
      _sipPoints = points;
    });
  }

  void _calculateEmiLive() {
    final principal = _parse(_emiPrincipalController);
    final years = _parse(_emiYearsController);
    final annualRate = _parse(_emiRateController);
    final months = (years * 12).round();
    if (months <= 0 || principal <= 0) {
      setState(() {
        _emiMonthly = 0;
        _emiInterest = 0;
        _emiTotal = 0;
      });
      return;
    }
    final monthlyRate = annualRate / 12 / 100;
    final emi = monthlyRate == 0
        ? principal / months
        : principal *
            monthlyRate *
            math.pow(1 + monthlyRate, months) /
            (math.pow(1 + monthlyRate, months) - 1);
    final totalPayable = emi * months;
    final interest = totalPayable - principal;
    setState(() {
      _emiMonthly = emi;
      _emiInterest = interest;
      _emiTotal = totalPayable;
    });
  }

  void _calculateSimpleLive() {
    final expr = _simpleExprController.text.replaceAll(' ', '');
    if (expr.isEmpty) {
      setState(() => _simpleResult = 'Enter expression');
      return;
    }
    final match = RegExp(r'^(-?\d+(\.\d+)?)([+\-*/])(-?\d+(\.\d+)?)$').firstMatch(expr);
    if (match == null) {
      setState(() => _simpleResult = 'Use format like 12+8, 20*3, 50/5');
      return;
    }
    final a = double.parse(match.group(1)!);
    final op = match.group(3)!;
    final b = double.parse(match.group(4)!);
    double result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        if (b == 0) {
          setState(() => _simpleResult = 'Cannot divide by zero');
          return;
        }
        result = a / b;
        break;
      default:
        setState(() => _simpleResult = 'Unsupported operation');
        return;
    }
    setState(() => _simpleResult = 'Result: ${_money(result)}');
  }

  void _resetCurrentCalculator() {
    switch (_tab) {
      case _CalcTab.gst:
        _gstAmountController.clear();
        _gstRateController.text = '18';
        _gstMode = _GstMode.exclusive;
        _calculateGstLive();
        break;
      case _CalcTab.sip:
        _sipMonthlyController.clear();
        _sipLumpsumController.clear();
        _sipYearsController.text = '10';
        _sipRateController.text = '12';
        _sipMode = _SipMode.sip;
        _calculateSipLive();
        break;
      case _CalcTab.emi:
        _emiPrincipalController.clear();
        _emiYearsController.text = '5';
        _emiRateController.text = '9';
        _calculateEmiLive();
        break;
      case _CalcTab.simple:
        _simpleExprController.clear();
        _calculateSimpleLive();
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculators'),
        actions: [
          TextButton.icon(
            onPressed: _resetCurrentCalculator,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _calcChip(
                isDark: isDark,
                label: 'GST',
                selected: _tab == _CalcTab.gst,
                onSelected: (_) => setState(() => _tab = _CalcTab.gst),
              ),
              _calcChip(
                isDark: isDark,
                label: 'SIP',
                selected: _tab == _CalcTab.sip,
                onSelected: (_) => setState(() => _tab = _CalcTab.sip),
              ),
              _calcChip(
                isDark: isDark,
                label: 'EMI',
                selected: _tab == _CalcTab.emi,
                onSelected: (_) => setState(() => _tab = _CalcTab.emi),
              ),
              _calcChip(
                isDark: isDark,
                label: 'Simple',
                selected: _tab == _CalcTab.simple,
                onSelected: (_) => setState(() => _tab = _CalcTab.simple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab == _CalcTab.gst)
            _CalcCard(
              title: 'GST Calculator',
              subtitle: 'Switch between Tax Exclusive and Tax Inclusive.',
              isDark: isDark,
              fields: [
                Row(
                  children: [
                    Expanded(
                      child: _calcChip(
                        isDark: isDark,
                        label: 'Tax Exclusive',
                        selected: _gstMode == _GstMode.exclusive,
                        onSelected: (_) {
                          setState(() => _gstMode = _GstMode.exclusive);
                          _calculateGstLive();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _calcChip(
                        isDark: isDark,
                        label: 'Tax Inclusive',
                        selected: _gstMode == _GstMode.inclusive,
                        onSelected: (_) {
                          setState(() => _gstMode = _GstMode.inclusive);
                          _calculateGstLive();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _NumberField(controller: _gstAmountController, label: 'Amount'),
                _NumberField(controller: _gstRateController, label: 'GST %'),
              ],
              resultWidget: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _SummaryBlock(
                  key: ValueKey('${_gstBase.toStringAsFixed(2)}-${_gstTax.toStringAsFixed(2)}'),
                  lines: [
                    'Base Amount: ${_money(_gstBase)}',
                    'GST Amount: ${_money(_gstTax)}',
                    'Total: ${_money(_gstTotal)}',
                  ],
                ),
              ),
            ),
          if (_tab == _CalcTab.sip)
            _CalcCard(
              title: 'SIP & Lumpsum Calculator',
              subtitle: 'Live projection with yearly graph and allocation pie.',
              isDark: isDark,
              fields: [
                Row(
                  children: [
                    Expanded(
                      child: _calcChip(
                        isDark: isDark,
                        label: 'SIP',
                        selected: _sipMode == _SipMode.sip,
                        onSelected: (_) {
                          setState(() => _sipMode = _SipMode.sip);
                          _calculateSipLive();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _calcChip(
                        isDark: isDark,
                        label: 'Lumpsum',
                        selected: _sipMode == _SipMode.lumpsum,
                        onSelected: (_) {
                          setState(() => _sipMode = _SipMode.lumpsum);
                          _calculateSipLive();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_sipMode == _SipMode.sip)
                  _NumberField(controller: _sipMonthlyController, label: 'Monthly Investment'),
                if (_sipMode == _SipMode.lumpsum)
                  _NumberField(controller: _sipLumpsumController, label: 'Lumpsum Amount'),
                _NumberField(controller: _sipYearsController, label: 'Years'),
                _NumberField(controller: _sipRateController, label: 'Expected Return % (annual)'),
              ],
              resultWidget: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey('${_sipInvested.toStringAsFixed(1)}-${_sipValue.toStringAsFixed(1)}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryBlock(
                      lines: [
                        'Invested: ${_money(_sipInvested)}',
                        'Current Value: ${_money(_sipValue)}',
                        'Returns: ${_money(_sipValue - _sipInvested)}',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel('Growth Chart (Year vs Value)'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: _SipLineChart(points: _sipPoints),
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel('Invested vs Returns'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: _PieChart(
                        slices: [
                          _PieSlice(
                            label: 'Invested',
                            value: _sipInvested,
                            color: const Color(0xFF1857E6),
                          ),
                          _PieSlice(
                            label: 'Returns',
                            value: math.max(0, _sipValue - _sipInvested),
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_tab == _CalcTab.emi)
            _CalcCard(
              title: 'EMI Calculator',
              subtitle: 'Live monthly EMI with dynamic principal-interest split.',
              isDark: isDark,
              fields: [
                _NumberField(controller: _emiPrincipalController, label: 'Loan Amount'),
                _NumberField(controller: _emiYearsController, label: 'Tenure (Years)'),
                _NumberField(controller: _emiRateController, label: 'Interest % (annual)'),
              ],
              resultWidget: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey('${_emiMonthly.toStringAsFixed(1)}-${_emiTotal.toStringAsFixed(1)}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryBlock(
                      lines: [
                        'Monthly EMI: ${_money(_emiMonthly)}',
                        'Total Interest: ${_money(_emiInterest)}',
                        'Total Payable: ${_money(_emiTotal)}',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel('Principal vs Interest'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: _PieChart(
                        slices: [
                          _PieSlice(
                            label: 'Principal',
                            value: _parse(_emiPrincipalController),
                            color: const Color(0xFF1857E6),
                          ),
                          _PieSlice(
                            label: 'Interest',
                            value: math.max(0, _emiInterest),
                            color: const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_tab == _CalcTab.simple)
            _CalcCard(
              title: 'Simple Calculator',
              subtitle: 'Real-time result. No need to press calculate.',
              isDark: isDark,
              fields: [
                TextField(
                  controller: _simpleExprController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-*/. ]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Expression (e.g. 120*3)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              resultWidget: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _SummaryBlock(
                  key: ValueKey(_simpleResult),
                  lines: [_simpleResult],
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final Widget resultWidget;
  final bool isDark;

  const _CalcCard({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.resultWidget,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          ...fields,
          const SizedBox(height: 12),
          resultWidget,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumberField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final List<String> lines;

  const _SummaryBlock({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
    );
  }
}

class _SipLineChart extends StatelessWidget {
  final List<_SipYearPoint> points;
  const _SipLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SipLineChartPainter(points: points),
      child: const SizedBox.expand(),
    );
  }
}

class _SipLineChartPainter extends CustomPainter {
  final List<_SipYearPoint> points;
  _SipLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1;
    final investedPaint = Paint()
      ..color = const Color(0xFF1857E6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final valuePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final left = 16.0;
    final bottom = size.height - 16;
    final top = 8.0;
    final right = size.width - 8;
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);
    if (points.length < 2) return;

    final maxY = points
        .map((p) => math.max(p.invested, p.value))
        .fold<double>(1, (a, b) => math.max(a, b));
    final dx = (right - left) / (points.length - 1);

    final investedPath = Path();
    final valuePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = left + (dx * i);
      final investedY = bottom - ((points[i].invested / maxY) * (bottom - top));
      final valueY = bottom - ((points[i].value / maxY) * (bottom - top));
      if (i == 0) {
        investedPath.moveTo(x, investedY);
        valuePath.moveTo(x, valueY);
      } else {
        investedPath.lineTo(x, investedY);
        valuePath.lineTo(x, valueY);
      }
    }
    canvas.drawPath(investedPath, investedPaint);
    canvas.drawPath(valuePath, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _SipLineChartPainter oldDelegate) => oldDelegate.points != points;
}

class _PieSlice {
  final String label;
  final double value;
  final Color color;

  const _PieSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _PieChart extends StatelessWidget {
  final List<_PieSlice> slices;
  const _PieChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legendStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: isDark ? Colors.white : const Color(0xFF334155),
    );
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      return const Center(child: Text('Enter values to see chart'));
    }
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PieChartPainter(slices: slices),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, color: s.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${s.label}: ${(s.value / total * 100).toStringAsFixed(1)}%',
                            style: legendStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  const _PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, paint);
      start += sweep;
    }
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => oldDelegate.slices != slices;
}
