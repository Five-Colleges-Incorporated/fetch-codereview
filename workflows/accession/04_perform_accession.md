#### The good

#### The ok but notable

POSTing the AccessionJob returns the accession job.
Then it is fetched again when navigating to the job page.
I think this once again ties back to the explicit Pinia state handling.

#### Areas of improvement


#### Red Flags

The AccessionTrayInfo and AccessionNonTrayInfo components are 85% the same.
There's about 500 lines of duplicated code.
There's already subtle formatting and logic differences between them which will grow over time.
