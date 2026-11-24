# Tablet Grade Permissions

All employee-tablet access is configured in `Config.TabletAccess` inside `config.lua`.

The values are minimum ESX job grades. A lower number grants access to more employees; a higher number restricts access to senior grades.

## Page permissions

```lua
Config.TabletAccess.pages = {
    orders = Config.Grades.trainee,
    deliveries = Config.Grades.trainee,
    register = Config.Grades.employee,
    catering = Config.Grades.employee,
    supplies = Config.Grades.senior,
    stock = Config.Grades.trainee,
    profile = Config.Grades.trainee,
    business = Config.Grades.supervisor,
    equipment = Config.Grades.supervisor,
    promotions = Config.Grades.manager,
    staff = Config.Grades.manager
}
```

A page that the employee cannot access is not added to the tablet sidebar. If a player opens the tablet with a restricted requested page, the tablet automatically opens the configured default page or the first page they can access.

## Action permissions

```lua
Config.TabletAccess.actions = {
    updateOrder = Config.Grades.trainee,
    cancelReadyOrder = Config.Grades.supervisor,
    acceptDelivery = Config.Grades.trainee,
    createRegisterOrder = Config.Grades.employee,
    acceptCatering = Config.Grades.employee,
    startCateringDelivery = Config.Grades.employee,
    startSupplyRun = Config.Grades.senior,
    depositBusiness = Config.Grades.supervisor,
    withdrawBusiness = Config.Grades.owner,
    repairEquipment = Config.Grades.supervisor,
    upgradeEquipment = Config.Grades.manager,
    createPromotion = Config.Grades.manager,
    disablePromotion = Config.Grades.manager,
    employeeAction = Config.Grades.manager,
    buyBusinessUpgrade = Config.Grades.owner
}
```

Pages and actions are separate. For example, a supervisor can view the equipment page and repair equipment, while only a manager can upgrade it. A supervisor can view business finances and deposit money, while only the owner can withdraw money or purchase business upgrades.

## Security behavior

The NUI hides pages and buttons for usability, but the client is never trusted. Every privileged callback checks the current ESX job, current grade and on-duty state on the server. Restricted employee, financial, equipment and logistics data is also omitted from the bootstrap payload.

## Custom examples

Allow trainees to use the register:

```lua
Config.TabletAccess.pages.register = Config.Grades.trainee
Config.TabletAccess.actions.createRegisterOrder = Config.Grades.trainee
```

Let managers purchase business upgrades while keeping withdrawals owner-only:

```lua
Config.TabletAccess.actions.buyBusinessUpgrade = Config.Grades.manager
Config.TabletAccess.actions.withdrawBusiness = Config.Grades.owner
```

Give supervisors read-only staff access:

```lua
Config.TabletAccess.pages.staff = Config.Grades.supervisor
Config.TabletAccess.actions.employeeAction = Config.Grades.manager
```
