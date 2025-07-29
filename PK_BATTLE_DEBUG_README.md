# PK Battle Debug System

## Overview

This system provides comprehensive debugging information for PK (Player vs Player) battles in the live streaming app. When a user accepts a PK battle request, a dedicated debug screen is automatically displayed showing all API calls, headers, responses, and any errors that occur during the PK battle creation process.

## Features

### 🎯 **Automatic Debug Screen**
- Automatically triggered when a user accepts a PK battle request
- Shows real-time API call information
- Displays complete request/response details
- Color-coded status indicators

### 📊 **Detailed API Information**
- **API Call Details**: URL, method, headers, request body
- **Response Information**: Status codes, response bodies, results
- **Error Handling**: Clear error messages with context
- **Timestamps**: Precise timing of each API call

### 🎨 **User-Friendly Interface**
- Dark theme optimized for debugging
- Expandable API call cards
- Color-coded success/error indicators
- Raw JSON data for developers
- Responsive design

## How It Works

### 1. **PK Battle Acceptance Flow**
```
User accepts PK request → API calls are made → Debug screen shows results
```

### 2. **API Calls Tracked**
1. **Get User ID by Username (Local)** - Fetches local user's ID
2. **Get User ID by Username (Remote)** - Fetches remote user's ID  
3. **Start PK Battle** - Creates the PK battle with both user IDs

### 3. **Debug Screen Components**
- **Header Section**: Overall status and timestamp
- **API Calls Section**: Detailed breakdown of each API call
- **Final Response Section**: Success/error summary
- **Raw Data Section**: Complete JSON data for developers

## Files Structure

```
lib/
├── screens/live/
│   ├── pk_battle_debug_screen.dart    # Main debug screen
│   └── pk_battle_debug_test.dart      # Test screen for development
├── pk_widgets/
│   └── events.dart                    # PK events handling (updated)
└── services/
    └── api_service.dart               # API service methods
```

## Usage

### For End Users
The debug screen appears automatically when accepting a PK battle request. No additional action required.

### For Developers
To test the debug screen manually:

```dart
// Navigate to the test screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PKBattleDebugTest()),
);
```

### For Testing
Use the `PKBattleDebugTest` screen to test both success and error scenarios:

1. **Success Scenario**: Shows successful API calls with PK battle ID
2. **Error Scenario**: Shows failed API calls with error details

## API Call Details

### Sample API Call Structure
```json
{
  "api_name": "Get User ID by Username (Local)",
  "url": "https://api.example.com/user-id-by-username?username=john_doe",
  "method": "GET",
  "request_headers": "Authorization: Bearer token123, Content-Type: application/json",
  "request_body": null,
  "response_status": 200,
  "response_body": "{\"id\": 12345}",
  "result": 12345,
  "error": null
}
```

### Color Coding
- 🟢 **Green**: Successful API calls (200 status)
- 🔴 **Red**: Failed API calls (4xx/5xx status)
- 🟠 **Orange**: Pending API calls
- 🔵 **Blue**: URLs and general info
- 🟡 **Yellow**: Results and timestamps
- 🟣 **Purple**: Request bodies

## Error Handling

The system captures and displays:
- Network errors
- API response errors
- Missing user data
- Invalid request parameters
- Server errors

## Benefits

1. **Real-time Debugging**: See exactly what happens during PK battle creation
2. **Complete Visibility**: All API calls, headers, and responses are logged
3. **Error Identification**: Quickly identify and fix issues
4. **Developer Friendly**: Raw JSON data for advanced debugging
5. **User Experience**: Clear feedback on PK battle status

## Future Enhancements

- Export debug logs to file
- Share debug information with support team
- Historical debug data storage
- Performance metrics tracking
- Custom debug filters

## Troubleshooting

### Debug Screen Not Appearing
1. Check if context is available in PK events
2. Verify navigation is working properly
3. Ensure API call details are being captured

### Missing API Information
1. Verify API service methods are being called
2. Check network connectivity
3. Ensure proper error handling in API calls

### Performance Issues
1. Debug screen is optimized for large API responses
2. Uses lazy loading for expandable sections
3. Minimal memory footprint

---

**Note**: This debug system is designed for development and testing purposes. Consider disabling or limiting access in production builds. 