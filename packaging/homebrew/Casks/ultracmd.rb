cask "ultracmd" do
  version "0.1.0"
  sha256 "267b35b6095aecc2bdfc76436aeacc2c39123e6ffcace1435ceb196bb4192e25"

  url "https://github.com/Ryz3nPlayZ/ultracmd/releases/download/v#{version}/UltraCMD-#{version}.dmg"
  name "UltraCMD"
  desc "Native macOS launcher: apps, clipboard, snippets, windows, Raycast extensions"
  homepage "https://github.com/Ryz3nPlayZ/ultracmd"

  livecheck do
    url "https://github.com/Ryz3nPlayZ/ultracmd/releases"
    strategy :github_latest
  end

  # The app installs its own updates, so brew must not report it outdated or roll it back.
  auto_updates true
  depends_on arch: :arm64
  # macOS 26 is the only release the app builds for or runs on.
  depends_on macos: :tahoe

  app "UltraCMD.app"

  # Homebrew quarantines each download and --no-quarantine is gone; unnotarized, Gatekeeper blocks.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/UltraCMD.app"],
                          writable_paths: ["UltraCMD.app"], writable_base: :appdir
  end

  zap trash: [
    "~/Library/Application Support/com.ultracmd.app",
    "~/Library/Caches/com.ultracmd.app",
    "~/Library/Preferences/com.ultracmd.app.plist",
  ]
end
