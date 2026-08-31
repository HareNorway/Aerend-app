# Launch Screen Assets (Reen)

Native cold-start shows **gradient only** (`LaunchBackground.imageset`).
`LaunchImage` is intentionally transparent — the REEN logo + entrance animation
run in Flutter (`lib/screens/common/splash/splash.dart`) so they match the web
portal splash (pop in, no sheen; merge exit unchanged).

iOS caches launch screens aggressively — delete the app and reinstall after
changing these assets.
