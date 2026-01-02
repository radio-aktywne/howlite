---
slug: /usage
title: Usage
---

## iCalendar

The calendar is available in the [`iCalendar`](https://icalendar.org) format.

For example, you can use [`curl`](https://curl.se) to download the calendar data:

```sh
curl --user user:password http://localhost:10520/user/calendar
```

## CalDAV

You can use any [`CalDAV`](https://devguide.calconnect.org/CalDAV) client
to interact with the server.
Note that not all `CalDAV` features are supported.

For example, you can even use [`curl`](https://curl.se)
to add an event to the calendar:

```sh
curl \
    --user user:password \
    --request PUT \
    --header 'Content-Type: text/calendar' \
    --data 'BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20121212T121212Z
DTEND:20121213T000000Z
SUMMARY:The End of the World
END:VEVENT
END:VCALENDAR' \
    http://localhost:10520/user/calendar
```

## Web UI

You can access the web UI by going to the root URL in your browser.
