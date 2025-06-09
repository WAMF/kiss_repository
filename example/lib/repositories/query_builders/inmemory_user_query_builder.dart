import 'package:kiss_repository/kiss_repository.dart';
import '../../models/user.dart';
import '../../queries/user_queries.dart';

class InMemoryUserQueryBuilder implements QueryBuilder<InMemoryFilterQuery<User>> {
  @override
  InMemoryFilterQuery<User> build(Query query) {
    if (query is QueryByName) {
      return InMemoryFilterQuery<User>((user) => user.name.toLowerCase().contains(query.searchTerm.toLowerCase()));
    }

    if (query is QueryByEmail) {
      return InMemoryFilterQuery<User>((user) => user.email.toLowerCase().contains(query.emailDomain.toLowerCase()));
    }

    if (query is QueryByMaxAge) {
      final cutoffDate = DateTime.now().subtract(Duration(days: query.maxAge));
      return InMemoryFilterQuery<User>((user) => user.createdAt.isAfter(cutoffDate));
    }

    // Default: return all users
    return InMemoryFilterQuery<User>((user) => true);
  }
}
