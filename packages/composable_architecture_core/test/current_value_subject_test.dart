import 'package:composable_architecture_core/src/utils/current_value_subject.dart';
import 'package:test/test.dart';

void main() {
  test("base test", () {
    final subject = CurrentValueSubject.create(2);
    final subjectList = <int>[];
    subject.listen(subjectList.add);

    expect(subjectList[0], 2);
    subject.add(4);
    expect(subjectList[1], 4);
  });

  test("derived subject test", () async {
    final subject = CurrentValueSubject.create(2);
    final derived = subject.derive((e) => e);
    final subjectList = <int>[];
    subject.listen(subjectList.add);
    final derivedList = <int>[];
    derived.listen(derivedList.add);
    subject.add(4);
    expect(() => derived.add(5), throwsA(anything));
    subject.dispose();
    expect([2, 4], subjectList);
    expect([2, 4], derivedList);
  });
  test("Test on stream", () async {
    final subject = CurrentValueSubject.create(0);
    final list = <int>[];
    subject.listen(list.add);
    subject.add(1);
    subject.add(2);
    subject.add(3);
    subject.dispose();
    expect([0, 1, 2, 3], list);
  });

  test("Test on derived stream", () async {
    final subject = CurrentValueSubject.create(0);
    final derived = subject.derive((e) => e);
    final list = <int>[];
    derived.listen(list.add);
    subject.add(1);
    subject.add(2);
    subject.add(3);
    subject.dispose();
    expect([0, 1, 2, 3], list);
  });
}
