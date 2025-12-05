# Shelf Renumbering

### Implementation

Right now, using the API a shelf number can be updated.
This is not recommended for a number of reasons.
1. The shelf locations are not updated and have the incorrect location string
1. Because automatic shelf assignment only uses the shelf location string it will now be incorrect
1. Displaying the list of shelves in the Admin UI uses the order with with postgre returns the shelves, this does not respect the new number

In order to address the first two of the above issues, the Inventory Service can extend the functionality in `events.py`.
When a ShelfPosition or Shelf are created the locations are generated using SqlAlchemy native functionality.
Additional SqlAlchemy functionality for on_update can keep this up to date when the shelf number changes.
This approach is very much akin to SQL Triggers, commonly seen as bad practice or "spooky action at a distance".

A better approach would be to explictly queue the events to update locations when the shelf number is updated.
This happens in other scenarios, like completing an Accession Job.
The "best" applications using Domain Driven Design make this consisent and easy to implement.

In the frontend, editing any part of the location shares the same modal.
This is not done using polymorphism/composition but instead uses a switch statement.
It is unclear why the shelf number field is not editable.

This form in general allows for submitting some bad values with no feedback.
Shelf number in particular is tricky.
There are only 100 shelf numbers created with the seed.
I do not understaing why shelf numbers have been normalized in this way.

None of this addresses the difference between the physical location of the shelf and the logical location in FETCH.
In order to address both the display and auto-assignment, the logical location will have to be incorporated into the shelf assignment.

If we want to "split" a shelf a new modal will have to be created.
The existing modal assumes editing a specific shelf in a specific way that is tied to editing the rest of the Locations in FETCH.
Additionally, a batch endpoint should also be created. There is an existing "batch-upload" route but this is different.
I'm not sure if this paradigm exists in FETCH given the already loose handling of transactions.

If time is of the essence, implementing this right now I would recommend a database script over making changes to FETCH.

### Raw Notes

For some reason, shelf numbers are a separate table with many shelves pointing to the same shelf number record.
While currently, the id of the shelf number and the shelf number itself is the same the fact that it exists complicates renumbering shelves.

Additionally, the displayed shelf location is discretely calculated and saved to the database, rather than being dynamically generated based on its components.

Scenarios for adding a shelf

1. Keeping existing numbers (which are physically on the shelf?) but changing the logical order.
1. Re-numbering existing numbers (changing on the shelfs too)
1. Changing the barcode

What does changing this impact?

1. Adding a shelf between 7 and 8
1. If "renumber shelves" everything in 8+ will need to be updated to a new shelf?
1. That doesn't change any shelf calculations I guess
1. Actually nothing additional changes about the items?
1. So basically, just shift everything above to be +1 shelf position

1. Adding a new shelf to a ladder (without priority order) currently puts it "at the front"
1. This is because they are not sorted and pg returns them in a somewhat random order
1. They could be sorted by shelf number in the UI if passed.
1. This new shelf, can be made to display in the correct place in the shelf list but not in the shelf assignment calculations
1. The shelf assignment is purely based on shelf_number

Fixes/changes
Have the shelf assignment take into account the sort priority? (which would change the format of the location string?)
Maybe just get rid of the sort priority.
Recalculate all the location strings
Need to add ability to insert a shelf and shift the existing shelves.

Shelf positions are assigned by
building-module-aisle-side-ladder-SHELF NUMBER-position

* If shelves are inserted into the middle with non-contiguous numbering we need to choose based on something else
* If shelves are inserted and numbering shifts, we have to recalc the locations on every shelf and position

There's weird background tasks for updating the location field that could be reused.


