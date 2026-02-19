import 'package:hive/hive.dart';
import 'package:mrmoney/models/investment.dart';
import 'package:mrmoney/repositories/base_repository.dart';

class InvestmentRepository extends BaseRepository<Investment> {
  InvestmentRepository() : super(Hive.box<Investment>('investments'));
}
