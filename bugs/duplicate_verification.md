# Duplicate Verification Job

> There have been times where if you complete an Accession Job and click cancel and complete, that a duplicate Verification job can be created or that the job numbers can get out of sync.


## Investigation

As covered in the [Accession Workflow](../workflows/accession/04_perform_accession.md), there's nothing in the Inventory Service preventing completing an Accession Job twice.
Then, if it's completed twice there's nothing preventing a duplicate Verification Job.

There are only two places in FETCH where Verification Jobs are created.
1. complete_accession_job task
1. POST /verification-jobs endpoint (which is never called from the frontend)

The internals of the complete_accession_job task don't seem to allow duplication.
The [documentation on Starlette tasks](https://www.starlette.dev/background/) (which is what is handling the task) doesn't seem to run tasks twice.
The Starlette implementation seems simple enough as well using anyio to process it in a background thread.

complete_accession_job tasks get queued when a PATCH /accession-jobs call is made
There are multiple calls to PATCH /accession-jobs but only one of them sets status == "Completed".
Because the status is explicitly set before making each call there isn't a chance that the frontend gets into a bad state which would allow it to "Complete" a job on accident.

This leads me to believe that PATCH /accession-jobs is somehow being called multiple times with a status == "Completed".
As soon as the user clicks the button it is disabled from emitting events again.
If I queue up multiple clicks it creates multiple verification jobs
`[1, 2, 3, 4, 5].forEach(x => complete.click());`

But if I let the event loop flush in between clicks it will only create one.
`[1, 2, 3, 4, 5].forEach(x => setTimeout(() => complete.click(), 0));`
This is a much closer simulation to how a user actually clicks on the button, even if someone is a fast double clicker.

Turning off or slowing down the network to engage the PWA service worker also doesn't allow for multiple submissions.

## Hypotheses and Possible Fixes

Creating multiple Verification jobs from one Accession Job is certainly possible as the Inventory Service does nothing to prevent an Accession Job from being completed twice.
At this exact moment I cannot figure out what series of events cause an Accession Job to be completed twice.

A fix (without knowing the root cause) would require a code change to only trigger the complete_accession_job task when an Accession Job is completed for the first time.
