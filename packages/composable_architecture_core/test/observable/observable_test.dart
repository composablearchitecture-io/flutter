import 'package:composable_architecture_core/src/utils/current_value_subject.dart';
import 'package:test/test.dart';

void main() {
  group("map", () {
    test("transforms values", () {
      final subject = CurrentValueSubject.create(1);
      final mapped = subject.map((v) => v * 10);
      final results = <int>[];
      mapped.listen(results.add);

      subject.add(2);
      subject.add(3);

      expect(results, [10, 20, 30]);
    });

    test("transforms to different type", () {
      final subject = CurrentValueSubject.create(1);
      final mapped = subject.map((v) => "value: $v");
      final results = <String>[];
      mapped.listen(results.add);

      subject.add(2);

      expect(results, ["value: 1", "value: 2"]);
    });
  });

  group("distinct", () {
    test("filters consecutive duplicates", () {
      final subject = CurrentValueSubject.create(1);
      final distinct = subject.distinct();
      final results = <int>[];
      distinct.listen(results.add);

      subject.add(1);
      subject.add(2);
      subject.add(2);
      subject.add(3);
      subject.add(3);
      subject.add(1);

      expect(results, [1, 2, 3, 1]);
    });

    test("uses custom equality", () {
      final subject = CurrentValueSubject.create(1);
      final distinct = subject.distinct(
        (a, b) => a ~/ 10 == b ~/ 10,
      );
      final results = <int>[];
      distinct.listen(results.add);

      subject.add(5);
      subject.add(10);
      subject.add(15);
      subject.add(20);

      expect(results, [1, 10, 20]);
    });
  });

  group("when", () {
    test("filters values by predicate", () {
      final subject = CurrentValueSubject.create(0);
      final even = subject.when((v) => v.isEven);
      final results = <int>[];
      even.listen(results.add);

      subject.add(1);
      subject.add(2);
      subject.add(3);
      subject.add(4);

      expect(results, [0, 2, 4]);
    });
  });

  group("chaining", () {
    test("map then distinct", () {
      final subject = CurrentValueSubject.create(1);
      final chained = subject.map((v) => v ~/ 10).distinct();
      final results = <int>[];
      chained.listen(results.add);

      subject.add(5);
      subject.add(10);
      subject.add(15);
      subject.add(20);

      expect(results, [0, 1, 2]);
    });

    test("when then map", () {
      final subject = CurrentValueSubject.create(0);
      final chained = subject.when((v) => v.isEven).map((v) => v * 2);
      final results = <int>[];
      chained.listen(results.add);

      subject.add(1);
      subject.add(2);
      subject.add(3);
      subject.add(4);

      expect(results, [0, 4, 8]);
    });

    test("map then distinct then when", () {
      final subject = CurrentValueSubject.create(0);
      final chained = subject.map((v) => v ~/ 2).distinct().when((v) => v > 0);
      final results = <int>[];
      chained.listen(results.add);

      subject.add(1);
      subject.add(2);
      subject.add(3);
      subject.add(4);

      expect(results, [1, 2]);
    });
  });

  group("cancel", () {
    test("cancelling derived observable stops updates", () {
      final subject = CurrentValueSubject.create(0);
      final mapped = subject.map((v) => v * 2);
      final results = <int>[];
      final id = mapped.listen(results.add);

      subject.add(1);
      mapped.cancel(id);
      subject.add(2);

      expect(results, [0, 2]);
    });
  });
}
