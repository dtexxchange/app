# Application Pagination & Infinite Scroll Architecture Guidelines

This document outlines the standard architecture and implementation patterns for pagination, search, and infinite scrolling across the backend service and Flutter mobile applications.

---

## 1. Backend API Pattern (Nest.js + Prisma)

### A. List Endpoints (`GET /resources`)
- **Query Parameters**:
  - `page` (number, default: `1`) - 1-indexed page number.
  - `limit` (number, default: `10`) - Page size (limit).
  - `search` (string, optional) - Case-insensitive term for server-side matching.
  - `status`/filters (string, optional) - Resource-specific state filters.
- **Database Pagination**:
  - Always use Prisma's `skip` and `take` operators:
    ```typescript
    take: limit,
    skip: (page - 1) * limit
    ```
  - Exclude large nested relation lists or arrays (such as full message records) to keep payloads lightweight.

### B. Nested Sub-resource Listings (`GET /resources/:id/sub-resources`)
- If a detail view contains a list that grows indefinitely (e.g., chat messages, audit logs, ledger entries):
  - Request the parent resource metadata via `GET /resources/:id` (excluding the nested list).
  - Retrieve the nested items from a dedicated paginated sub-resource route: `GET /resources/:id/sub-resources?page=1&limit=20`.

---

## 2. Client-side Scrolling Patterns (Flutter)

### A. Infinite Scroll Down (Standard Lists)
- **Scroll Controller**: Bound to the list's `ScrollController`.
- **Scroll Listener**:
  - Triggers data retrieval when scrolling approaches the bottom:
    ```dart
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      if (hasMore && !isLoadingMore && !isInitialLoading) {
        fetchNextPage();
      }
    }
    ```
- **State Management**:
  - Keep track of `int page = 1;`, `bool hasMore = true;`, and `bool isLoadingMore = false;`.
  - Append new records to the end of the display list.
  - Render a loader spinner row at the bottom of the list when `isLoadingMore` is true.
  - Pull-to-refresh triggers must reset `page` to `1` and overwrite the list.

### B. Infinite Scroll Up (Reversed Message / Chat Feeds)
- **Reversed Layout**: Set `reverse: true` inside the list view (e.g., `ListView.builder(reverse: true)`).
- **List Sorting**:
  - Store items in descending order (latest items at index 0, which renders at the bottom near the keyboard/input field).
- **Scroll Listener**:
  - In a reversed ListView, scrolling upwards to see older history increases `pixels` towards `maxScrollExtent`.
  - Listen for older history pagination near the top:
    ```dart
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      if (hasMore && !isLoadingMore) {
        fetchOlderPage();
      }
    }
    ```
- **Data Insertion**:
  - Append older fetched pages to the end of the item list (rendered at the top).
  - Insert new locally composed entries instantly at index 0 (rendered at the bottom) to avoid full view rebuilds.

---

## 3. Search & Tabs Filter Conventions

- **Server-side Execution**: Switch filter/search parameters server-side rather than doing local memory sorting to ensure unscrolled page results are matches.
- **Search Keystroke Debouncer**: Always run a short debounce delay (e.g. 500ms using a `Timer`) on search text fields to prevent API spamming:
  ```dart
  Timer? debounce;
  onChanged: (v) {
    if (debounce?.isActive ?? false) debounce.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () => runSearchQuery(v));
  }
  ```
- **Reset State**: Ensure tab switches or search parameter updates reset the target page parameter to `1` and clear existing lists before dispatching requests.
