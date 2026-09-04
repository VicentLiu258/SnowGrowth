# snow_growth

A new Flutter project.

## IC website lookup

On the Tools page, entering `ic` calls the configured lookup API. When the API
returns a valid HTTP(S) URL, the app opens it in an in-app WebView and stores
the URL locally. On a later launch, the app refreshes the URL through the same
API before opening the WebView; the last successful URL is used as a fallback
when the API is temporarily unavailable.

The production API is already configured. It can be overridden when running or
building the app if another environment is needed:

```shell
flutter run \
  --dart-define=TOOLS_LOOKUP_API_URL=https://www.snowgrowth.com/index/jump/search \
  --dart-define=TOOLS_LOOKUP_QUERY_PARAMETER=keyword
```

The request is `GET https://www.snowgrowth.com/index/jump/search?keyword=ic`.
The response may be a URL
string or a JSON object containing `url`, `websiteUrl`, `href`, `link`, or a
nested `data`/`result` object with one of those fields. An endpoint containing
`{query}` is also supported, for example `https://api.example.com/url/{query}`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
