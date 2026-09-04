cask "ultracmd" do
  version "1.0.0"
  sha256 "64c9fcb3165f60799203d9a17e799d1a57caf18898f9af65d396c399a21c795f"

  url "https://github.com/Ryz3nPlayZ/ultracmd/releases/download/v#{version}/UltraCMD.dmg"
  name "UltraCMD"
  desc "Native macOS command launcher & AI workspace"
  homepage "https://github.com/Ryz3nPlayZ/ultracmd"

  depends_on macos: :ventura
  depends_on arch: :arm64

  livecheck do
    url "https://github.com/Ryz3nPlayZ/ultracmd/releases"
    strategy :github_latest
  end


  # Not notarized (no Apple Developer Program yet): Homebrew always
  # quarantines cask downloads on modern versions and Gatekeeper blocks the
  # first launch with "Apple could not verify…". Clearing the flag here makes
  # the same explicit trust decision the curl installer documents. Delete
  # this block once builds are Developer ID signed + notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/UltraCMD.app"]
  end

  app "UltraCMD.app"

  zap trash: [
    "~/Library/Application Support/ultracmd",
    "~/Library/Preferences/com.ultracmd.app.plist",
    "~/Library/Caches/com.ultracmd.app",
  ]
end
