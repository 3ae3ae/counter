import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:english_words/english_words.dart';

class Counter {
  String name;
  int value;
  HSLColor hslColor;
  Color _textColor = Colors.amber;
  Counter({required this.name, required this.value, required this.hslColor}) {
    _textColor = hslColor.lightness > 0.5 ? Colors.black : Colors.white;
  }

  void changeName(String newName) {
    name = newName;
  }

  void changeHSL(HSLColor newHslColor) {
    hslColor = newHslColor;
    _textColor = hslColor.lightness > 0.5 ? Colors.black : Colors.white;
  }

  void changeValue(int newValue) {
    value = newValue;
  }

  void plusValue(int amount) {
    value += amount;
  }

  Color returnTextColor() {
    return _textColor;
  }
}

class CounterNotifier extends StateNotifier<List<Counter>> {
  CounterNotifier() : super([]);

  void addCounter(
      {required String name, required int value, required HSLColor hslColor}) {
    state = [...state, Counter(name: name, hslColor: hslColor, value: value)];
  }

  void changeName({required int index, required String newName}) {
    state[index].changeName(newName);
    state = state.toList();
  }

  void changeHSL({required int index, required HSLColor newHslColor}) {
    state[index].changeHSL(newHslColor);
    state = state.toList();
  }

  void changeValue({required int index, required int newValue}) {
    state[index].changeValue(newValue);
    state = state.toList();
  }

  void plusValue({required int index, required int amount}) {
    state[index].plusValue(amount);
    state = state.toList();
  }

  void removeCounter({required int index}) {
    state.removeAt(index);
    state = state.toList();
  }
}

final counterProvider =
    StateNotifierProvider<CounterNotifier, List<Counter>>((ref) {
  return CounterNotifier();
});

void main() {
  runApp(const ProviderScope(
      child: MaterialApp(debugShowCheckedModeBanner: false, home: MainApp())));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  final HSLColor hslColor = HSLColor.fromAHSL(
                      1,
                      Random().nextDouble() * 360,
                      Random().nextDouble(),
                      Random().nextDouble());
                  final String name = nouns[Random().nextInt(2500)];
                  ref
                      .read(counterProvider.notifier)
                      .addCounter(name: name, value: 0, hslColor: hslColor);
                },
                icon: const Icon(Icons.add)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
          ],
          title: const Text('Counter'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final itemCount = ref.watch(counterProvider).length;
            if (itemCount == 0) {
              return InkWell(
                onTap: () {
                  final HSLColor hslColor = HSLColor.fromAHSL(
                      1,
                      Random().nextDouble() * 360,
                      Random().nextDouble(),
                      Random().nextDouble());
                  final String name = nouns[Random().nextInt(2500)];
                  ref
                      .read(counterProvider.notifier)
                      .addCounter(name: name, value: 0, hslColor: hslColor);
                },
                child: const Center(
                  child: Text('오른쪽 위의 + 버튼을 눌러 카운터를 추가하세요'),
                ),
              );
            }
            if (constraints.maxHeight > itemCount * 112) {
              return Column(
                children: [
                  for (var i = 0; i < itemCount; i++)
                    Expanded(child: CounterWidget(index: i))
                ],
              );
            } else {
              return CustomScrollView(
                slivers: [
                  SliverList.builder(
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 112,
                        ),
                        child: CounterWidget(
                          index: index,
                        ),
                      );
                    },
                  )
                ],
              );
            }
          },
        ));
  }
}

class CounterWidget extends ConsumerStatefulWidget {
  final int index;
  const CounterWidget({super.key, required this.index});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends ConsumerState<CounterWidget> {
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final counters = ref.watch(counterProvider);
    final name = counters[index].name;
    final value = counters[index].value;
    final color = counters[index].hslColor.toColor();
    final textColor = counters[index].returnTextColor();
    final T = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        color: color,
        constraints: const BoxConstraints(
          minHeight: 96,
          minWidth: double.infinity,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: color,
                child: GestureDetector(
                  onLongPress: () {
                    setState(() {
                      timer = Timer.periodic(const Duration(milliseconds: 50),
                          (timer) {
                        ref
                            .read(counterProvider.notifier)
                            .plusValue(index: index, amount: -1);
                      });
                    });
                  },
                  onLongPressEnd: (details) {
                    setState(() {
                      timer?.cancel();
                    });
                  },
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(counterProvider.notifier)
                          .plusValue(index: index, amount: -1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            Icons.remove,
                            color: textColor,
                          )),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return DialogUI(index: index);
                        });
                  },
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: T.headlineSmall?.copyWith(color: textColor),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Icon(
                        Icons.edit,
                        color: textColor.withAlpha(123),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      value.toString(),
                      style: T.headlineMedium?.copyWith(color: textColor),
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: Material(
                color: color,
                child: GestureDetector(
                  onLongPress: () {
                    setState(() {
                      timer = Timer.periodic(const Duration(milliseconds: 50),
                          (timer) {
                        ref
                            .read(counterProvider.notifier)
                            .plusValue(index: index, amount: 1);
                      });
                    });
                  },
                  onLongPressEnd: (details) {
                    setState(() {
                      timer?.cancel();
                    });
                  },
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(counterProvider.notifier)
                          .plusValue(index: index, amount: 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.add,
                            color: textColor,
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogUI extends ConsumerStatefulWidget {
  final int index;
  const DialogUI({super.key, required this.index});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DialogUIState();
}

class _DialogUIState extends ConsumerState<DialogUI> {
  late TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final T = Theme.of(context).textTheme;
    final index = widget.index;
    final oldName = ref.watch(counterProvider)[index].name;
    return Dialog(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Enter new name',
              style: T.headlineSmall,
            ),
            SizedBox(
              width: 200,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: oldName,
                ),
                controller: _textController,
                onSubmitted: _submitted,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submitted(_textController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitted(String value) {
    if (value.length > 10) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text("The name is too long. Use a shorter name.")));
    } else {
      ref
          .read(counterProvider.notifier)
          .changeName(index: widget.index, newName: value);
      Navigator.pop(context);
    }
  }
}
