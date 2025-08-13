-- this script retrieves user password and password salt from the database
-- It selects the username, password, password salt, and approval status, ordering the results by username
USE [YourDatabaseName]; -- Replace with your actual database name
SELECT 
    u.UserName, 
    m.Password, 
    m.PasswordSalt, 
    m.IsApproved
FROM 
    dbo.aspnet_Users u
JOIN 
    dbo.aspnet_Membership m ON u.UserId = m.UserId
ORDER BY 
    u.UserName;