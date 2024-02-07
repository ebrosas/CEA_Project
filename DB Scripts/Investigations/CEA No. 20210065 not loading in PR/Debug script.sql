	SELECT a.ABALKY, a.ABMCU, * FROM SecUser.F0101 AS a WITH (NOLOCK)
	WHERE a.ABALKY = '20210065' 

	SELECT * FROM secuser.CostCenterBudget a WITH (NOLOCK)
	WHERE TRIM(a.CostCenter) = '3890'
	ORDER BY a.BudgetYear, a.SubLedger
	--WHERE a.SubLedger = '20210065' 

	SELECT * FROM secuser.CostCenterBudget a WITH (NOLOCK)
	WHERE TRIM(a.CostCenter) = '7600'
		AND a.SubLedger = '20210045' 
	ORDER BY a.SubLedger