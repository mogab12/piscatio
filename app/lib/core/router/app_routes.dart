abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const history = '/history';
  static const stats = '/stats';
  static const community = '/community';
  static const communityProfile = '/community/profile';
  static const communitySearch = '/community/people';
  static const communityRequests = '/community/requests';
  static const communityBlocked = '/community/blocked';
  static const settings = '/settings';
  static const baits = '/settings/baits';
  static const gear = '/settings/gear';
  static const account = '/settings/account';
  static const activeTrip = '/trip/active';
  static const pastTrip = '/past-trip';

  static String person(String handle) => '/people/$handle';
  static String followers(String handle) => '/people/$handle/followers';
  static String following(String handle) => '/people/$handle/following';
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
  static String yearCard(int year) => '/cards/year/$year';
  static String yearSummary(int year) => '/stats/year/$year';
}
