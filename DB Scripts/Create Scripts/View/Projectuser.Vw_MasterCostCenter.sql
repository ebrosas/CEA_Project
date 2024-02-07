/********************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Vw_MasterCostCenter
*	Description: Get the cost center master records
*
*	Date:			Author:		Rev. #:		Comments:
*	10/09/2023		Ervin		1.0			Created
*
*********************************************************************************************************************************************************************************/

CREATE VIEW Projectuser.Vw_MasterCostCenter
AS

	SELECT     
		LTRIM(RTRIM(a.MCCO)) AS CompanyCode,
		LTRIM(RTRIM(a.MCMCU)) AS CostCenter, 
		LTRIM(RTRIM(a.MCDC)) AS CostCenterName, 
		LTRIM(RTRIM(a.MCRP21)) AS ParentCostCenter, 
		a.MCANPA AS CostCenterManager,
		a.MCAN8 AS Superintendent,
		LTRIM(RTRIM(a.MCRP02)) AS GroupCode
	FROM Projectuser.sy_F0006 a WITH (NOLOCK)
	WHERE  LTRIM(RTRIM(a.MCSTYL)) IN ('*', '', 'BP', 'DA') 
		AND LTRIM(RTRIM(a.MCCO)) IN ('00100', '00850')
		AND ISNUMERIC(a.MCMCU) = 1
GO

/*	Debug:

	SELECT * FROM Projectuser.Vw_MasterCostCenter a
	ORDER BY a.CostCenter

*/
