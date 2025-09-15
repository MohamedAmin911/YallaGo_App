![1](assets/images/logo5.png)

YallaGo - Full-Stack Ride-Hailing Application
YallaGo is a complete, real-time ride-hailing ecosystem built from the ground up, inspired by modern platforms like Uber and Careem. This project is not just a UI clone; it's a fully functional, multi-part system that demonstrates a deep understanding of full-stack mobile application architecture.

The ecosystem consists of three distinct parts:

📱 A Flutter App for Customers: For requesting and tracking rides.

🚗 A Flutter App for Drivers: For accepting and managing trips.

🖥️ A Web-Based Admin Dashboard: For user verification and platform monitoring.

🎥 Driver Authentication
![2](logo/DRIVER AUTH.mp4)

🎥 Customer Authentication
![3](logo/CUS AUTH.mp4)

🎥 Driver app features
![4](logo/DRIVER FEA.mp4)

🎥 Customer app features
![5](logo/CUS FEATURES.mp4)

🎥 Live Trip booking
![6](logo/B96A3592-8E36-4ee3-9438-ADCBC52E3482_video.mp4)

---
✨ Features
This project is packed with features designed to create a complete and realistic user experience.

👤 Customer App

[x] Secure OTP Authentication: Passwordless sign-up and login using Firebase Auth.

[x] Real-Time Map: Live tracking of nearby available drivers on Google Maps.

[x] Destination Search: Autocomplete search for destinations.

[x] Upfront Fare Estimation: Real-time calculation of trip distance, duration, and estimated cost using OSRM.

[x] Real-Time Trip Progress: Live updates on the driver's location and status (Accepted, Arrived, In Progress).

[x] Secure Payments: Save and manage credit/debit cards securely with Stripe.

[x] Ride History & Details: View a list of past trips with detailed information.

[x] Driver Rating: Rate the driver at the end of a trip.

[x] In-App Chat: Real-time chat with the driver during an active trip.

[x] Local Notifications: Receive a notification when the driver arrives at the pickup location.


🚗 Driver App

[x] Multi-Step Onboarding: A complete sign-up flow including profile info, vehicle details, and document uploads.

[x] Online/Offline Status: Drivers can toggle their availability to receive ride requests.

[x] Real-Time Ride Requests: Receive and review new trip requests from nearby customers instantly.

[x] Trip Management: Accept, decline, start, and end trips.

[x] Live Navigation to Customer: See the route to the customer's pickup location on the map.

[x] Live Navigation to Destination: See the route to the customer's destination after starting the trip.

[x] Earnings & Payouts: Securely set up payout information with Stripe Connect and track earnings in a real-time balance.

[x] Ride History & Details: View a list of completed trips with earnings and customer ratings.

[x] In-App Chat: Real-time chat with the customer.

[x] Local Notifications: Receive a notification when a trip is completed and paid for.


---
🛠️ Tech Stack & Architecture
This project was built with a clean, scalable architecture (MVVM using the BLoC/Cubit pattern) to separate UI from business logic.

Frontend: Flutter & Dart

State Management: BLoC / Cubit

Backend & Database: Firebase (Auth, Firestore Real-time Updates, Cloud Storage)

Payments (Customer): Stripe SDK

Payouts (Driver): Stripe Connect

Mapping: Google Maps Platform

Routing & ETA: Open Source Routing Machine (OSRM) API

Image Handling: Cloudinary API

Notifications: Flutter Local Notifications

Local Storage: SharedPreferences
---


🚀 How to Run
To set up and run this project locally, you will need to:

Clone the repository:

```
git clone <https://gitlab.com/mohamed-amin-dev/YallaGo_App>
cd YallaGo
```


Set up Firebase:

Create a new Firebase project.

Add an Android and an iOS app to your project.

Download the google-services.json file and place it in the android/app directory.

Set up Firestore and enable Authentication (Phone Number).

Add your app's SHA-1 and SHA-256 keys to your Firebase project settings.

Set up API Keys:

Create a .env file in the root of the project.

Add your keys for Google Maps, Stripe, and Cloudinary to this file.

Run the app:

```
flutter pub get
flutter run
```

---

## ⚖️ License & Usage

This project is licensed under a custom portfolio license. Please see the `LICENSE.md` file for full details.

-   **You ARE allowed to:** View, download, and run the code for personal, educational, and evaluation purposes.
-   **You are NOT allowed to:** Use this code for any commercial purpose, distribute it, or sell it.

This repository is intended to be a showcase of my skills and should be treated as such.

---

👤 Author
Mohamed Amin

LinkedIn: [linkedin.com/in/mohamed-amin-002849189/](url)

Email: [mohamed.amin911911@gmail.com](url)
