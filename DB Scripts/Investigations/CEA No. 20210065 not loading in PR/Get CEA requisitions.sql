	SELECT a.ABALKY AS CEANo, LTRIM(RTRIM(a.ABALPH)) AS CEADesc, LTRIM(RTRIM(a.ABMCU)) AS CostCenter, a.AccountID, a.BudgetYear, 
		LTRIM(RTRIM(b.GMMCU)) AS BusinessUnit, LTRIM(RTRIM(b.GMOBJ)) AS ObjectAcct, LTRIM(RTRIM(b.GMSUB)) AS Subsidiary, LTRIM(RTRIM(a.ABALPH)) AS AcctDescription, 
		a.TotalBudget, a.TotalIncurred, a.TotalInProcess, a.TotalPROrder 
	FROM 
	(
		SELECT a.ABALKY, a.ABMCU, a.AccountID, a.ABALPH, a.BudgetYear, a.TotalBudget, 
			a.TotalIncurred, a.TotalInProcess, a.TotalPROrder 
		FROM 
		(
			SELECT ROW_NUMBER() OVER(ORDER BY a.ABALKY DESC, b.BudgetYear) AS RowNumber, a.ABAN8, a.ABALKY, a.ABALPH, a.ABMCU, b.AccountID, 
				ISNULL(b.BudgetYear, 0) AS BudgetYear, ISNULL(b.TotalBudget, 0) AS TotalBudget, ISNULL(b.TotalIncurred, 0) AS TotalIncurred, 
				ISNULL(b.TotalInProcess, 0) AS TotalInProcess, ISNULL(b.TotalPROrder, 0) AS TotalPROrder 
			FROM SecUser.F0101 AS a 
				INNER JOIN SecUser.CostCenterBudget AS b ON LTRIM(RTRIM(a.ABALKY)) = b.SubLedger  AND a.ABALKY = '20210065' --AND LTRIM(RTRIM(a.ABMCU)) = '3890'
		) AS a 
		WHERE a.RowNumber BETWEEN 1 AND 10
	) AS a 
	LEFT JOIN SecUser.F0901 AS b ON a.AccountID = LTRIM(RTRIM(b.GMAID)) AND b.GMPEC <> 'I' AND b.GMPEC <> 'N'  
	ORDER BY a.ABALKY DESC, a.BudgetYear