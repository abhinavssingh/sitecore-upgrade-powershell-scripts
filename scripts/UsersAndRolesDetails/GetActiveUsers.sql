-- This script retrieves active users from the Sitecore database, filtering by usernames that start with 'sitecore' followed by a letter.
-- It selects the username, email, and last login date, ordering the results by last login
USE [YourDatabaseName]; -- Replace with your actual database name
SELECT 
    u.UserName, 
    m.Email, 
    m.LastLoginDate 
FROM 
    dbo.aspnet_Users u
JOIN 
    dbo.aspnet_Membership m ON u.UserId = m.UserId
 where u.UserName like 'sitecore\[a-z]%'
ORDER BY 
    m.LastLoginDate desc