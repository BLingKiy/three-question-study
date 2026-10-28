## MODIFIED Requirements

### Requirement: Dark mode switching
The system SHALL allow users to switch between three color modes: follow system (跟随系统), light (浅色), and dark (深色). The selection SHALL be persisted in PreferencesService and applied globally via `ApplicationContext.setColorMode()`.

#### Scenario: Select dark mode
- **WHEN** user selects "深色" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_DARK)`, persists the mode value 0 to PreferencesService, and all pages immediately render with dark color scheme

#### Scenario: Select light mode
- **WHEN** user selects "浅色" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_LIGHT)`, persists the mode value 1 to PreferencesService, and all pages immediately render with light color scheme

#### Scenario: Select follow system
- **WHEN** user selects "跟随系统" in the color mode sheet
- **THEN** system calls `setColorMode(COLOR_MODE_NOT_SET)`, persists the mode value -1 to PreferencesService, and the app follows the system color mode

#### Scenario: Restore color mode on app launch
- **WHEN** the app starts (EntryAbility.onCreate)
- **THEN** system reads the saved color mode from PreferencesService and calls `setColorMode()` with the saved value

#### Scenario: Restore color mode on ProfilePage load
- **WHEN** user navigates to ProfilePage
- **THEN** system reads the saved color mode from PreferencesService, updates the colorModeIndex state, and calls `setColorMode()` with the saved value

### Requirement: Semantic color resources for dark mode
The system SHALL define all UI colors as semantic color resources in both base and dark resource directories, so that switching color mode automatically updates all colors.

#### Scenario: Color resources in base directory
- **WHEN** the app is in light mode
- **THEN** all `$r('app.color.xxx')` references resolve to light-mode colors from the base resource directory

#### Scenario: Color resources in dark directory
- **WHEN** the app is in dark mode
- **THEN** all `$r('app.color.xxx')` references resolve to dark-mode colors from the dark resource directory

#### Scenario: No hardcoded colors in page files
- **WHEN** a page renders in dark mode
- **THEN** all background colors, text colors, and fill colors that differ between light and dark mode use `$r('app.color.xxx')` resource references instead of hardcoded hex values