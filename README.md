# Lighthouse Mini Roadmap

## Vision

Lighthouse Mini is a minimal, private and text-only app for recording:

- good things that happened
- positive things coming soon
- daily habits

The app should always remain quick and uncomplicated:

> Open the app, write one sentence, press Enter and close it.

Lighthouse is designed to be local-first, distraction-free and usable without an account, subscription or internet connection.

---

## Product Principles

- Text only
- No photos, videos or attachments
- Minimal and calm interface
- Fast entry with as few clicks as possible
- Automatic saving
- User-owned data
- Local-first storage
- No advertising
- No mandatory account
- No social feed or public profile
- No judgemental scores
- AI remains optional and separate from the core app

Future `Ahead` entries are limited to one calendar month from the current date.

---

## Version 0.1 — Working Prototype

### Good Things

- [x] Monthly list view
- [x] One section for every day
- [x] Add multiple text entries per day
- [x] Save quickly with Enter
- [x] Edit existing entries
- [x] Delete entries
- [x] Highlight the current day
- [x] Mark past entries as `Good`
- [x] Mark future entries as `Ahead`
- [x] Limit Ahead entries to one calendar month
- [x] Show suggestions from recent and recurring entries
- [x] Store entries locally in IndexedDB

### Habit Tracker

- [x] Monthly habit grid
- [x] Add custom habits
- [x] Edit habits
- [x] Archive habits
- [x] Restore archived habits
- [x] Permanently delete habits
- [x] Mark and unmark individual days
- [x] Prevent future days from being marked
- [x] Show monthly completion totals
- [x] Store habit data locally in IndexedDB

### Interface

- [x] Desktop sidebar navigation
- [x] Mobile bottom navigation
- [x] Responsive layout
- [x] Lighthouse branding and logo
- [x] Local development in Chrome

---

## Version 0.2 — Data Safety

The next priority is protecting the user’s data.

- [ ] Export all data as a backup file
- [ ] Import an existing backup
- [ ] Add a backup format version
- [ ] Validate backup files before importing
- [ ] Show backup creation date and app version
- [ ] Warn before replacing existing data
- [ ] Create a safety backup before importing
- [ ] Add a reminder explaining that browser data can be deleted
