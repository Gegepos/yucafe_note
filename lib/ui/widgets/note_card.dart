import 'package:flutter/material.dart';
import '../../models/coffee_note.dart';

class NoteCard extends StatefulWidget {
  final CoffeeNote note;

  /// 点「去冲煮」时回调；为 null 时不显示该按钮。
  final VoidCallback? onBrew;

  const NoteCard({super.key, required this.note, this.onBrew});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.coffee),
            title: Text(n.beanName ?? '未知咖啡豆'),
            subtitle: Text(n.beanBrand ?? ''),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _paramRow('豆量', '${n.weight}g'),
                  _paramRow('磨豆机', n.grinder),
                  _paramRow('研磨度', n.grinderSize),
                  _paramRow('冲煮器具', n.brewingDevices),
                  _paramRow('水温', n.waterTemperature),
                  _paramRow('粉水比', n.brewRatio),
                  if (n.brewRecipe != null) _paramRow('冲煮方案', n.brewRecipe!),
                  if (widget.onBrew != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: widget.onBrew,
                        icon: const Icon(Icons.local_cafe_outlined, size: 18),
                        label: const Text('去冲煮'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _paramRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
