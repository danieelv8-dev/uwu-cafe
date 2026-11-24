# Live-Server Acceptance Checklist

Use a test database and at least two connected players.

## Startup

- [ ] Resource starts after all five required dependencies.
- [ ] No SQL or missing-item errors appear.
- [ ] The ingredient stash registers and opens.
- [ ] All target zones align with the installed MLO.

## Employee lifecycle

- [ ] Owner, manager and trainee permissions differ correctly.
- [ ] Clock-in/out works only at the duty point.
- [ ] AFK clock-out triggers after the configured period.
- [ ] Payroll deducts from the business and pays the employee.
- [ ] Payroll fails safely when the business lacks funds.
- [ ] Employee blips appear only while on duty.

## Inventory and crafting

- [ ] Every ingredient and product icon loads.
- [ ] Each station shows only its recipes.
- [ ] Missing ingredients prevent crafting.
- [ ] Cancelling crafting does not consume ingredients.
- [ ] Successful crafting consumes exact ingredients.
- [ ] Crafted items contain quality and freshness metadata.
- [ ] Broken equipment blocks production.
- [ ] Repair and upgrade costs come from the business account.

## Customer orders

- [ ] Terminal orders require proximity.
- [ ] Table orders save the correct table number.
- [ ] `/uwuorder` saves the customer's current delivery destination.
- [ ] Cash and bank payments reject insufficient funds.
- [ ] Customer cancellation refunds a pending order once.
- [ ] Register billing requires customer approval.
- [ ] Declined bills charge nothing.

## Kitchen and fulfillment

- [ ] Pending → accepted → preparing → ready transitions work.
- [ ] Marking ready requires and removes exact finished products.
- [ ] Ready orders preserve average quality metadata.
- [ ] Pickup transfers products and credits the business once.
- [ ] A full customer inventory blocks collection without losing the order.
- [ ] Table service requires both players near the table.
- [ ] Customer reconnects do not break table fulfillment.

## Delivery and catering

- [ ] Only one employee can claim a delivery.
- [ ] Completion requires the assigned employee, customer and saved location.
- [ ] Supply run costs are deducted before departure.
- [ ] Supply vehicle damage creates a penalty.
- [ ] Supply items reach the shared stash.
- [ ] Catering removes exact products and returns them if startup fails.
- [ ] Completed catering credits the business and employee bonus.
- [ ] `/uwucanceljob` cleans up the active job.

## NPC customers

- [ ] NPCs spawn only with enough on-duty employees.
- [ ] NPC order appears in the kitchen queue.
- [ ] Ready NPC orders complete and produce ratings/tips.
- [ ] Host disconnect reassigns or safely removes the NPC.
- [ ] Timed-out NPC orders reduce reputation.

## Management

- [ ] Manager can hire nearby online players.
- [ ] Manager can change lower grades and fire offline staff.
- [ ] Equal/higher grades cannot be modified.
- [ ] Only owner can withdraw business money.
- [ ] Promotions change server-calculated prices.
- [ ] Reputation unlocks premium menu products.
- [ ] Business upgrades apply their configured effects.
- [ ] Low cleanliness can trigger a health inspection.

## Persistence and recovery

- [ ] Restarting the resource preserves business, employee and equipment data.
- [ ] Offline refunds pay on the customer's next login.
- [ ] Expired ready orders refund customers and return products to stock.
- [ ] Completed or cancelled old orders are cleaned after the retention period.

## NPC departure test

1. Clock in with at least the configured minimum employees.
2. Wait for an NPC order and prepare it normally.
3. Mark the order ready.
4. Confirm the NPC completes the order, leaves the queue, walks to `Config.NPC.exit`, fades, and despawns.
5. Temporarily move the exit somewhere unreachable and confirm `maxWalkTimeMs` still removes the NPC.
6. Set `Config.NPC.departure.walkToExit = false` and confirm completed NPCs despawn without walking.
