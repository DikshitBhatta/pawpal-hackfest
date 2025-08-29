import 'package:flutter/material.dart';
import '../ColorsScheme.dart';

/// Centralized icon management system for consistent styling across the app
class AppIcons {
  // Default icon properties
  static const double defaultSize = 24.0;
  static const double smallSize = 16.0;
  static const double mediumSize = 20.0;
  static const double largeSize = 32.0;
  static const double extraLargeSize = 40.0;
  
  static const Color primaryIconColor = Colors.teal;
  static const Color secondaryIconColor = Color(0xff584A79); // appBarColor
  static const Color warningIconColor = Colors.amber;
  static const Color errorIconColor = Colors.red;
  static const Color successIconColor = Colors.green;
  static const Color disabledIconColor = Colors.grey;
  
  // Navigation Icons
  static Icon homeIcon({double? size, Color? color}) => Icon(
    Icons.home_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon settingsIcon({double? size, Color? color}) => Icon(
    Icons.settings_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon profileIcon({double? size, Color? color}) => Icon(
    Icons.person_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon communityIcon({double? size, Color? color}) => Icon(
    Icons.people_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon shopIcon({double? size, Color? color}) => Icon(
    Icons.shopping_bag_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Pet-related Icons
  static Icon petIcon({double? size, Color? color}) => Icon(
    Icons.pets,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon addPetIcon({double? size, Color? color}) => Icon(
    Icons.add_circle_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon petFoodIcon({double? size, Color? color}) => Icon(
    Icons.restaurant_menu,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon petHealthIcon({double? size, Color? color}) => Icon(
    Icons.favorite_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon vetIcon({double? size, Color? color}) => Icon(
    Icons.local_hospital_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon exerciseIcon({double? size, Color? color}) => Icon(
    Icons.directions_run_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon weightIcon({double? size, Color? color}) => Icon(
    Icons.monitor_weight_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Action Icons
  static Icon editIcon({double? size, Color? color}) => Icon(
    Icons.edit_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon deleteIcon({double? size, Color? color}) => Icon(
    Icons.delete_rounded,
    size: size ?? defaultSize,
    color: color ?? errorIconColor,
  );
  static Icon saveIcon({double? size, Color? color}) => Icon(
    Icons.check_rounded,
    size: size ?? defaultSize,
    color: color ?? successIconColor,
  );
  static Icon cancelIcon({double? size, Color? color}) => Icon(
    Icons.close_rounded,
    size: size ?? defaultSize,
    color: color ?? errorIconColor,
  );
  static Icon backIcon({double? size, Color? color}) => Icon(
    Icons.arrow_back_ios_rounded,
    size: size ?? defaultSize,
    color: color ?? Colors.white,
  );
  static Icon forwardIcon({double? size, Color? color}) => Icon(
    Icons.arrow_forward_ios_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon refreshIcon({double? size, Color? color}) => Icon(
    Icons.refresh_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon searchIcon({double? size, Color? color}) => Icon(
    Icons.search_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon filterIcon({double? size, Color? color}) => Icon(
    Icons.filter_list_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Form Icons
  static Icon nameIcon({double? size, Color? color}) => Icon(
    Icons.badge_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon emailIcon({double? size, Color? color}) => Icon(
    Icons.email_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon phoneIcon({double? size, Color? color}) => Icon(
    Icons.phone_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon passwordIcon({double? size, Color? color}) => Icon(
    Icons.lock_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon dateIcon({double? size, Color? color}) => Icon(
    Icons.calendar_today_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon timeIcon({double? size, Color? color}) => Icon(
    Icons.access_time_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon cameraIcon({double? size, Color? color}) => Icon(
    Icons.camera_alt_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon galleryIcon({double? size, Color? color}) => Icon(
    Icons.photo_library_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon uploadIcon({double? size, Color? color}) => Icon(
    Icons.cloud_upload_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon downloadIcon({double? size, Color? color}) => Icon(
    Icons.cloud_download_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon documentIcon({double? size, Color? color}) => Icon(
    Icons.description_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon noteIcon({double? size, Color? color}) => Icon(
    Icons.note_add_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Status Icons
  static Icon warningIcon({double? size, Color? color}) => Icon(
    Icons.warning_rounded,
    size: size ?? defaultSize,
    color: color ?? warningIconColor,
  );
  static Icon errorIcon({double? size, Color? color}) => Icon(
    Icons.error_rounded,
    size: size ?? defaultSize,
    color: color ?? errorIconColor,
  );
  static Icon successIcon({double? size, Color? color}) => Icon(
    Icons.check_circle_rounded,
    size: size ?? defaultSize,
    color: color ?? successIconColor,
  );
  static Icon infoIcon({double? size, Color? color}) => Icon(
    Icons.info_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Meal and Food Icons
  static Icon mealIcon({double? size, Color? color}) => Icon(
    Icons.restaurant_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon nutritionIcon({double? size, Color? color}) => Icon(
    Icons.eco_rounded,
    size: size ?? defaultSize,
    color: color ?? successIconColor,
  );
  static Icon treatIcon({double? size, Color? color}) => Icon(
    Icons.cookie_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Activity Icons
  static Icon walkIcon({double? size, Color? color}) => Icon(
    Icons.directions_walk_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon playIcon({double? size, Color? color}) => Icon(
    Icons.sports_tennis_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon sleepIcon({double? size, Color? color}) => Icon(
    Icons.bedtime_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Shopping Icons
  static Icon cartIcon({double? size, Color? color}) => Icon(
    Icons.shopping_cart_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon purchaseIcon({double? size, Color? color}) => Icon(
    Icons.payment_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon favoriteIcon({double? size, Color? color, bool filled = false}) => Icon(
    filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    size: size ?? defaultSize,
    color: color ?? (filled ? Colors.red : primaryIconColor),
  );
  // Notification Icons
  static Icon notificationIcon({double? size, Color? color}) => Icon(
    Icons.notifications_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon reminderIcon({double? size, Color? color}) => Icon(
    Icons.schedule_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Communication Icons
  static Icon chatIcon({double? size, Color? color}) => Icon(
    Icons.chat_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon sendIcon({double? size, Color? color}) => Icon(
    Icons.send_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon callIcon({double? size, Color? color}) => Icon(
    Icons.call_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Subscription Icons
  static Icon subscriptionIcon({double? size, Color? color}) => Icon(
    Icons.card_membership_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon premiumIcon({double? size, Color? color}) => Icon(
    Icons.star_rounded,
    size: size ?? defaultSize,
    color: color ?? Colors.amber,
  );
  // Admin & Management Icons
  static Icon inventoryIcon({double? size, Color? color}) => Icon(
    Icons.inventory_2,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon analyticsIcon({double? size, Color? color}) => Icon(
    Icons.analytics_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon deliveryIcon({double? size, Color? color}) => Icon(
    Icons.local_shipping_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon userManagementIcon({double? size, Color? color}) => Icon(
    Icons.people_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon logoutIcon({double? size, Color? color}) => Icon(
    Icons.logout_rounded,
    size: size ?? defaultSize,
    color: color ?? disabledIconColor,
  );
  // Visibility Icons for passwords
  static Icon visibilityIcon({double? size, Color? color}) => Icon(
    Icons.visibility_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon visibilityOffIcon({double? size, Color? color}) => Icon(
    Icons.visibility_off_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Location Icon
  static Icon locationIcon({double? size, Color? color}) => Icon(
    Icons.location_city_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Quantity management icons
  static Icon addIcon({double? size, Color? color}) => Icon(
    Icons.add_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon removeIcon({double? size, Color? color}) => Icon(
    Icons.remove_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Published/Unpublished icons
  static Icon publishedIcon({double? size, Color? color}) => Icon(
    Icons.check_circle_rounded,
    size: size ?? defaultSize,
    color: color ?? successIconColor,
  );
  static Icon unpublishedIcon({double? size, Color? color}) => Icon(
    Icons.unpublished_rounded,
    size: size ?? defaultSize,
    color: color ?? warningIconColor,
  );
  // Section Header Icons
  static Icon fitnessIcon({double? size, Color? color}) => Icon(
    Icons.fitness_center_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon heartIcon({double? size, Color? color}) => Icon(
    Icons.monitor_heart_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  static Icon timerIcon({double? size, Color? color}) => Icon(
    Icons.timer_rounded,
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Ingredient Category Icons
  static IconData getIngredientIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'protein':
      case 'meat':
        return Icons.restaurant_menu;
      case 'vegetable':
      case 'vegetables':
        return Icons.eco;
      case 'fruit':
      case 'fruits':
        return Icons.apple;
      case 'grain':
      case 'grains':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      case 'supplement':
      case 'supplements':
        return Icons.medical_services;
      case 'fat':
      case 'oil':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }
  static Icon ingredientIcon(String? category, {double? size, Color? color}) => Icon(
    getIngredientIcon(category),
    size: size ?? defaultSize,
    color: color ?? primaryIconColor,
  );
  // Utility method to create consistent icon button
  static IconButton iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double? size,
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: size ?? defaultSize,
        color: color ?? primaryIconColor,
      ),
      tooltip: tooltip,
    );
  }
  // Utility method to create consistent floating action button
  static FloatingActionButton floatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    double? size,
    Color? backgroundColor,
    Color? foregroundColor,
    String? tooltip,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? primaryIconColor,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      child: Icon(
        icon,
        size: size ?? defaultSize,
      ),
    );
  }
}

/// Icon theme extension for easier access to themed icons
extension IconTheme on BuildContext {
  // Get themed icon colors based on current theme
  Color get primaryIconColor => AppIcons.primaryIconColor;
  Color get secondaryIconColor => AppIcons.secondaryIconColor;
  Color get errorIconColor => AppIcons.errorIconColor;
  Color get successIconColor => AppIcons.successIconColor;
  Color get warningIconColor => AppIcons.warningIconColor;
  Color get disabledIconColor => AppIcons.disabledIconColor;
}
