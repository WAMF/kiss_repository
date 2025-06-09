import 'package:kiss_repository/kiss_repository.dart';
import '../../queries/user_queries.dart';

class PocketBaseUserQueryBuilder implements QueryBuilder<String> {
  @override
  String build(Query query) {
    if (query is QueryByName) {
      return "name ~ '${query.searchTerm}'";
    }

    if (query is QueryByEmail) {
      return "email ~ '${query.emailDomain}'";
    }

    if (query is QueryByMaxAge) {
      final cutoffDate = DateTime.now().subtract(Duration(days: query.maxAge));
      final cutoffString = cutoffDate.toIso8601String();
      return "created >= '$cutoffString'";
    }

    // Default: return all users
    return "";
  }
}
