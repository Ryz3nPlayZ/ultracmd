#!/bin/bash
# The test suite. There is no XCTest target: each harness compiles the shipped sources it guards,
# so a harness that stops compiling means a decision leaked out of a pure layer. See docs/testing.md.
#
# Never join a compile and its run with `&&`: `set -e` ignores a failure in a non-final AND-OR list
# member, which is how CI reported success over a harness that had not compiled since phase 10.

set -uo pipefail

# Absolute: the workers re-enter this script after the cd, where a relative $0 would not resolve.
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/.." || exit 1

BIN="${TMPDIR:-/tmp}/ultracmd-harness"
mkdir -p "$BIN"

# `--exec` is the worker half: xargs re-enters here once per queued harness.
if [ "${1:-}" = "--exec" ]; then
    shift
    name=$1 opt=$2
    shift 2
    : > "$BIN/$name.running"
    trap 'rm -f "$BIN/$name.running" "$BIN/$name.time"' EXIT
    fail() {
        printf '\033[31mFAIL\033[0m  %-25s %s\n' "$name" "$1"
        : > "$BIN/$name.failed"
        exit 0
    }
    TIMEFORMAT=%1R
    if ! compiled=$( { time swiftc -swift-version 6 "$opt" "$@" "Tests/$name.swift" -o "$BIN/$name" > "$BIN/$name.log" 2>&1; } 2>&1 ); then
        fail "did not compile"
    fi
    { time "$BIN/$name" > "$BIN/$name.log" 2>&1; } 2> "$BIN/$name.time" &
    pid=$!
    # macOS ships no `timeout`, so the worker polls; a wedged harness must fail, not stall the suite.
    ticks=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$ticks" -ge $((ULTRACMD_TEST_TIMEOUT * 5)) ]; then
            { pkill -KILL -P "$pid"; kill -KILL "$pid"; wait "$pid"; } 2>/dev/null
            printf '\n[run-tests] killed after %ss without finishing\n' "$ULTRACMD_TEST_TIMEOUT" >> "$BIN/$name.log"
            fail "timed out after ${ULTRACMD_TEST_TIMEOUT}s"
        fi
        ticks=$((ticks + 1))
        sleep 0.2
    done
    wait "$pid"
    status=$?
    took=$(< "$BIN/$name.time")
    if [ "$status" -gt 128 ]; then fail "crashed (signal $((status - 128))) after ${took}s"; fi
    if [ "$status" -ne 0 ]; then fail "assertion failed after ${took}s"; fi
    printf '\033[32mok\033[0m    %-25s %5ss  \033[2m(compile %ss)\033[0m\n' "$name" "$took" "$compiled"
    exit 0
fi

