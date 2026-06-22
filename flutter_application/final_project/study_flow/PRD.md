Product Requirements Document: AI Plan Interface Revamp
1. Overview
The objective is to redesign the "AI Plan" tab (currently displaying a basic "Study Flow" list) into a chronological timeline view. This update will group tasks and events by date, introduce detailed colored block components, and add sub-pages for completed tasks and an AI Chat assistant.

2. UI & Layout Specifications (Flutter)
2.1. Main View: The Timeline (AI Plan Tab)

Structure: A vertically scrollable list grouped by Date. Recommended implementation uses a CustomScrollView with SliverList or a sticky header package (e.g., sliver_sticky_header) for the date dividers.

Date Headers: Bold, distinct text (e.g., "Tue 23", "Mon, 29 Jun") acting as headers for the blocks below them.

Global Add Button: A Floating Action Button (FAB) or an inline IconButton (+) placed at the top right of the view or next to specific date headers to add new blocks.

2.2. Task/Event Blocks (Cards)

Styling: Rounded Container or Card widgets with distinct background colors (e.g., yellow for deadlines, red for events, blue for general tasks) to match the target design.

Content Layout:

Title: Bold, primary text (e.g., "Final Project Submission").

Time: Secondary text displayed beneath or next to the title (e.g., "23:59" or "10:30–11:00").

Description: An expandable section or subtitle text (truncated to 1-2 lines with an overflow ellipsis).

Icons & Actions (UI):

Edit Button: A standard edit icon (e.g., Icons.edit or Icons.more_vert opening a bottom sheet).

Delete Button: A standard trash icon (e.g., Icons.delete_outline) or implemented via Dismissible (swipe-to-delete).

Checklist (Checkbox): A circular or standard Flutter Checkbox located on the leading or trailing edge of the block.

2.3. Top Navigation Bar (Sub-pages)

Placement: An AppBar that only appears when navigating deeper into the "AI Plan" stack (it should not override the global BottomNavigationBar).

Behavior: Features a standard back button (Icons.arrow_back) and a title matching the sub-page.

3. Functional Requirements
3.1. Data & Sorting Logic

Sorting: All blocks must be strictly sorted chronologically by Date, followed by Time.

Data Model: The core object must contain the following attributes:

Date (DateTime or formatted String)

Time (TimeOfDay or formatted String)

Title (String)

Description (String)

isCompleted (Boolean, default: false)

3.2. Block Interactions

Checklist Action: Tapping the checkbox sets isCompleted = true.

Routing on Check: Once checked, the block must be immediately removed from the main Timeline View and transferred to the "Marked as done" state. A SnackBar can be optionally shown to allow for an undo action.

Edit: Tapping the Edit button opens a modal or new screen pre-filled with the block's current attributes, allowing the user to update and save changes.

Delete: Tapping the Delete button prompts a confirmation dialog, then permanently removes the block from the state/database.

3.3. Sub-page: "Marked as Done"

Access: Reached via a button or menu in the main AI Plan view.

Content: Displays a list of all blocks where isCompleted == true.

UI: Utilizes the sub-page top AppBar. Blocks here should allow the user to uncheck them (returning them to the main timeline) or permanently delete them.

3.4. Sub-page: "AI Chat"

Access: Reached via a distinct button/icon in the main AI Plan view (e.g., an AI sparkle icon in the header or a secondary FAB).

Content: Currently an empty Scaffold.

UI: Utilizes the sub-page top AppBar titled "AI Chat".

4. Technical Implementation Notes
Routing Strategy: To ensure the sub-page AppBars only appear within the AI Plan tab without losing the global BottomNavigationBar, use a Nested Navigator for the AI Plan tab, or push the sub-pages standardly if hiding the bottom bar is preferred during deep focus tasks.

State Management: Ensure that checking a block triggers a state rebuild so the item smoothly transitions out of the active list and into the completed list (e.g., using Provider, Riverpod, or Bloc).

Styling Consistency: Migrate away from the current ListTile with borders (Image 1) to tight, borderless Container widgets with padding and dynamic BoxDecoration colors (Image 2). Ensure proper contrast for text overlaying colored blocks.