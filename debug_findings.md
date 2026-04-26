# Debug Findings: Cards Not Visible on Table After Drop

## Issue Description
When dragging and dropping cards onto the table area, the cards are successfully removed from the player's hand and added to the `gameState.tableCards` array. However, the dropped cards do not appear visually on the table.

## Root Cause Analysis

### 1. Card Removal and Addition Process
- In `GameBoard:mousereleased()`, when a card is dropped in the table area (y >= 0 and y <= TABLE_AREA_HEIGHT), `Trail.execute()` is called
- `Trail.execute()` successfully:
  - Removes the card from `state.playerHand`
  - Adds the card to `state.tableCards` (initializing the array if needed)

### 2. Drawing Logic Gap
- The `GameBoard:draw()` method only calls three functions:
  - `drawTableArea()` - draws the green background
  - `drawSquare()` - draws the draggable square
  - `drawHandArea()` - draws the remaining cards in the player's hand
- **Missing**: No code to draw the `tableCards`

### 3. Card Drawing Capability
- Cards have a `draw(x, y, width, height)` method implemented in `Card.lua`
- The method renders the card with suit, rank, and visual styling

## Technical Details
- `GameState` initializes `tableCards = {}` in the `start()` method
- `Trail.execute()` correctly manipulates `state.tableCards`
- No errors in the drag-and-drop logic; hand rebuilding works properly
- The visual rendering pipeline stops at the hand; table cards are not included

## Recommended Fix
Add a `drawTableCards()` function to `GameBoard.lua` and call it from `draw()`. This function should iterate through `gameState.tableCards` and call each card's `draw()` method with appropriate positioning logic.</content>
<parameter name="filePath">debug_findings.md