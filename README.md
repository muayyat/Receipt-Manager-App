# Receipt Manager

**Description:**
Receipt Manager is a Flutter application designed to help users scan, manage, and analyze their receipts efficiently. The app integrates Firebase for user authentication and data storage, providing a seamless experience for tracking expenses.

## Features

- **Receipt Scanning**: Users can scan receipts using the device camera and extract relevant data using an integrated Receipt API, allowing for quick data entry.

- **Expense Management**: The app allows users to categorize their expenses based on the extracted data, making it easier to track spending habits.

- **Data Visualization**: Users can visualize their expenses through interactive pie charts and graphs, helping them understand their financial situation at a glance.

- **Budget Setting**: Users can set and manage budgets for different expense categories, with alerts for budget limits to promote better financial management.(In progress)

- **Custom Categories**: The app supports custom expense categories, enabling users to tailor their tracking to their specific needs.(In progress)

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

- **firebase_core**: For initializing Firebase.
- **firebase_auth**: For user authentication.
- **cloud_firestore**: For storing and retrieving receipt data.
- **firebase_storage**: For storing images and files.
- **firebase_remote_config**: For fetching remote configuration settings.
- **flutter_tesseract_ocr**: For OCR capabilities to extract text from receipts.
- **fl_chart**: For charting and visualizations.

## Currency API Integration

The application uses the [Open Exchange Rates API](https://openexchangerates.org/) to provide real-time currency data. Key functionalities include:

- **Currency Codes Fetching**: The app can fetch a list of available currency codes from the Open Exchange Rates API.

- **Conversion Rates Fetching**: The service retrieves current conversion rates, allowing users to view expenses in their preferred currency.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Thank you to the Flutter community and the contributors to the libraries used in this project.
