# SheMade - Women's E-commerce Platform

A modern Flutter-based e-commerce application designed specifically for women entrepreneurs and buyers. SheMade provides a comprehensive platform for sellers to showcase their products and for buyers to discover unique items.

## 🌟 Features

### For Sellers
- **Product Management**: Add, edit, and manage product listings
- **Order Management**: Track and manage incoming orders
- **Dashboard**: Comprehensive seller dashboard with analytics
- **Product Descriptions**: Rich product description pages
- **Inventory Management**: Keep track of product stock

### For Buyers
- **Product Discovery**: Browse through various product categories
- **Order Tracking**: Track your order status
- **User Authentication**: Secure login and registration
- **Product Listings**: View detailed product information

### General Features
- **Firebase Integration**: Real-time data synchronization
- **Google Sign-In**: Seamless authentication
- **Push Notifications**: Stay updated with order status
- **Image Upload**: Product image management
- **Responsive Design**: Works across different screen sizes

## 🛠️ Tech Stack

- **Framework**: Flutter 3.6.0
- **Language**: Dart
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Messaging
- **State Management**: Provider
- **UI Components**: Material Design
- **Additional Libraries**:
  - Google Fonts
  - Flutter SVG
  - Image Picker
  - Cached Network Image
  - Shared Preferences

## 📱 Screenshots

[Add your app screenshots here]

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.6.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/shemadev2.git
   cd shemadev2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Messaging
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place these files in their respective platform directories

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── seller/              # Seller-specific screens
│       ├── loginScreen.dart
│       ├── signUpScreen.dart
│       ├── sellerHome.dart
│       ├── buyerHome.dart
│       ├── add_product_screen.dart
│       ├── edit_product_screen.dart
│       ├── sellerOrders.dart
│       ├── buyerOrdersPage.dart
│       └── ...
├── widgets/                 # Reusable UI components
├── services/               # Business logic and API calls
├── models/                 # Data models
├── provider/              # State management
└── notifications/         # Push notification handling

assets/
├── logo2.png             # App logo
├── splash.png            # Splash screen
├── login.jpg             # Login background
├── signup.jpg            # Signup background
└── ob1.jpg, ob2.png, ob3.jpg  # Onboarding images
```

## 🔧 Configuration

### Firebase Configuration

1. **Authentication**
   - Enable Email/Password authentication
   - Enable Google Sign-In
   - Configure OAuth consent screen

2. **Firestore Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Add your security rules here
     }
   }
   ```

3. **Storage Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       // Add your storage rules here
     }
   }
   ```

## 🎨 UI/UX Features

- **Color Scheme**: 
  - Primary: Light Pink (#FFB6C1)
  - Secondary: Gold (#FFD700)
  - Background: Lavender Blush (#FFF0F5)

- **Design Elements**:
  - Material Design components
  - Smooth page indicators
  - Custom splash screen
  - Onboarding flow
  - Responsive layouts

## 📋 Features in Detail

### Authentication System
- Email/password registration and login
- Google Sign-In integration
- Password reset functionality
- User role management (Buyer/Seller)

### Product Management
- Add new products with images
- Edit existing product details
- Product categorization
- Inventory tracking
- Rich product descriptions

### Order System
- Order creation and tracking
- Order status updates
- Order history for both buyers and sellers
- Real-time order notifications

### User Experience
- Onboarding flow for new users
- Intuitive navigation
- Loading states and error handling
- Offline data persistence

## 🔒 Security Features

- Firebase Authentication
- Secure data transmission
- Input validation
- Role-based access control
- Secure file uploads

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (planned)
- ✅ Desktop (planned)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: [Your Name]
- **Design**: [Designer Name]
- **Project Manager**: [PM Name]

## 📞 Support

For support, email support@shemade.com or create an issue in this repository.

## 🔄 Version History

- **v1.0.0** - Initial release with basic e-commerce functionality
- **v1.1.0** - Added push notifications and improved UI
- **v1.2.0** - Enhanced product management features

## 🚧 Roadmap

- [ ] Multi-language support (English/Tamil)
- [ ] Advanced analytics dashboard
- [ ] Payment gateway integration
- [ ] Chat system between buyers and sellers
- [ ] Advanced search and filtering
- [ ] Social media integration
- [ ] Review and rating system

---

**Made with ❤️ for women entrepreneurs**
