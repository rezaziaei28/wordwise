import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/features/review/widgets/swipe_stack.dart';

void main() {
  late List<Grade> swipes;
  late SwipeStackKey key;

  Widget harness() => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 400,
            child: SwipeStack(
              key: key,
              itemKey: 1,
              current: const ColoredBox(color: Colors.blue, child: Text('current')),
              next: const ColoredBox(color: Colors.grey, child: Text('next')),
              onSwipe: (g) async => swipes.add(g),
            ),
          ),
        ),
      );

  setUp(() {
    swipes = [];
    key = SwipeStackKey();
  });

  testWidgets('a short drag springs back without grading', (tester) async {
    await tester.pumpWidget(harness());
    await tester.drag(find.text('current'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(swipes, isEmpty);
    expect(find.text('current'), findsOneWidget);
  });

  testWidgets('right past the threshold = know, left = unknown, down = issues', (tester) async {
    for (final (offset, grade) in [
      (const Offset(200, 0), Grade.know),
      (const Offset(-200, 0), Grade.unknown),
      (const Offset(0, 220), Grade.issues),
    ]) {
      swipes = [];
      key = SwipeStackKey();
      await tester.pumpWidget(harness());
      await tester.drag(find.text('current'), offset);
      await tester.pumpAndSettle();
      expect(swipes, [grade], reason: 'drag $offset');
    }
  });

  testWidgets('a hint with the outcome and its meaning shows while dragging', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.text('EASY'), findsNothing);
    final start = tester.getCenter(find.text('current'));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(find.text('EASY'), findsOneWidget);
    expect(find.text('Never show again'), findsOneWidget);
    await gesture.moveBy(const Offset(100, 0)); // past 35 % of 300 px
    await tester.pump();
    expect(find.text('release'), findsOneWidget);
    await gesture.moveTo(start + const Offset(0, 60));
    await tester.pump();
    expect(find.text('SHAKY'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(swipes, isEmpty);
  });

  testWidgets('a second grade during the fly animation is ignored', (tester) async {
    await tester.pumpWidget(harness());
    final first = key.commit(Grade.know);
    await tester.pump(const Duration(milliseconds: 60)); // mid-flight
    final second = key.commit(Grade.unknown); // double tap
    await tester.pumpAndSettle();
    await Future.wait([first, second]);
    expect(swipes, [Grade.know], reason: 'the card underneath is not graded unseen');
  });

  testWidgets('dragging during the fly animation does not grade again', (tester) async {
    await tester.pumpWidget(harness());
    final done = key.commit(Grade.know);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.drag(find.text('current'), const Offset(-250, 0));
    await tester.pumpAndSettle();
    await done;
    expect(swipes, [Grade.know]);
  });

  testWidgets('buttons commit through the stack key', (tester) async {
    await tester.pumpWidget(harness());
    final done = key.commit(Grade.issues);
    await tester.pumpAndSettle();
    await done;
    expect(swipes, [Grade.issues]);
  });
}
