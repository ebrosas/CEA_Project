USE [ProjectRequisition]
GO

/****** Object:  View [Projectuser].[Master_CostCenter]    Script Date: 03/07/2023 02:48:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO












ALTER            VIEW [Projectuser].[Master_CostCenter]
AS
SELECT     	LTRIM(RTRIM(MCMCU)) AS CostCenter, 
		MCDL01 AS CostCenterName, 
		MCRP21 AS ParentCC, 
		CAST(MCAN8 AS INT) AS ManagerNo,
		MCSTYL CostCenterType,
		MCCO
FROM         	JDE_PRODUCTION.PRODDTA.F0006
WHERE     	(MCSTYL IN ('*', ' ', 'BP', 'AL')) AND (MCCO IN ('00100', '00600'))

UNION

SELECT '7850' AS 'CostCenter', '7850 - Management Services' AS 'CostCenterName', 
0 AS ParentCC, 
		0 AS ManagerNo,
		'' CostCenterType,
		'00100'











GO


