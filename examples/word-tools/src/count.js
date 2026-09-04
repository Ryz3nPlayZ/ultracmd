import { Form, ActionPanel, Action, showToast, Toast, Clipboard } from "@raycast/api";
import { useState } from "react";

export default function Command() {
  const state = useState("");
  const text = state[0];
  const setText = state[1];

  const words = text.trim() ? text.trim().split(/\s+/).length : 0;
  const characters = text.length;

  return Form(
    {
      actions: ActionPanel({}, [
        Action.SubmitForm({
          title: "Copy Stats",
          onPerform: function (values) {
            const t = values.text || "";
            const stats = "Words: " + (t.trim() ? t.trim().split(/\s+/).length : 0) +
              " · Characters: " + t.length;
            return Clipboard.write({ text: stats }).then(function () {
              showToast({ style: Toast.Style.Success, title: "Copied", message: stats });
            });
          },
        }),
      ]),
    },
    [
      Form.TextArea({
        id: "text",
        title: "Text",
        placeholder: "Paste or type text to analyze…",
        info: words + " words · " + characters + " characters",
      }),
      Form.Description({ id: "summary", title: "Live Stats", text: words + " words · " + characters + " characters" }),
      Form.Separator({ id: "sep" }),
      Form.Checkbox({ id: "includeChars", title: "Include character count", defaultValue: true }),
    ]
  );
}
