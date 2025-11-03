# Accession Barcode Lag

> During Accession, the speed of scanning is the #1 complaint. If you go too fast, it misses and you have to go back a few and rescan. You can get used to the rhythm where you can do it fast but not too fast

> Observation: It looks like you can do like 1-2 per second, not 3 per second

> The individual is scanning pretty fast. But it is not as fast as some folks do with LAS (up to like 3 per second, as opposed to the 1-2/second that you see here). They demonstrated that if she scanned only a bit faster that FETCH wouldn't register the scan even though you hear the scanner’s beep. In fact, I think that there is an audible “bonk” and a red box appears at the top of the screen with an error

> I can’t actually explain what the nature of the actual problem. On the one hand, if it is not registering the scan, then I might think that it just takes in whatever is inputted and just “miss” those that came to fast. On the other hand, maybe it “combines” multiple speedy inputs together, rendering them invalid...

## Investigation

The "bonk" noise occurs during Accession if an unhandled exception occurs
* During initial scanning
* During updating a scanned item
* During deleting a scanned item
* During completion of an Accession Job
* On Page Load when checking for a Verification Job for the Completed Accession Job

Of these, the initial scanning "bonk" is the most likely to be the one made when scanning too fast.
Unhandled Exceptions that could happen during this phase:
* Any unexpected server error HTTP>=500
  * Weird null references
  * Server overloaded or down
  * Database connection issues
  * Many others
* verifyBarcode
  * Barcode exists but is not an Item barcode
  * Barcode does not meet Item barcode regex
  * Barcode somehow got created in between checking for it and creating it
* postAccession[Non]TrayItem
  * Item somehow got created in between checking for it and creating it

Handling the barcode scanner is controlled by the barcode input delay setting.
Each "keypress" saves the keypress to a list, then waits X seconds to turn all the saved keypresses into a single barcode.
The barcode reader is nothing fancy, it just emits keypresses. You can simulate it by typing any keys on a keyboard on the Accession screen.
If a "barcode" is entered before the barcode input delay elapses it will be appended to the previously scanned barcode.
The relevant code is in src/composables/useBarcodeScanHandler.js

Setting the barcode input delay to a very small number allows for the rapid entry of barcodes using a keyboard.
On FETCH Local I was able to get to 5-6 per second. FETCH "fell behind" visually but did catch up when I stopped entering barcodes.

## Hypotheses and Possible Fixes

Scanning "too fast" may cause undue load on the server/database which could result in 500 errors.
This is unlikely as the behavior would also manifest when multiple people are scanning at a relaxed pace.

Because the same action (scanning an item) succeeds if done slowly we can rule out null references or a non-item barcode.

This leaves two possible causes.

#### Combined Barcode Validation

The barcode input delay has not elapsed and results in FETCH combining two barcodes into one.
This combined barcode does not match the Item validation regex and results in a failure to validate.

#### Double Scan Race Condition

Checking for the existence of a barcode/item and creating a new barcode/item if it doesn't exist is not atomic.
This can lead to race conditions where after a barcode is confirmed to not exist, it becomes created by another thread/process.
This can happen if a user scans an Item twice when:
* the network connection is temporarily slow
* the server is under temporary load
* postgres chooses different query plans with wildly different performance characteristics
* tables are locked in postgres
* many other hard to predict scenarios

Scanning quickly makes it more likely for multiple requests to be happening at the same time which increases the odds of a race condition.
Scanning quickly also makes it more likely that an Item may be scanned twice in mistake.

### Final hypothesis

Of the two theories I think that the combined barcode validation scenario is most likely.
It can be tested definitively by Temporarily setting the allowed_pattern column to .* in the barcode_types table for Item barcodes and see if an Item is accessioned with a doubled barcode while scanning quickly.

If loosening the allowed_pattern does reveal the root cause then the barcode input delay value should be lowered, based on the rate at which the barcode scanner produces characters. The value can be set to a fractional number for < 1 second delays.

If loosening the allowed_pattern does not reveal the root cause then it is likely to be a race condition. Code changes would be needed to properly handle this scenario.
