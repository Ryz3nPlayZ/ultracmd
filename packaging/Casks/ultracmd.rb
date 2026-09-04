cask "ultracmd" do
  version "1.0.0"
  sha256 "64c9fcb3165f60799203d9a17e799d1a57caf18898f9af65d396c399a21c795f"

  url "https://github.com/Ryz3nPlayZ/ultracmd/releases/download/v#{version}/UltraCMD.dmg"
  name "UltraCMD"
  desc "Native macOS command launcher & AI workspace"
  homepage "https://github.com/Ryz3nPlayZ/ultracmd"

  depends_on macos: :ventura
  depends_on arch: :arm64

  app "UltraCMD.app"

  zap trash: [
    "~/Library/Application Support/ultracmd",
    "~/Library/Preferences/com.ultracmd.app.plist",
    "~/Library/Caches/com.ultracmd.app",
  ]
end
