class ApiEndpoints {
  static const String baseUrl = "https://prakrutitech.xyz/gaurang/";

  // Auth
  static const String login = "${baseUrl}login.php";
  static const String register = "${baseUrl}register.php";

  // Artist Profile
  static const String addArtistProfile = "${baseUrl}add_artist_profile.php";
  static const String updateArtistProfile = "${baseUrl}update_artist_profile.php";
  static const String viewArtistProfile = "${baseUrl}view_artist_profile.php";
  static const String artistDetails = "${baseUrl}artist_details.php";

  // Media
  static const String addArtistMedia = "${baseUrl}add_artist_media.php";
  static const String getMedia = "${baseUrl}get_media.php";
  static const String viewArtistMedia = "${baseUrl}view_artist_media_by_id.php";
  static const String updateArtistMedia = "${baseUrl}update_artist_media.php";
  static const String deleteArtistMedia = "${baseUrl}delete_artist_media.php";

  // Bookings
  static const String addBooking = "${baseUrl}add_bookings.php";
  static const String viewBooking = "${baseUrl}view_booking.php";
  static const String viewBookingById = "${baseUrl}view_booking_by_id.php";
  static const String artistBookingCancel = "${baseUrl}artist_booking_cancel.php";
  static const String customerBookingCancel = "${baseUrl}customer_booking_cancel.php";
  static const String updateBooking = "${baseUrl}update_bookings.php";

  // Reviews & Comments
  static const String addReview = "${baseUrl}add_review.php";
  static const String viewReview = "${baseUrl}view_review.php";
  static const String addComment = "${baseUrl}add_comments.php";
  static const String viewComments = "${baseUrl}view_comments.php";
  static const String updateComment = "${baseUrl}update_comments.php";
  static const String deleteComment = "${baseUrl}delete_comments.php";

  // Likes & Shares
  static const String like = "${baseUrl}like.php";
  static const String share = "${baseUrl}share.php";
  static const String viewLikes = "${baseUrl}view_like.php";

  // Artists & Customers
  static const String viewArtist = "${baseUrl}view_artist.php";
  static const String customerViewArtist = "${baseUrl}customer_view_artist.php";
  static const String viewUser = "${baseUrl}view_user.php";
  static const String updateUser = "${baseUrl}update_user.php";

  // Feedback
  static const String addFeedback = "${baseUrl}add_feedback.php";
  static const String viewFeedback = "${baseUrl}view_feedback.php";
  static const String viewFeedbackArtist = "${baseUrl}view_feedback_artist.php";

  // Payments
  static const String addPayment = "${baseUrl}add_payments.php";
  static const String viewPayments = "${baseUrl}view_payments.php";
}