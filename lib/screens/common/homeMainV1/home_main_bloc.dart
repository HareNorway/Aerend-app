import '../../../blocs/bloc.dart';

class HomeMainBloc extends Bloc {
  final subjectCurrentPage = BehaviorSubject<int>.seeded(2);

  @override
  void dispose() {
    subjectCurrentPage.close();
  }
}
