abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const history = '/history';
  static const settings = '/settings';
  static const activeTrip = '/trip/active';

  static String trip(String id) => '/trip/$id';
  static String editTrip(String id) => '/trip/$id/edit';
  static String capture(String tripId) => '/capture/$tripId';
  static String catchDetail(String id) => '/catch/$id';
  static String tripSummary(String id) => '/summary/$id';
  static String tripCard(String id) => '/cards/trip/$id';
  static String catchCard(String id) => '/cards/catch/$id';
}
