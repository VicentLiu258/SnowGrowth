# Snow Growth Deep Link

## App entry URLs

Use the HTTPS URL in H5 pages and WhatsApp messages/cards:

```text
https://www.snowgrowth.com/open/ic
```

The custom-scheme fallback is useful for native integrations and local tests:

```text
snowgrowth://open/ic
```

Both URLs open a blank transition page in the app, request
`GET https://www.snowgrowth.com/index/jump/search?keyword=ic`, and open the
returned website URL in the WebView.

The app also accepts the HTTPS form
`https://www.snowgrowth.com/open?keyword=ic` and the equivalent custom-scheme
form.

## Android App Links server file

Upload `assetlinks.json.example` as:

```text
https://www.snowgrowth.com/.well-known/assetlinks.json
```

Replace `REPLACE_WITH_RELEASE_CERT_SHA256` with the SHA-256 fingerprint of the
certificate used to sign the production APK/AAB. If the bare domain is also
used, serve the same file from `https://snowgrowth.com/.well-known/`.

## iOS Universal Links server file

Rename `apple-app-site-association.example` to
`apple-app-site-association`, replace `TEAM_ID` with the Apple Developer Team
ID, and serve it without a file extension at both:

```text
https://www.snowgrowth.com/.well-known/apple-app-site-association
https://snowgrowth.com/.well-known/apple-app-site-association
```

The response must be served over HTTPS as `application/json` (or without a
content type that causes a download), with no redirect.

## H5 / WhatsApp

```html
<a href="https://www.snowgrowth.com/open/ic">
  Open Snow Growth verification
</a>
```

Use the same HTTPS URL as the WhatsApp card's button/action URL. The card's
preview title, image, and description are controlled by the web server's Open
Graph metadata for `/open/ic`; the mobile app only handles the click.
