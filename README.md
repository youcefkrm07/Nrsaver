# flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Online Save

- Tap the cloud button in the home screen to push all stored clients to an online endpoint.
- By default the app posts to [JSONPlaceholder](https://jsonplaceholder.typicode.com/posts); provide a real API by passing `--dart-define=REMOTE_SAVE_ENDPOINT=<url>` at build time.
- The button is disabled while an upload is in progress or when you have not entered any clients yet.
- A floating snackbar confirms the result and shows the HTTP status returned by the remote service.
