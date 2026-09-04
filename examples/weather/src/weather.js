import { List, Detail, Action, ActionPanel, Icon } from "@raycast/api";
import { usePromise } from "@raycast/utils";
import { useState } from "react";

const CITIES = [
  { name: "San Francisco", lat: 37.77, lon: -122.42 },
  { name: "New York", lat: 40.71, lon: -74.01 },
  { name: "London", lat: 51.51, lon: -0.13 },
  { name: "Berlin", lat: 52.52, lon: 13.41 },
  { name: "Tokyo", lat: 35.68, lon: 139.69 },
  { name: "Sydney", lat: -33.87, lon: 151.21 },
];

function codeToEmoji(code) {
  if (code === 0) return "☀️";
  if (code <= 3) return "⛅️";
  if (code <= 48) return "🌫";
  if (code <= 57) return "🌦";
  if (code <= 67) return "🌧";
  if (code <= 77) return "🌨";
  if (code <= 82) return "🌧";
  if (code <= 86) return "❄️";
  return "⛈";
}

async function fetchWeather(city) {
  const url =
    "https://api.open-meteo.com/v1/forecast?latitude=" +
    city.lat + "&longitude=" + city.lon +
    "&current=temperature_2m,weather_code,wind_speed_10m";
  const res = await fetch(url);
  if (!res.ok) throw new Error("HTTP " + res.status);
  const data = await res.json();
  return data.current;
}

export default function Command() {
  const state = useState(CITIES[0]);
  const city = state[0];
  const setCity = state[1];
  const weather = usePromise(function () { return fetchWeather(city); }, [city]);

  const picker = List(
    { searchBarPlaceholder: "Pick a city… " },
    CITIES.map(function (c) {
      return List.Item({
        key: c.name,
        id: c.name,
        title: c.name,
        subtitle: c.lat + ", " + c.lon,
        icon: Icon.Globe,
        onClick: function () { setCity(c); },
      });
    })
  );

  if (weather.isLoading || !weather.data) {
    return List({ isLoading: true }, [
      List.Item({ id: "loading", title: "Loading " + city.name + "…", icon: Icon.Cloud }),
    ]);
  }

  const current = weather.data;
  const emoji = codeToEmoji(current.weather_code);

  return Detail({
    markdown:
      "# " + emoji + " " + city.name + "\n\n" +
      "**" + current.temperature_2m + "°C** · wind " + current.wind_speed_10m + " km/h\n\n" +
      "_(open-meteo, fetched live)_",
    actions: ActionPanel({}, [
      Action({
        title: "Refresh",
        icon: Icon.ArrowClockwise,
        onPerform: function () { weather.revalidate(); },
      }),
      Action({
        title: "Back to Cities",
        icon: Icon.ChevronLeft,
        onPerform: function () { setCity(CITIES[0]); },
      }),
    ]),
  });
}
