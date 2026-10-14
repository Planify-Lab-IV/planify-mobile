---
name: figma-inspect-design
description: Inspects Figma frames, extracts layout specifications, spacing, typography, and color tokens, and compares them against Flutter implementation code. Use this skill when reviewing Figma design links or verifying UI fidelity.
---

# Skill: Inspect Figma Screens & Validate UI Implementation

## 1. When to Use This Skill
Apply this skill whenever:
- A Figma URL is provided (`https://www.figma.com/design/...`, `https://www.figma.com/file/...`, or a node ID link).
- Verifying if a student's Flutter UI matches the target Figma screen specifications.
- Extracting exact spacing, padding, typography scales, or color tokens from a design frame.

---

## 2. Figma Inspection & Review Workflow

### Step 1: Extract Frame Data via Figma MCP Server
- Query the Figma node using the MCP server.
- Extract key design properties:
  - **Layout & Structure:** Auto-Layout direction (Row/Column), padding, item spacing (gap), alignment.
  - **Colors & Tokens:** Background fill, primary accents, container fills (map to `Theme.of(context).colorScheme` or `AppColors`).
  - **Typography:** Font size, weight, line height, letter spacing (map to `Theme.of(context).textTheme`).
  - **Components & Assets:** Buttons, icons, card containers, dialogs.

### Step 2: Compare Design Specs Against Student Implementation
- Check if the student used appropriate design tokens (e.g., `AppSpacing.md` instead of hardcoded numbers).
- Verify widget choice matches design intent (e.g., using `ElevatedButton` for primary actions, custom floating bottom nav for root navigation).
- Ensure Material 3 rules from `flutter-apply-material3-guidelines` are respected.

### Step 3: Pedagogical Feedback Generation
- **Point out specific delta:** (e.g., *"In Figma, the padding between card items is 16dp (`AppSpacing.md`), but your code uses `EdgeInsets.all(8.0)`"*).
- **Enforce Anti-Magic Constraints:** Do NOT write the complete screen code to match Figma.
- Provide a minimal 5-10 line skeleton snippet as a hint if necessary.
- Ask a guided challenge question for the student to fix the discrepancy themselves.

---

## 3. Reference Mapping (Figma to Flutter M3)

| Figma Property | Flutter Theme / Design System Equivalent |
| :--- | :--- |
| **Primary Fill / Color** | `colorScheme.primary` or `AppColors.primary` |
| **Surface Fill / Container** | `colorScheme.surface` or `AppColors.surface` |
| **Error / Alert Fill** | `colorScheme.error` or `AppColors.error` |
| **Title / Header Text** | `textTheme.headlineSmall` / `textTheme.titleMedium` |
| **Body Text** | `textTheme.bodyMedium` / `textTheme.bodySmall` |
| **Item Spacing / Gap** | `SizedBox(height: AppSpacing.md)` or `AppSpacing.sm` |
