-- this scripts compares user password and password salt
-- between two databases (newprod and oldprod) using Common Table Expressions (CTEs)
-- CTE for combined data from newprod
WITH DB1_Combined_Data AS (
SELECT 
    npu.UserName, 
    npm.Password, 
    npm.PasswordSalt, 
    npm.IsApproved
FROM 
   [firstdbname].dbo.aspnet_Users npu
JOIN 
    [firstdbname].dbo.aspnet_Membership npm ON npu.UserId = npm.UserId
),
-- CTE for combined data from oldprod
DB2_Combined_Data AS (
   SELECT 
    u.UserName, 
    m.Password, 
    m.PasswordSalt, 
    m.IsApproved
FROM        
   [seconddbname].dbo.aspnet_Users u
JOIN 
    [seconddbname].dbo.aspnet_Membership m ON u.UserId = m.UserId
)
-- Final comparison using FULL OUTER JOIN
SELECT
    COALESCE(D1.UserName, D2.UserName) AS Username,
    D1.Password AS NewProdPassWord,
    D2.Password AS OldProdPassWord,
    D1.PasswordSalt AS NewProdPassWorldSalt,
    D2.PasswordSalt AS OldProdPassWorldSalt,
    D1.IsApproved AS NewProdIsApproved,
    D2.IsApproved AS OldProdIsApproved,
    CASE
        WHEN D1.UserName IS NULL THEN 'Only in OldProd'
        WHEN D2.UserName IS NULL THEN 'Only in NewProd'
        WHEN D1.Password <> D2.Password 
            OR D1.PasswordSalt <> D2.PasswordSalt
            OR D1.IsApproved <> D2.IsApproved THEN 'Mismatch in Data'
        ELSE 'Match'
    END AS ComparisonStatus
FROM
    DB1_Combined_Data AS D1
FULL OUTER JOIN
    DB2_Combined_Data AS D2 ON D1.UserName = D2.UserName
