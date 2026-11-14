/// Route paths.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const home = '/home';
  static const notifications = '/notifications';

  static const results = '/search/results';
  static const fare = '/booking/fare';
  static const passengers = '/booking/passengers';
  static const seats = '/booking/seats';
  static const review = '/booking/review';
  static const confirmed = '/booking/confirmed';

  static const trip = '/trip';
  static String tripDetails(String reference) => '$trip/$reference';
  static String confirmedFor(String reference) => '$confirmed/$reference';

  static const personalInfo = '/profile/personal';
  static const savedTravellers = '/profile/travellers';
  static const paymentMethods = '/profile/payments';
  static const travelDocuments = '/profile/documents';
}
