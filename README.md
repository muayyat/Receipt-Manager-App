# Receipt Manager

**Description:**
Receipt Manager is a Flutter application designed to help users scan, manage, and analyze their receipts efficiently. The app integrates Firebase for user authentication and data storage, providing a seamless experience for tracking expenses.

## Features

- **Receipt Scanning**: Users can scan receipts using the device camera and extract relevant data using an integrated Receipt API, allowing for quick data entry.

- **Expense Management**: The app allows users to categorize their expenses based on the extracted data, making it easier to track spending habits.

- **Data Visualization**: Users can visualize their expenses through interactive pie charts and graphs, helping them understand their financial situation at a glance.

- **Budget Setting**: Users can set and manage budgets for different expense categories, with alerts for budget limits to promote better financial management.

- **Custom Categories**: The app supports custom expense categories, enabling users to tailor their tracking to their specific needs.

- **Data Export**: Users can export their receipt data to CSV format for easy sharing and analysis outside of the app.(In progress)

- **Offline Functionality**: The app supports offline mode, allowing users to access their receipts and data even without an internet connection.(In progress)

- **User Notifications**: The app provides notifications for budget alerts and other important updates to keep users informed about their finances.(In progress)

## Platforms

- Android
- iOS

## Getting Started

To get a copy of the project up and running on your local machine, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/jingjingyang0803/Receipt-Manager-App.git
   ```
2. Navigate to the Project Directory: Change into the project directory with the command:
   ```bash
    cd receipt_manager
   ```
3. Install Dependencies: Ensure all necessary dependencies are installed by running:
   ```bash
    flutter pub get
   ```
4. Run the Application: The application can be executed on an emulator/simulator or a physical device. Use the following command to launch the application:

   ```bash
   flutter run
   ```

   **For Android**:

   Ensure you have an Android emulator running or a physical Android device connected.
   You can connect a physical device via USB debugging or enable Wireless debugging:

   **For iOS**:

   Make sure you have an iOS simulator running or a physical iOS device connected.
   For physical devices, ensure that the device is set up for development by trusting your computer.

   Flutter will automatically detect the connected devices and launch the app accordingly.

## Dependencies

- **flutter**: Core SDK for building the app.

- **firebase_core**: Initializes Firebase services.

- **firebase_auth**: Manages user authentication.

- **cloud_firestore**: Stores and retrieves receipt data, supporting real-time syncing.

- **firebase_storage**: Handles storage for images and other files.

- **firebase_remote_config**: Enables dynamic fetching of remote configuration values.

- **cloud_functions**: Calls Firebase Cloud Functions to process OCR requests.

- **shared_preferences**: Stores local key-value pairs for user preferences and settings.

- **path_provider**: Locates directories on the device, useful for accessing file storage locations.

- **permission_handler**: Requests and manages permissions for accessing device features like the camera and gallery.

- **camera**: Provides direct access to the device's camera for capturing receipts.

- **image_picker**: Allows users to select images from the gallery or take new photos.

- **image**: Offers image manipulation capabilities such as resizing and formatting.

- **fl_chart**: Visualizes data with various types of customizable charts, ideal for spending analysis.

- **intl**: Handles internationalization and formats dates, times, and currencies.

- **http**: Facilitates HTTP requests for communication with external APIs and services.

- **emoji_picker_flutter**: Allows users to categorize expenses with emojis, adding an expressive layer to spending data.

- **logger**: Provides structured logging for debugging and tracking app activities.

## Currency API Integration

The application uses the [Open Exchange Rates API](https://openexchangerates.org/) to provide real-time currency data. Key functionalities include:

- **Currency Codes Fetching**: The app can fetch a list of available currency codes from the Open Exchange Rates API.

- **Conversion Rates Fetching**: The service retrieves current conversion rates, allowing users to view expenses in their preferred currency.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Thank you to the Flutter community and the contributors to the libraries used in this project.
