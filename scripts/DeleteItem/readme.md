## Objective of these scripts

- These scripts will be used to delete the items from Sitecore Content Tree based on available options.

### How to delete the items

- Right click on Context Item
- Go to the Scripts --> Content Migration --> Content --> Delete Item
- Select Nested true if you want nested items to delete
- Select the templates what you want to exclude

### How to get the delete the items from recycle bin

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Content --> Get Deleted Items Report From Recycle Bin
- Select the start and end date to filter the results
- this script returns the deleted items on provided date range

### How to delete the items from csv

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Content --> Delete Content Items
- Upload the csv file
- this script deletes the item
