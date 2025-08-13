## Objective of these scripts

- These scripts will be used to get user details and update its properties.

### How to get the sitecore users details (option-1)

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Get Users with Role Details
- this returns the users with role deatils

### How to get the sitecore users details (option-2)

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Get Users with Complete Details
- this returns the users with complete deatils means along with custom properties

### How to get the sitecore users enanle/disable status

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Get Enable-Disable Users
- this returns the users status

### How to get the sitecore modified users based on date range

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Get Modified Users
- Select start and end date
- this returns the modified users

### How to get the sitecore modified roles based on date range

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Get Modified Roles
- Select start and end date
- this returns the modified roles

### How to update the sitecore user enable/disable status

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Update Users Enable-Disable Status
- Upload the csv file
- this updates user status

### How to update the sitecore roles

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Update Users Roles
- Upload the csv file
- this updates user roles

### How to update the sitecore users custom properties

- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Update Users Custom Properties
- Upload the csv file
- this updates user custom properties

### How to update the sitecore users password

- login to db server and open ssms
- update db name and execute GetUsersPassword.sql
- save the data as csv. check header row is present or not. If it is not present, add header row.
- Click on Sitecore start button.
- Reporting Tools --> PowerShell Reports --> Content Migration Reports --> Security --> Update Users Passwords
- Upload the csv file
- this updates user password
- post password migration execute DBCompareUsingCTE.sql to validate the password migration is done successfully

### How to get the sitecore active users based on last login to sitecore

- login to db server and open ssms
- update db name and execute GetActiveUsers.sql
- save the data as csv. check header row is present or not. If it is not present, add header row.
