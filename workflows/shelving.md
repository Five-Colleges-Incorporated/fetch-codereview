# Shelving

### Questions from kickoff

> How is availability calculated? How are Shelves assigned?

The first entry in shelf position table sorted by location which matches the size_class/owner and isn't already assigned to a Tray or Item.

> How do we report the capacity of the facility/shelf/etc?

You would have to count the total shelf positions vs shelf positions with a Tray or Item.

> How quickly will we fill a facility/shelf/etc?

You could utilize the scanned_for_shelving column on the Tray or Item to see how the capacity is changing over time.

#### The good

The shelving "calculation" is actually very straightforward.
It basically looks for the first shelf position for owner + size_class isn't already assigned.
Additional filters can be provide to narrow down the possible shelf positions.
The calculation is (almost entirely) done in SQL which is more effecient than bring back the data and doing it in python.

There is actual verification during job creation.

#### Ok but notable

The query for shelf positions is unecessarily run twice.
Once to get the shelves but then again to get the shelf positions.
Maybe this is for the weird sorting logic?

There's nothing on the shelf position tracking what is in it.
It is instead stored on the item/tray.

This is another area where assumptions are made about the format of data which is potentially LoC specific.
In this scenario it is the format of the location field.

The storage heirarchy is a lot to manage and navigate. It's probably necessary but maybe there is a simpler alternative?

#### Areas of improvement

This is another area where transactions are mis-used.
First the shelving job is created and committed, then validation happens and the job is deleted if there are errors.

Finding shelf positions is done per owner/size combination.
After each combination the database is committed.
This leaves it in an inconsistent state if a later combination doesn't have available shelving.

### In lieu of a diagram

The logic for assigning shelves is translated into the following sql.

Parameters:
1. Item/Tray owner
1. Item/Tray size class
1. Ladder Id
1. Side Id
1. Aisle Id
1. Module Id
1. Building Id
1. Number of Items/Trays with this owner + size class

```sql
SELECT
  sp.id AS shelf_position_id
FROM shelf_positions sp
JOIN shelf_position_numbers spn ON
  spn.id = sp.shelf_position_number_id
JOIN shelves sh ON
  sh.id = sp.shelf_id
JOIN shelves st ON
  st.id = sh.shelf_type_id
JOIN ladders l ON
  l.id = sh.ladder_id
JOIN sides si ON
  l.side_id = si.id
JOIN aisles a ON
  a.id = si.aisle_id
JOIN modules m ON
  m.id = a.module_id
LEFT JOIN trays tp ON
  sp.id = tp.shelf_position_id
LEFT JOIN trays tpp ON
  sp.id = tpp.shelf_position_proposed_id
LEFT JOIN non_tray_items nti ON
  sp.id = nti.shelf_position_id
LEFT JOIN non_tray_items ntip ON
  sp.id = ntip.shelf_position_proposed_id
WHERE
  tp.id IS NULL AND
  tpp.id IS NULL AND
  nti.id IS NULL AND
  ntip.id IS NULL AND
  st.size_class_id = $1 AND
  sh.owner_id = $2 AND
  ($3 IS NULL OR sh.ladder_id = $3) AND
  ($4 IS NULL OR l.side_id = $4) AND
  ($5 IS NULL OR si.aisle_id = $5) AND
  ($6 IS NULL OR ai.module_id = $6) AND
  m.building_id = $7
ORDER BY sp.location
LIMIT $8
```
