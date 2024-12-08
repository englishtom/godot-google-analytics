# Google Analytics 4 Plugin for Godot 4.x

A plugin that enables Google Analytics 4 tracking in Godot games. This plugin supports both page views and custom events with session tracking.

## Setup

1. Enable the plugin in your Godot project:

   - Copy the `addons/google_analytics` folder to your project
   - Go to Project → Project Settings → Plugins
   - Enable the "Google Analytics" plugin

#### HTML5/Web Builds

For HTML5/Web exports, you'll need to add the GA4 tracking code to your HTML template, this can either be done by adding the tag to the Head Include or by supplying a custom HTML file in the export options.

In the snippet below we disable the default page view tracking that G4A does. If you want to allow G4A to handle page views normally then you can remove the `send_page_view` line.

1. Add the GA4 tracking code to your HTML template:

   ```html
   <!-- Google tag (gtag.js) -->
   <script
     async
     src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"
   ></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag() {
       dataLayer.push(arguments);
     }
     gtag("js", new Date());
     gtag("config", "G-XXXXXXXXXX", {
       send_page_view: false,
       allow_google_signals: false,
       allow_ad_personalization_signals: false,
     });
   </script>
   ```

2. Replace `G-XXXXXXXXXX` with your measurement ID
3. The plugin will automatically use gtag.js when running in a web context

#### Desktop/Mobile Builds

For desktop and mobile builds you'll need to configure the plugin with your Google Analytics credentials.

1. Configure your Google Analytics credentials:
   - Go to Project → Project Settings → General
   - In the top right enable "Advanced Settings" with the toggle
   - Scroll down to "google_analytics" section
   - Fill in the following settings:
     - `measurement_id`: Your GA4 measurement ID (format: "G-XXXXXXXXXX")
     - `api_secret`: Your GA4 API secret (from GA4 Admin → Data Streams → Choose your stream → Measurement Protocol API secrets)

## Usage

### Tracking Page Views

When the game starts, the plugin will automatically track a 'Game Start' page view. You can also manually track page views to track when players enter different scenes or sections of your game:

```gdscript
# Track a simple page view
Analytics.track_page_view("Main Menu") # This will take the title and generate a location, in this case "app://game/main_menu"

# Track a page view with custom location
Analytics.track_page_view("Level 1", "app://game/levels/level_1") # This will use the provided location instead of generating one
```

### Tracking Custom Events

Custom events will be tracked with the current page context.

Track custom events using GA4's recommended event names and parameters:

```gdscript
# Track button clicks
Analytics.track_event("select_content", {
    "content_type": "button",
    "item_id": "start_game",
    "content_category": "main_menu"
})

# Track level completion
Analytics.track_event("level_complete", {
    "level_id": "1",
    "score": "1000",
    "time_spent": "120"
})

# Track item purchases
Analytics.track_event("purchase", {
    "currency": "gold",
    "value": "500",
    "items": "magic_sword"
})
```

## Features

- Automatic session tracking
- Event queuing with rate limiting
- Persistent client ID across game sessions
- Automatic page context for all events
- Support for GA4's recommended event names and parameters
- Error handling and debug logging

## Implementation Details

- Events are automatically queued and sent with a minimum delay between them
- Each event includes session information and current page context
- Client ID is generated once and stored persistently
- All numeric values are automatically converted to strings (GA4 requirement)
- Debug logging helps track event sending and any issues

## Best Practices

1. Use GA4's recommended event names when possible:

   - `select_content`
   - `level_complete`
   - `purchase`
   - `tutorial_begin`
   - `tutorial_complete`
   - etc.

2. Track meaningful game events:

   - Scene/level changes (using `page_view`)
   - Button clicks and UI interactions
   - Game progression events
   - Achievement unlocks
   - Resource gathering/spending
   - Player preferences

3. Include relevant parameters:
   - Always include meaningful context
   - Use consistent parameter names
   - Follow GA4's parameter naming conventions

## Debugging

The plugin includes detailed logging prefixed with "[GA]". To enable debug logs:

1. Run Godot with the `--verbose` flag, or
2. Set "Debug > Stdout > Verbose" in your Godot Editor Settings

When verbose logging is enabled, you'll see:

- Client initialization details
- Page view tracking information
- Event preparation and parameters
- HTTP request details and responses
- Success/failure status of each event

Error messages (prefixed with "[GA] Error:") are always shown regardless of verbose mode.

## Known Limitations

- Maximum of 25 custom parameters per event
- Parameter names must use snake_case
- Parameter values must be strings

## License

MIT License - Feel free to use in any project, commercial or otherwise.
