import 'package:flutter/material.dart';

class ConsoleWidget extends StatefulWidget {
  final List<String> logs;
  final Function(String) onEnviarComando;

  const ConsoleWidget({
    super.key, 
    required this.logs, 
    required this.onEnviarComando
  });

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Auto-scroll al fondo cuando llegan mensajes nuevos
  @override
  void didUpdateWidget(ConsoleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E), 
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: widget.logs.length,
              itemBuilder: (context, index) {
                final linea = widget.logs[index];
                Color color = Colors.greenAccent; 
                if (linea.startsWith("YO")) color = Colors.white;
                if (linea.startsWith("🛑")) color = Colors.redAccent;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(linea, style: TextStyle(color: color, fontFamily: 'Courier New', fontSize: 13)),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          color: Colors.white,
          child: Row(
            children: [
              const Text(" CMD > ", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(border: InputBorder.none),
                  onSubmitted: (txt) {
                    widget.onEnviarComando(txt);
                    _controller.clear();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send), 
                onPressed: () {
                  widget.onEnviarComando(_controller.text);
                  _controller.clear();
                }
              )
            ],
          ),
        ),
      ],
    );
  }
}