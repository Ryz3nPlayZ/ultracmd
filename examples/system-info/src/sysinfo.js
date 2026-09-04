import { Detail, Action, ActionPanel, Icon } from "@raycast/api";
import { useBash } from "@raycast/utils";

const script =
  "echo \"**Host:** $(scutil --get ComputerName)\"; " +
  "echo \"**macOS:** $(sw_vers -productVersion) ($(uname -m)\"; " +
  "echo \"**Uptime:** $(uptime | sed 's/.*up //; s/,.*load.*//')\"; " +
  "echo \"**Disk:** $(df -h / | tail -1 | awk '{print $3 \" used of \" $2}')\"; " +
  "echo \"**Battery:** $(pmset -g batt | grep -o '[0-9]*%' | head -1)\"";

export default function Command() {
  const result = useBash(script, { timeout: 5000 });

  if (result.isLoading) {
    return Detail({ markdown: "Collecting system info…" });
  }
  if (result.error) {
    return Detail({ markdown: "### Error\n\n```\n" + String(result.error) + "\n```" });
  }
  return Detail({
    markdown: "# System\n\n" + result.data.stdout,
    actions: ActionPanel({}, [
      Action({
        title: "Copy Report",
        icon: Icon.Clipboard,
        onPerform: function () {
          const { Clipboard } = require("@raycast/api");
          return Clipboard.write({ text: result.data.stdout });
        },
      }),
    ]),
  });
}
