USE MedicationTracker;
GO

-- Company facility count.
SELECT
    c.CompanyKey        AS CompanyKey,
    c.CompanyName       AS CompanyName,
    COUNT(*)            AS FacilityCount
FROM
    dbo.Company c
INNER JOIN
    dbo.Facility f
ON
    f.CompanyKey = c.CompanyKey
GROUP BY
    c.CompanyKey,
    c.CompanyName
ORDER BY
    COUNT(*) DESC;
GO

-- Company facilities.
SELECT
    c.CompanyKey,
    c.CompanyName,
    f.FacilityKey,
    f.FacilityName
FROM
    dbo.Company c
INNER JOIN
    dbo.Facility f
ON
    f.CompanyKey = c.CompanyKey
ORDER BY
    c.CompanyKey,
    f.FacilityKey;
GO
