
ALTER VIEW Projectuser.Master_CostCenter
AS

	SELECT  LTRIM(RTRIM(MCMCU)) AS CostCenter, 
			MCDL01 AS CostCenterName, 
			MCRP21 AS ParentCC, 
			CAST(MCAN8 AS INT) AS ManagerNo,
			MCSTYL CostCenterType,
			LTRIM(RTRIM(a.MCRP02)) AS GroupCode,
			a.MCCO AS CompanyCode,
			a.MCCO
	FROM Projectuser.sy_F0006 a WITH (NOLOCK)
	WHERE (a.MCSTYL IN ('*', ' ', 'BP', 'AL')) AND (a.MCCO IN ('00100', '00600'))

	UNION

	SELECT	'7850' AS 'CostCenter', 
			'7850 - Management Services' AS 'CostCenterName', 
			0 AS ParentCC, 
			0 AS ManagerNo,
			'' CostCenterType,
			'' AS GroupCode,
			'00100' AS CompanyCode,
			'00100' AS MCCO

GO

/*	Debug:

	SELECT * FROM Projectuser.Master_CostCenter

*/

