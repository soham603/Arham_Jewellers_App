import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/widgets/pdf_page_tick_viewer.dart';

class PdfPageSelectionPage extends StatefulWidget {
  final String catalogTitle;
  final PdfCatalogPageModel page;
  final Offset? initialTick;

  const PdfPageSelectionPage({
    super.key,
    required this.catalogTitle,
    required this.page,
    this.initialTick,
  });

  @override
  State<PdfPageSelectionPage> createState() => _PdfPageSelectionPageState();
}

class _PdfPageSelectionPageState extends State<PdfPageSelectionPage> {
  Offset? _tick;

  @override
  void initState() {
    super.initState();
    _tick = widget.initialTick;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.catalogTitle} · Page ${widget.page.pageNumber}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPageTickViewer(
              imageUrl: widget.page.imageUrl,
              imageWidth: widget.page.width,
              imageHeight: widget.page.height,
              initialTick: _tick,
              onTickChanged: (tick) => _tick = tick,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tick == null
                        ? 'Tap on the design you want to select'
                        : 'Design selected. Tap again to move the tick-mark.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _tick == null ? null : () => Get.back(result: _tick),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8860B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save selection'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
