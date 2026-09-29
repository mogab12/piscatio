abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const history = '/history';
  static const stats = '/stats';
  static const settings = '/settings';
  static const baits = '/settings/baits';
  static const gear = '/settings/gear';
  static const account = '/settings/account';
  static const activeTrip = '/trip/active';
  static const pastTrip = '/past-trip';

  static String trip(String id) => '/trip/$id';
  static String editTrip(String id) => '/trip/$id/edit';
  static String capture(String tripId, {String? photo}) => photo == null
      ? '/capture/$tripId'
      : Uri(
          path: '/capture/$tripId',
          queryParameters: {'photo': photo},
        ).toString();
  static String catchDetail(String id) => '/catch/$id';
  static String tripSummary(String id) => '/summary/$id';
  static String tripCard(String id) => '/cards/trip/$id';
  static String catchCard(String id) => '/cards/catch/$id';
}
