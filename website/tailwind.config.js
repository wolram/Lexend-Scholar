/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./*.html",
    "./_partials/*.html",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "primary":                    "#137fec",
        "on-primary-fixed-variant":   "#0b5ed7",
        "primary-fixed":              "#dbeafe",
        "error":                      "#ef4444",
        "on-tertiary-container":      "#312e81",
        "on-tertiary":                "#ffffff",
        "secondary-fixed-dim":        "#617589",
        "inverse-primary":            "#a8c8ff",
        "surface-bright":             "#ffffff",
        "on-tertiary-fixed":          "#312e81",
        "secondary-container":        "#e5e7eb",
        "on-surface-variant":         "#617589",
        "surface":                    "#ffffff",
        "inverse-surface":            "#1a2634",
        "primary-container":          "#dbeafe",
        "error-container":            "#fee2e2",
        "surface-container":          "#f1f3fd",
        "on-secondary-fixed":         "#111418",
        "tertiary-container":         "#e0e7ff",
        "on-background":              "#111418",
        "surface-tint":               "#137fec",
        "primary-fixed-dim":          "#137fec",
        "on-tertiary-fixed-variant":  "#4338ca",
        "tertiary-fixed":             "#e0e7ff",
        "surface-variant":            "#f1f3fd",
        "on-error":                   "#ffffff",
        "tertiary-fixed-dim":         "#4f46e5",
        "surface-container-lowest":   "#ffffff",
        "secondary":                  "#617589",
        "surface-container-highest":  "#dbeafe",
        "tertiary":                   "#4f46e5",
        "surface-container-high":     "#e5e7eb",
        "on-secondary":               "#ffffff",
        "surface-container-low":      "#f6f7f8",
        "on-error-container":         "#991b1b",
        "outline":                    "#e5e7eb",
        "background":                 "#f6f7f8",
        "secondary-fixed":            "#e5e7eb",
        "surface-dim":                "#f6f7f8",
        "on-surface":                 "#111418",
        "on-primary-fixed":           "#001b3c",
        "on-primary-container":       "#0b5ed7",
        "on-secondary-container":     "#111418",
        "on-secondary-fixed-variant": "#374151",
        "inverse-on-surface":         "#f6f7f8",
        "outline-variant":            "#374151",
        "on-primary":                 "#ffffff"
      },
      borderRadius: {
        DEFAULT: "0.25rem",
        lg:      "0.5rem",
        xl:      "0.75rem",
        full:    "9999px"
      },
      fontFamily: {
        headline: ["Lexend", "system-ui", "sans-serif"],
        body:     ["Lexend", "system-ui", "sans-serif"],
        label:    ["Lexend", "system-ui", "sans-serif"]
      }
    }
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
  ],
}
