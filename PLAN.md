# PLAN.md

Implementation roadmap for A Grand Tour.

## Overview

Building a multi-tenant trip planning application in phases:
- **Phase 1**: Foundation (DB, basic UI, map integration)
- **Phase 2**: Core Features (tours, trips, routes, POIs)
- **Phase 3**: Content (documents, countries, reference data)
- **Phase 4**: Polish (seeding, import/export, UX refinements)
- **Phase 5**: Users & Sharing (auth, collaboration, public tours)

Each phase consists of small iterations. Each iteration follows the development workflow in CLAUDE.md.

---

## Phase 1: Foundation

### 1.1 Project Setup
- [x] Create Phoenix app with LiveView
- [x] Create development database
- [x] Verify tests pass
- [x] Write CLAUDE.md
- [x] Write PLAN.md

### 1.2 Add PostGIS Support
- [ ] Add `geo_postgis` dependency
- [ ] Configure Ecto for PostGIS types
- [ ] Create migration to enable PostGIS extension
- [ ] Write test for spatial queries

### 1.3 Basic Layout
- [ ] Create app layout with split view (map | content)
- [ ] Add top navigation bar with placeholder tabs
- [ ] Add resizable divider between map and content
- [ ] Mobile responsive: stack layout

### 1.4 Mapbox Integration
- [ ] Add Mapbox GL JS to assets
- [ ] Create MapHook for LiveView integration
- [ ] Display globe with basic styling
- [ ] Test: map loads and renders

### 1.5 LiveView ↔ Map Communication
- [ ] Implement pushEvent from map to LiveView (click events)
- [ ] Implement handleEvent from LiveView to map (fly_to, update_data)
- [ ] Test bidirectional communication

---

## Phase 2: Core Features

### 2.1 Tours Context
- [ ] Create Tour schema (name, subtitle, is_public)
- [ ] Create Tour context with CRUD operations
- [ ] Tour list LiveView
- [ ] Tour creation form
- [ ] Tour detail/edit view
- [ ] Tests for Tour context

### 2.2 Trips Context
- [ ] Create Trip schema (belongs_to Tour, position, dates)
- [ ] Trip CRUD within a Tour
- [ ] Trip reordering (drag-and-drop or up/down)
- [ ] Trip list in sidebar
- [ ] Trip detail view
- [ ] Tests for Trip context

### 2.3 Routes - Basic
- [ ] Create Route schema with segments (JSONB)
- [ ] Waypoints as PostGIS MultiPoint
- [ ] Simplified path as PostGIS LineString
- [ ] Route display on map
- [ ] Tests for Route schema

### 2.4 Routes - Editing
- [ ] Add waypoint by clicking map
- [ ] Remove waypoint
- [ ] Reorder waypoints (drag)
- [ ] Segment types (drive, ferry, flight, etc.)
- [ ] Tests for route editing

### 2.5 Routes - Generation
- [ ] Oban job for route generation
- [ ] Integration with OSRM or Mapbox Directions API
- [ ] Generate simplified path from full path
- [ ] Calculate distance and duration
- [ ] Tests for route generation

### 2.6 POIs - Global
- [ ] Create POI schema with PostGIS Point
- [ ] POI categories and subcategories
- [ ] POI display on map (markers)
- [ ] POI popup/detail view
- [ ] POI search/filter
- [ ] Tests for POI context

### 2.7 POIs - Per-Tour Customization
- [ ] TourPOI schema for overrides
- [ ] Add custom POI to tour
- [ ] Edit global POI (creates override)
- [ ] Hide global POI from tour
- [ ] User rating for POIs
- [ ] Tests for POI overrides

### 2.8 Itinerary
- [ ] Create Itinerary and ItineraryDay schemas
- [ ] Day-by-day view for a trip
- [ ] Add stops to a day
- [ ] Set accommodation
- [ ] Notes per day
- [ ] Tests for Itinerary

---

## Phase 3: Content