QUEUE="$BIN/queue"
: > "$QUEUE"
rm -f "$BIN"/*.failed "$BIN"/*.running

failed=()
ran=0
only="${1:-}"

# `--index` merges each harness's compile command into .compile instead of running anything.
# xcodebuild never compiles the harnesses, so without this nothing in Tests/ resolves in an editor.
# The source lists below are the only copy, which is why this lives here rather than in its own script.
emit_db=0
DB="${TMPDIR:-/tmp}/ultracmd-compile-db.json"
if [ "$only" = "--index" ]; then
    emit_db=1
    only=""
    printf '[' > "$DB"
fi

# run [slow] [-O] [index] <name> <source...> — queue the harness. `slow` dispatches it in the first
# wave; `index` claims editor flags for a harness that is compiled by hand rather than by the suite.
run() {
    local opt=-Onone pri=1 index_only=0
    while :; do
        case "$1" in
            slow)  pri=0; shift;;
            -O)    opt=-O; shift;;
            index) index_only=1; shift;;
            *)     break;;
        esac
    done
    local name=$1
    shift
    if [ -n "$only" ] && [ "$name" != "$only" ]; then return 0; fi
    if [ "$index_only" -eq 1 ] && [ "$emit_db" -eq 0 ]; then return 0; fi
    ran=$((ran + 1))

    # Absolute paths throughout: sourcekit-lsp resolves the command itself and does not apply
    # `directory` to relative arguments, so a relative path there silently yields no index.
    if [ "$emit_db" -eq 1 ]; then
        local sources=()
        for source in "$@" "Tests/$name.swift"; do sources+=("$PWD/$source"); done
        [ "$ran" -gt 1 ] && printf ',' >> "$DB"
        printf '{"directory":"%s","command":"swiftc -swift-version 6 -sdk %s' \
            "$PWD" "$(xcrun --show-sdk-path --sdk macosx)" >> "$DB"
        printf ' %s' "${sources[@]}" >> "$DB"
        # Claim every file under `Tests/`: the harness and any helper compiled beside it. A shipped
        # source stays unclaimed, because it would get this short command instead of the app's full
        # one and `.compile` is last-wins — but the app never compiles anything in `Tests/`.
        local claimed=""
        for source in "${sources[@]}"; do
            case "$source" in *"/Tests/"*) claimed="$claimed${claimed:+,}\"$source\"";; esac
        done
        printf '","files":[%s]}' "$claimed" >> "$DB"
        return 0
    fi

    # xargs splits the queue on whitespace, so no harness source path may contain a space.
    printf '%s %s %s %s\n' "$pri" "$name" "$opt" "$*" >> "$QUEUE"
}

L=UltraCMD/Features/Launcher/Model
run slow -O fuzz-test      $L/SearchRelevance.swift $L/ScriptRomanization.swift \
                           $L/EntryNaming.swift $L/LauncherOrder.swift
run slow -O corpus-test    $L/SearchRelevance.swift $L/ScriptRomanization.swift \
                           $L/EntryNaming.swift $L/LauncherOrder.swift \
                           $L/LauncherRankingStore.swift
run file-search-test       $L/SearchRelevance.swift \
                           UltraCMD/Features/FileSearch/Model/*.swift
run file-search-session-test UltraCMD/Platform/Signposts.swift \
                             $L/SearchRelevance.swift \
                             UltraCMD/Features/FileSearch/Model/*.swift \
                             UltraCMD/Features/FileSearch/Service/*.swift
run menu-search-test       $L/SearchRelevance.swift \
                           UltraCMD/Features/MenuSearch/Model/*.swift \
                           UltraCMD/Features/MenuSearch/Service/*.swift
run window-switch-test     $L/SearchRelevance.swift \
                           UltraCMD/Features/WindowSwitcher/Model/*.swift
run index file-search-performance UltraCMD/Platform/Signposts.swift \
                           $L/SearchRelevance.swift \
                           UltraCMD/Features/FileSearch/Model/*.swift \
                           UltraCMD/Features/FileSearch/Service/FileSearchService.swift
run ranking-test           $L/SearchRelevance.swift $L/LauncherRankingStore.swift
run scopes-test            $L/SearchScopes.swift
run quick-capture-test     UltraCMD/Features/QuickCapture/Model/QuickCaptureParser.swift \
                           $L/WebSearch.swift
run app-name-test          UltraCMD/Platform/AppDisplayName.swift \
                           UltraCMD/Platform/BundleLocalization.swift \
                           $L/SearchRelevance.swift
run favorites-test         $L/FavoriteSlots.swift
run apple-shortcut-test    UltraCMD/Features/AppleShortcuts/Model/*.swift
run calc-test              UltraCMD/Features/Calculator/Model/*.swift
run index calc-performance UltraCMD/Features/Calculator/Model/*.swift
run calendar-test          UltraCMD/Features/Calendar/Model/*.swift
run clipboard-test         UltraCMD/Features/Clipboard/Model/ClipboardStore.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFilter.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFileKind.swift \
                           UltraCMD/Features/Clipboard/Model/ColorValue.swift \
                           UltraCMD/Features/Clipboard/Model/ColorFormat.swift \
                           UltraCMD/Features/Clipboard/Model/ColorSpaces.swift
# `Q` is the URL detector a drag payload builds its link with, rather than a second one.
Q=UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift
run clipboard-search-test  UltraCMD/Features/Clipboard/Model/*.swift $Q
run clipboard-text-test    UltraCMD/Features/Clipboard/Model/*.swift $Q \
                           UltraCMD/Features/Clipboard/Service/ClipboardTextExtractor.swift \
                           UltraCMD/Features/Clipboard/Service/ClipboardTextIndexer.swift \
                           UltraCMD/Features/Clipboard/Service/ClipboardTextWorker.swift
run pasteboard-test        UltraCMD/Platform/PasteboardFiles.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardStore.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFilter.swift \
                           UltraCMD/Features/Clipboard/Model/ColorValue.swift \
                           UltraCMD/Features/Clipboard/Model/ColorFormat.swift \
                           UltraCMD/Features/Clipboard/Model/ColorSpaces.swift \
                           UltraCMD/Features/Clipboard/Service/ClipboardManager.swift \
                           UltraCMD/Features/Clipboard/Service/Paster.swift
run index clipboard-file-performance \
                           UltraCMD/Platform/PasteboardFiles.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardStore.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFilter.swift \
                           UltraCMD/Features/Clipboard/Model/ColorValue.swift \
                           UltraCMD/Features/Clipboard/Model/ColorFormat.swift \
                           UltraCMD/Features/Clipboard/Model/ColorSpaces.swift \
                           UltraCMD/Features/Clipboard/Service/ClipboardManager.swift
run emoji-test             UltraCMD/Features/Emoji/Model/EmojiCatalog.swift \
                           UltraCMD/Features/Emoji/Model/EmojiGridGeometry.swift \
                           UltraCMD/Features/Emoji/Model/EmojiData.generated.swift
run emoji-search-test      UltraCMD/Features/Emoji/Model/EmojiCatalog.swift \
                           UltraCMD/Features/Emoji/Model/EmojiData.generated.swift \
                           UltraCMD/Features/Emoji/Service/EmojiIndex.swift \
                           UltraCMD/Features/Emoji/Service/FrequentEmojiStore.swift \
                           UltraCMD/Features/Emoji/Service/PinnedEmojiStore.swift \
                           UltraCMD/Features/Launcher/Model/SearchRelevance.swift \
                           UltraCMD/Platform/AppPaths.swift UltraCMD/Platform/Memo.swift
run index emoji-search-performance \
                           UltraCMD/Features/Emoji/Model/EmojiCatalog.swift \
                           UltraCMD/Features/Emoji/Model/EmojiData.generated.swift \
                           UltraCMD/Features/Emoji/Service/EmojiIndex.swift \
                           UltraCMD/Features/Emoji/Service/FrequentEmojiStore.swift \
                           UltraCMD/Features/Launcher/Model/SearchRelevance.swift \
                           UltraCMD/Platform/AppPaths.swift UltraCMD/Platform/Memo.swift
run palette-selection-test UltraCMD/Features/PaletteRowIndex.swift \
                           UltraCMD/Features/Emoji/Model/EmojiGridGeometry.swift
run appearance-test        UltraCMD/Platform/Appearance.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/Settings/AppAppearance.swift
run interface-size-test    UltraCMD/Platform/Appearance.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/Settings/InterfaceSize.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionFormMetrics.swift
run palette-placement-test UltraCMD/Platform/Appearance.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/Settings/InterfaceSize.swift \
                           UltraCMD/Palette/PalettePlacement.swift
run scroll-reveal-test     UltraCMD/DesignSystem/Scrolling/SelectionReveal.swift
run redaction-test         UltraCMD/DesignSystem/RedactedPlaceholder.swift
run keyboard-focus-test    UltraCMD/DesignSystem/Interaction/KeyboardFocus.swift
run ai-instructions-test   UltraCMD/Features/AI/Model/AIInstructions.swift \
                           UltraCMD/Features/AI/Model/AIPreamble.swift
run hover-arming-test      UltraCMD/Palette/HoverArming.swift \
                           UltraCMD/Palette/PaletteState.swift \
                           UltraCMD/Palette/PaletteMode.swift \
                           UltraCMD/Features/Emoji/Model/EmojiCatalog.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardStore.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFilter.swift \
                           UltraCMD/Features/FileSearch/Model/FileSearchFilter.swift \
                           UltraCMD/Features/Clipboard/Model/ColorValue.swift \
                           UltraCMD/Features/Clipboard/Model/ColorFormat.swift \
                           UltraCMD/Features/Clipboard/Model/ColorSpaces.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift
run palette-escape-test    UltraCMD/Palette/PaletteMode.swift \
                           UltraCMD/Palette/PaletteEscapeAction.swift \
                           UltraCMD/Palette/CommandEscapeTap.swift \
                           UltraCMD/Features/Settings/EscapeKeyBehavior.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift
run palette-navigation-test UltraCMD/Palette/PaletteState.swift \
                           UltraCMD/Palette/PaletteMode.swift \
                           UltraCMD/Palette/HoverArming.swift \
                           UltraCMD/Features/Emoji/Model/EmojiCatalog.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardStore.swift \
                           UltraCMD/Features/Clipboard/Model/ClipboardFilter.swift \
                           UltraCMD/Features/FileSearch/Model/FileSearchFilter.swift \
                           UltraCMD/Features/Clipboard/Model/ColorValue.swift \
                           UltraCMD/Features/Clipboard/Model/ColorFormat.swift \
                           UltraCMD/Features/Clipboard/Model/ColorSpaces.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift
run palette-filter-test    UltraCMD/Palette/PaletteMode.swift \
                           UltraCMD/Palette/PaletteFilterAction.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift
run palette-shortcut-test  UltraCMD/Palette/PaletteShortcut.swift
run palette-tab-test       UltraCMD/Palette/PaletteMode.swift \
                           UltraCMD/Palette/PaletteTabAction.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift
run fallback-test          UltraCMD/Features/Launcher/Model/Fallback.swift \
                           UltraCMD/Features/Launcher/Model/CommandID.swift \
                           UltraCMD/Features/HotKeys/Model/HotKeyAction.swift \
                           UltraCMD/Features/QuickActions/Model/QuickAction.swift \
                           UltraCMD/Features/QuickActions/Model/BuiltInQuickAction.swift \
                           UltraCMD/Features/QuickActions/Model/CustomQuickAction.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/SystemActions/Model/SystemAction.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowCommand.swift
run hotkey-test            UltraCMD/Features/HotKeys/Model/DoubleTapModifier.swift \
                           UltraCMD/Features/HotKeys/Model/DoubleTapDetector.swift \
                           UltraCMD/Features/HotKeys/Model/HyperKey.swift \
                           UltraCMD/Platform/ASCIIKeyboardLayout.swift \
                           UltraCMD/Features/HotKeys/Service/KeyShortcut.swift \
                           UltraCMD/Features/HotKeys/Model/HotKeyAction.swift \
                           UltraCMD/Features/QuickActions/Model/QuickAction.swift \
                           UltraCMD/Features/QuickActions/Model/BuiltInQuickAction.swift \
                           UltraCMD/Features/QuickActions/Model/CustomQuickAction.swift \
                           UltraCMD/Features/Launcher/Model/CommandID.swift \
                           UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/SystemActions/Model/SystemAction.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowCommand.swift
run callout-test           UltraCMD/Platform/Appearance.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/HotKeys/UI/CalloutPlacement.swift
run icon-cache-test        UltraCMD/Platform/Appearance.swift \
                           UltraCMD/Platform/Images/IconCache.swift
run entry-icon-test        UltraCMD/Platform/Appearance.swift \
                           UltraCMD/Platform/Images/IconCache.swift \
                           UltraCMD/Platform/Images/FileIconStamp.swift
run ext-icon-test          UltraCMD/Platform/Appearance.swift \
                           UltraCMD/Platform/Images/IconCache.swift \
                           UltraCMD/Platform/Compression/Zlib.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionBootConfig.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionLaunchType.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionManifest.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionRefreshPolicy.swift \
                           UltraCMD/Features/Extensions/Model/ExtensionRefreshState.swift \
                           UltraCMD/Features/Extensions/Model/RenderNode.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionCatalog.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionFetcher.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionNodeShims.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionOAuthKeychain.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionOAuthSession.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionRuntime.swift \
                           UltraCMD/Features/Extensions/Service/ExtensionIconCache.swift \
                           UltraCMD/Features/Extensions/UI/ExtensionAnimatedImage.swift \
                           UltraCMD/Features/Extensions/UI/ExtensionImage.swift
run system-action-test     UltraCMD/Features/SystemActions/Model/SystemAction.swift
run volume-test            UltraCMD/Features/SystemActions/Model/VolumeLevel.swift
run window-command-test    UltraCMD/Features/WindowManagement/Model/WindowCommand.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowCycle.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowPlacementEngine.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowActionMemory.swift
run space-gesture-test     UltraCMD/Features/WindowManagement/Model/WindowCommand.swift \
                           UltraCMD/Features/WindowManagement/Model/SpaceGesture.swift
run window-layout-test     UltraCMD/Features/WindowManagement/Model/WindowCommand.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowCycle.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowPlacementEngine.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayoutAnchor.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayoutDisplay.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayout.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayoutGeometry.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayoutPlan.swift \
                           UltraCMD/Features/WindowManagement/Model/WindowLayoutStore.swift \
                           UltraCMD/Features/WindowManagement/Model/CustomWindowSize.swift \
                           UltraCMD/Features/WindowManagement/Model/CustomWindowSizeStore.swift
run custom-command-test    UltraCMD/Platform/PseudoTerminal.swift \
                           UltraCMD/Features/CustomCommands/Model/CustomCommand.swift \
                           UltraCMD/Features/CustomCommands/Model/RaycastScriptImport.swift \
                           UltraCMD/Features/CustomCommands/Service/ShellCommandRunner.swift \
                           UltraCMD/Features/CustomCommands/Service/CustomCommandArgumentSession.swift
run uninstall-test         UltraCMD/Features/Uninstall/Model/UninstallTarget.swift \
                           UltraCMD/Features/Uninstall/Model/UninstallSearchRoot.swift \
                           UltraCMD/Features/Uninstall/Model/UninstallRules.swift \
                           UltraCMD/Features/Uninstall/Model/UninstallProtection.swift \
                           UltraCMD/Features/Uninstall/Model/UninstallPlan.swift
run quicklink-test         UltraCMD/Features/Quicklinks/Model/Quicklink.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkDestination.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkStore.swift \
                           UltraCMD/Features/Quicklinks/Model/QuicklinkArchive.swift \
                           UltraCMD/Features/Quicklinks/Model/RaycastQuicklinkImport.swift
run slow snippets-test     UltraCMD/Platform/NotificationToken.swift \
                           UltraCMD/Platform/HealthTicker.swift \
                           UltraCMD/Platform/AccessibilityText.swift \
                           UltraCMD/Features/Snippets/Model/*.swift \
                           UltraCMD/Features/Snippets/Service/*.swift \
                           UltraCMD/Features/TextInjection/Service/*.swift
run notes-test             UltraCMD/Platform/Signposts.swift \
                           $L/SearchRelevance.swift \
                           UltraCMD/Features/Notes/Model/*.swift \
                           UltraCMD/Features/Notes/Service/*.swift
run notes-editor-test      UltraCMD/Platform/Signposts.swift \
                           UltraCMD/Platform/Appearance.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           UltraCMD/Features/TextInjection/Service/InjectableTextView.swift \
                           UltraCMD/Features/Notes/Model/NoteDocument.swift \
                           UltraCMD/Features/Notes/Model/NoteTask.swift \
                           UltraCMD/Features/Notes/UI/NoteTextView.swift \
                           UltraCMD/Features/Notes/UI/NoteEditorView.swift
run slow -O raycast-test   UltraCMD/Features/Backup/Model/RaycastImportError.swift \
                           UltraCMD/Features/Backup/Service/RaycastDecoder.swift \
                           UltraCMD/Features/Backup/Service/Scrypt.swift \
                           UltraCMD/Platform/Compression/Zlib.swift
run settings-backup-test   UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/Backup/Model/SettingsBackupCoverage.swift
run backup-archive-test    UltraCMD/Platform/AppPaths.swift \
                           UltraCMD/Features/Backup/Model/BackupArchive.swift \
                           UltraCMD/Features/Backup/Model/BackupBundle.swift \
                           UltraCMD/Features/Backup/Model/BackupCategory.swift \
                           UltraCMD/Features/Backup/Model/BackupClipboardItem.swift \
                           UltraCMD/Features/Backup/Model/BackupManifest.swift \
                           UltraCMD/Features/Backup/Service/BackupStaging.swift
E=UltraCMD/Features/Extensions
run symbols-test           $E/Service/SymbolCatalog.swift
run ext-cleanup-test       $E/Service/ExtensionCleanup.swift \
                           $E/Service/ExtensionCatalog.swift \
                           $E/Model/ExtensionManifest.swift \
                           $E/Model/ExtensionLaunchType.swift \
                           $E/Model/ExtensionRefreshPolicy.swift \
                           $E/Model/ExtensionRefreshState.swift
run ext-refresh-test       $E/Model/ExtensionManifest.swift \
                           $E/Model/ExtensionLaunchType.swift \
                           $E/Model/ExtensionRefreshPolicy.swift \
                           $E/Model/ExtensionRefreshState.swift
run ext-metadata-test      $E/Model/ExtensionCommandMetadata.swift \
                           $E/Service/ExtensionCommandMetadataStore.swift
run ext-store-test         $E/Model/ExtensionRegistry.swift \
                           $E/Model/ExtensionPackageManager.swift \
                           $E/Model/ExtensionStoreResponse.swift
run ext-form-test          $E/Model/ExtensionFormMetrics.swift \
                           $E/Model/ExtensionFormField.swift \
                           $E/UI/ExtensionFormKey.swift \
                           $E/Model/ExtensionDateExpression.swift \
                           $E/UI/ExtensionListKey.swift \
                           Tests/ext-list-key-test.swift
run ext-accessory-test     $E/Model/RenderNode.swift \
                           $E/Model/ExtensionPickerItem.swift \
                           $E/Model/ExtensionSearchAccessory.swift \
                           $E/Service/ExtensionStorage.swift
run slow ext-test          -parse-as-library \
                           UltraCMD/Platform/Appearance.swift \
                           UltraCMD/Platform/Images/IconCache.swift \
                           UltraCMD/DesignSystem/Theme.swift \
                           UltraCMD/DesignSystem/InterfaceMetrics.swift \
                           $E/Model/ExtensionBootConfig.swift \
                           $E/Model/ExtensionDeepLink.swift \
                           $E/Model/ExtensionLaunchType.swift \
                           $E/Model/ExtensionFormField.swift \
                           $E/Model/ExtensionGridLayout.swift \
                           $E/Model/ExtensionManifest.swift \
                           $E/Model/ExtensionRefreshPolicy.swift \
                           $E/Model/ExtensionRefreshState.swift \
                           $E/Model/RenderNode.swift \
                           $E/Model/ExtensionPickerItem.swift \
                           $E/Model/ExtensionSearchAccessory.swift \
                           $E/Service/ExtensionCatalog.swift \
                           $E/Service/ExtensionFetcher.swift \
                           $E/Service/ExtensionIconCache.swift \
                           $E/Service/ExtensionNodeShims.swift \
                           $E/Service/ExtensionOAuthKeychain.swift \
                           $E/Service/ExtensionOAuthSession.swift \
                           $E/Service/ExtensionRuntime.swift \
                           $E/UI/ExtensionAnimatedImage.swift \
                           $E/UI/ExtensionImage.swift \
                           $E/UI/ExtensionScreen.swift \
                           $L/SearchRelevance.swift \
                           UltraCMD/Platform/Compression/Zlib.swift
run settings-history-test  UltraCMD/Features/Settings/SettingsTab.swift \
                           UltraCMD/Features/Settings/SettingsHistory.swift \
                           UltraCMD/Features/Settings/SettingsAnchor.swift \
                           UltraCMD/Features/Settings/SettingsNavigationState.swift \
                           UltraCMD/Features/Settings/SettingsSearchCatalog.swift \
                           $L/SearchRelevance.swift
run updates-test           UltraCMD/Features/Updates/Model/*.swift \
                           UltraCMD/Features/Updates/Service/BundleSignature.swift
run support-test           UltraCMD/Features/Support/Model/*.swift
run ai-provider-test       UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/AI/Model/*.swift \
                           UltraCMD/Features/AI/Settings/AISettingsStore.swift
run ai-chat-test           UltraCMD/Features/AI/Model/AIRequest.swift \
                           UltraCMD/Features/AI/Model/AIAttachmentPolicy.swift \
                           UltraCMD/Features/AI/Model/AIRetention.swift \
                           UltraCMD/Features/AI/Model/AITool.swift \
                           UltraCMD/Features/AI/Model/JSONValue.swift \
                           UltraCMD/Features/AI/Model/ChatMessage.swift \
                           UltraCMD/Features/AI/Model/ChatSession.swift \
                           UltraCMD/Features/AI/Model/MarkdownBlock.swift \
                           UltraCMD/Features/AI/Service/AIProvider.swift \
                           UltraCMD/Features/AI/Service/ChatHistoryStore.swift \
                           UltraCMD/Features/AI/Service/AIToolLoopProvider.swift \
                           UltraCMD/Features/AI/UI/AIChatState.swift
run mcp-test               UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/AI/Model/AIConnection.swift \
                           UltraCMD/Features/AI/Model/AppleIntelligence.swift \
                           UltraCMD/Features/AI/Model/AITool.swift \
                           UltraCMD/Features/AI/Model/JSONValue.swift \
                           UltraCMD/Features/MCP/Model/*.swift \
                           UltraCMD/Features/MCP/Settings/MCPSettingsStore.swift
run -O text-diff-test      UltraCMD/Features/QuickActions/Model/TextDiffEngine.swift
run index text-diff-performance UltraCMD/Features/QuickActions/Model/TextDiffEngine.swift
run quick-action-test      UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/AI/Model/AIConnection.swift \
                           UltraCMD/Features/AI/Model/AppleIntelligence.swift \
                           UltraCMD/Features/AI/Model/ChatGPTSubscription.swift \
                           UltraCMD/Features/AI/Model/InstalledAI.swift \
                           UltraCMD/Features/QuickActions/Model/*.swift \
                           UltraCMD/Features/QuickActions/Settings/QuickActionSettingsStore.swift
run apple-intelligence-test UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/AI/Model/*.swift \
                           UltraCMD/Features/AI/Service/AIProvider.swift \
                           UltraCMD/Features/AI/Service/AppleIntelligenceProvider.swift
run slow mcp-stdio-test    UltraCMD/Platform/ExecutableLocator.swift \
                           UltraCMD/Platform/KeychainSecretStore.swift \
                           UltraCMD/Features/Settings/AppSettingsKey.swift \
                           UltraCMD/Features/AI/Model/AIConnection.swift \
                           UltraCMD/Features/AI/Model/AppleIntelligence.swift \
                           UltraCMD/Features/AI/Model/AITool.swift \
                           UltraCMD/Features/AI/Model/AIStreamDecoder.swift \
                           UltraCMD/Features/AI/Model/AIRequest.swift \
                           UltraCMD/Features/AI/Model/JSONValue.swift \
                           UltraCMD/Features/MCP/Model/*.swift \
                           UltraCMD/Features/MCP/Service/*.swift
run slow codex-turn-test   UltraCMD/Platform/AppPaths.swift \
                           UltraCMD/Features/AI/Model/*.swift \
                           UltraCMD/Features/AI/Service/AIProvider.swift \
                           UltraCMD/Features/AI/Service/ChatGPTSubscriptionManager.swift \
                           UltraCMD/Features/AI/Service/CodexAppServerClient.swift \
                           UltraCMD/Platform/ExecutableLocator.swift \
                           UltraCMD/Features/AI/Service/CodexTurnRunner.swift
run installed-ai-test     UltraCMD/Features/AI/Model/*.swift \
                          UltraCMD/Features/AI/Service/AIProvider.swift \
                          UltraCMD/Platform/AppPaths.swift \
                          UltraCMD/Platform/ExecutableLocator.swift \
                          UltraCMD/Features/AI/Service/InstalledCLIProvider.swift \
                          UltraCMD/Features/AI/Service/InstalledAIManager.swift

if [ "$emit_db" -eq 1 ]; then
    printf ']\n' >> "$DB"
    [ -f .compile ] || echo '[]' > .compile
    node -e '
const fs = require("node:fs");
const [comp, db] = process.argv.slice(1);
const existing = JSON.parse(fs.readFileSync(comp, "utf8"));
const harnesses = JSON.parse(fs.readFileSync(db, "utf8"));
const kept = existing.filter((e) => !(e.files || []).some((f) => f.includes("/Tests/")));
fs.writeFileSync(comp, JSON.stringify([...kept, ...harnesses], null, 1));
console.log(harnesses.length + " harness entries indexed into .compile");
' .compile "$DB"
    exit 0
fi

if [ "$ran" -eq 0 ]; then
    echo "No harness named '$only'." >&2
    exit 2
fi

# `sort -s` is stable, so the slow harnesses lead and everything else keeps its declaration order.
JOBS="${ULTRACMD_TEST_JOBS:-$(sysctl -n hw.ncpu)}"
export ULTRACMD_TEST_TIMEOUT="${ULTRACMD_TEST_TIMEOUT:-300}"
started=$SECONDS

# Numbers each result, and names what is still running whenever the output goes quiet.
report() {
    local finished=0 line asked running file
    while :; do
        asked=$SECONDS
        if IFS= read -r -t 15 line; then
            case "$line" in "dispatch "*) return "${line#dispatch }";; esac
            finished=$((finished + 1))
            printf '[%*d/%d] %s\n' "${#ran}" "$finished" "$ran" "$line"
            continue
        fi
        # Bash 3.2 returns the same status for a timeout and EOF; only EOF comes back at once.
        if [ $((SECONDS - asked)) -lt 10 ]; then return 1; fi
        running=""
        for file in "$BIN"/*.running; do
            [ -e "$file" ] && running="$running $(basename "$file" .running)"
        done
        printf '        \033[2mstill running after %ds:%s\033[0m\n' $((SECONDS - started)) "$running"
    done
}

# Without this the suite reports "all passed" whenever dispatch itself dies and no harness ran.
if ! { sort -s -k1,1n "$QUEUE" | cut -d' ' -f2- | xargs -P "$JOBS" -L1 "$SELF" --exec; echo "dispatch $?"; } | report; then
    echo "harness dispatch failed; no result below can be trusted" >&2
    exit 1
fi
elapsed=$((SECONDS - started))

# A compiler diagnostic is far longer than PIPE_BUF, so the workers log it and it is replayed here.
while read -r _ name _; do
    if [ -f "$BIN/$name.failed" ]; then failed+=("$name"); fi
done < "$QUEUE"

if [ ${#failed[@]} -gt 0 ]; then
    for name in "${failed[@]}"; do
        printf '\n\033[31m--- %s ---\033[0m\n' "$name"
        cat "$BIN/$name.log"
    done
    printf '\n\033[31mFAILED\033[0m  %d of %d harness(es) failed in %ds: %s\n' \
        "${#failed[@]}" "$ran" "$elapsed" "${failed[*]}" >&2
    exit 1
fi
printf '\n\033[32mPASSED\033[0m  All %d harness(es) passed in %ds.\n' "$ran" "$elapsed"
