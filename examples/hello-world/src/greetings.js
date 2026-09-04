import { List, Action, ActionPanel, Icon, showToast, Toast, showHUD, environment } from "@raycast/api";
import { useEffect, useState } from "react";

export default function Command() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    showToast({ style: Toast.Style.Success, title: "Hello from " + environment.extensionName });
  }, []);

  const people = ["World", "Raycast User", "UltraCMD User", "macOS"];

  return List(
    {
      searchBarPlaceholder: "Greet someone…",
      onSearchTextChange: function (text) {
        setCount(text.length);
      },
    },
    people.map(function (name, i) {
      return List.Item({
        key: name,
        id: name,
        title: "Hello, " + name + "!",
        subtitle: "Typed " + count + " characters so far",
        icon: Icon.Sparkles,
        accessories: [{ text: "#" + (i + 1) }],
        actions: ActionPanel({}, [
          Action({
            title: "Say Hi on Screen",
            icon: Icon.Megaphone,
            onPerform: function () {
              showHUD("👋 Hi, " + name + "!");
            },
          }),
          Action({
            title: "Copy Greeting",
            icon: Icon.Clipboard,
            shortcut: "cmd+c",
            onPerform: function () {
              // Clipboard API
              return import_promo(name);
            },
          }),
        ]),
      });
    })
  );
}

function import_promo(name) {
  const api = require("@raycast/api");
  return api.Clipboard.write({ text: "Hello, " + name + "!" }).then(function () {
    showToast({ style: Toast.Style.Success, title: "Copied greeting for " + name });
  });
}