### 3.1 Countries - Schema
- [ ] Create Country schema with all properties
- [ ] Safety rating (1-5, color-coded)
- [ ] Visa info (JSONB by passport country)
- [ ] Driving side, currency, power, etc.
- [ ] Seed from reference data
- [ ] Tests for Country schema

### 3.2 Countries - UI
- [ ] Country list view
- [ ] Country detail view (renders as document)
- [ ] Country on map (highlight, click to view)
- [ ] Per-tour country overrides
- [ ] Tests for Country views

### 3.3 Documents - Basic
- [ ] Create Document schema
- [ ] Markdown storage and rendering
- [ ] Document list in tour
- [ ] Create/edit document
- [ ] Tests for Document context

### 3.4 Documents - Smart References
- [ ] Parse [[type:id|label]] syntax
- [ ] Render as clickable links
- [ ] Autocomplete UI when typing [[
- [ ] Click link → navigate + highlight on map
- [ ] Tests for reference parsing

### 3.5 Risk Regions
- [ ] Create RiskRegion schema with PostGIS Polygon
- [ ] Display on map with color coding
- [ ] Popup with reason
- [ ] Seed from reference data
- [ ] Tests for RiskRegion

### 3.6 Scenic Routes & Ferries
- [ ] Create ScenicRoute schema
- [ ] Create Ferry schema
- [ ] Display on map (different line styles)
- [ ] List views
- [ ] Seed from reference data
- [ ] Tests

---

## Phase 4: Polish

### 4.1 Seed Reference Data
- [ ] Script to import countries
- [ ] Script to import POIs with images
- [ ] Script to import scenic routes
- [ ] Script to import ferries
- [ ] Script to import risk regions
- [ ] Upload images to R2

### 4.2 Import/Export
- [ ] Export tour as GeoJSON
- [ ] Export trip route as GPX
- [ ] Import GeoJSON POIs
- [ ] Import waypoints from GPX/KML

### 4.3 Image Management
- [ ] R2 presigned URL generation
- [ ] Direct upload from browser
- [ ] Image display in POIs, scenic routes
- [ ] Cloudflare Images integration (thumbnails)

### 4.4 Timeline View
- [ ] Auto-generated timeline from trips
- [ ] Visual timeline component
- [ ] Click trip in timeline → show on map
- [ ] Statistics (total km, days, countries)

### 4.5 Tab Configuration
- [ ] User can add/remove/reorder tabs
- [ ] Default tabs: Overview, Timeline, Trips
- [ ] Custom tabs: Countries, POIs, Documents
- [ ] Persist tab configuration

### 4.6 Mobile UX
- [ ] Stacked layout on mobile
- [ ] Touch-friendly map controls
- [ ] Swipe between tabs
- [ ] Test on various screen sizes

---

## Phase 5: Users & Sharing

### 5.1 Authentication
- [ ] User schema with email/password
- [ ] Registration flow
- [ ] Login/logout
- [ ] Session management
- [ ] Tests for auth

### 5.2 Authorization
- [ ] Tour ownership
- [ ] Tour belongs to user
- [ ] Only owner can edit (for now)
- [ ] Tests for authorization

### 5.3 Public Tours
- [ ] Toggle tour public/private
- [ ] Public URL for tour (slug-based)
- [ ] Read-only view for public tours
- [ ] SEO metadata for public tours

### 5.4 Subscription (Placeholder)
- [ ] Subscription tier field on User
- [ ] Feature gates by tier
- [ ] Placeholder for payment integration

---

## Future (V2)

- [ ] Collaboration (invite collaborators, real-time editing)
- [ ] AI integration (document generation, POI research)
- [ ] Community features (fork tours, comments, POI ratings)
- [ ] iOS app
- [ ] Offline support (PWA)
- [ ] Budget tracking
- [ ] Checklist/todos per trip

---

## Current Status

**Phase 1.1 Complete** - Project created, basic setup done.

**Next:** Phase 1.2 - Add PostGIS support.
