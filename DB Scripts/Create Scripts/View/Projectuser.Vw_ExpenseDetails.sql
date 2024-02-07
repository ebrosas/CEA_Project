/******************************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Vw_ExpenseDetails
*	Description: Get the expense details information from JDE
*
*	Date:			Author:		Rev. #:		Comments:
*	27/04/2023		Ervin		1.0			Created
*
******************************************************************************************************************************************************************************************************************/

ALTER VIEW Projectuser.Vw_ExpenseDetails
AS


	SELECT	LTRIM(RTRIM(a.PDKCOO)) AS Company, 
			LTRIM(RTRIM(a.PDMCU)) AS CostCenter, 
			RTRIM(c.CostCenterName) AS CostCenterName,
			a.PDDOCO AS OrderNumber, 
			a.PDLNID / 1000 AS [LineNo], 
			projectuser.ConvertFromJulian(a.PDTRDJ) AS OrderDate, 
			b.ABAN8 AS VendorNo,
			LTRIM(RTRIM(b.ABALPH)) AS Vendor, 
			LTRIM(RTRIM(a.PDDSC1)) AS Description1, 
			LTRIM(RTRIM(a.PDDSC2)) AS Description2, 
			(a.PDUORG + A.PDUCHG) / 1000 AS Quantity, 
			a.PDAOPN / 1000 AS POAmount,
			0 AS GLAmount,
			LTRIM(RTRIM(a.PDCRCD)) AS CurrencyCode, 
			(a.PDFEA + a.PDFCHG) / 100 AS CurrencyAmount, 
			LTRIM(RTRIM(a.PDAID)) AS AccountID, 
			LTRIM(RTRIM(a.PDSBL)) AS CEANumber,
			a.PDDOCO,
			a.PDLNID,
			'PO' AS [Source]
	FROM  Projectuser.sy_F4311 a WITH (NOLOCK)	
		LEFT JOIN Projectuser.sy_F0101 b WITH (NOLOCK) ON a.PDAN8 = b.ABAN8
		LEFT JOIN Projectuser.Master_CostCenter c WITH (NOLOCK) ON LTRIM(RTRIM(a.PDMCU)) = RTRIM(c.CostCenter)
	WHERE LTRIM(RTRIM(a.PDDCTO)) = 'OP' 
		AND LTRIM(RTRIM(a.PDLTTR)) <> '980' 
		AND a.PDAOPN <> 0   
	
	UNION ALL

	SELECT  LTRIM(RTRIM(a.GLKCO)) AS Company, 
			LTRIM(RTRIM(GLMCU)) AS CostCenter, 
			RTRIM(c.CostCenterName) AS CostCenterName,
			GLPO AS OrderNumber, 
			GLJELN AS [LineNo], 
			projectuser.ConvertFromJulian(GLDICJ) AS OrderDate, 
			b.ABAN8 AS VendorNo,
			ISNULL(ABALPH, '') AS Vendor, 
			GLEXA AS Description1, 	
			GLEXR AS Description2, 
			0 AS Quantity,
			0 AS POAmount, 
			GLAA / 1000 AS GLAmount, 
			'BD' AS CurrencyCode, 
			0 AS CurrencyAmount, 
			GLAID AS AccountID, 
			LTRIM(RTRIM(GLSBL)) AS CEANumber,
			GLPO,
			GLLNID,
			'GL' AS [Source]
	FROM Projectuser.sy_F0911 a WITH (NOLOCK) 
		LEFT JOIN Projectuser.sy_F0101 b WITH (NOLOCK) ON a.GLAN8 = b.ABAN8
		LEFT JOIN Projectuser.Master_CostCenter c WITH (NOLOCK) ON LTRIM(RTRIM(a.GLMCU)) = RTRIM(c.CostCenter)
	WHERE a.GLSBL <> ' ' 
		AND LTRIM(RTRIM(a.GLLT)) = 'AA'    
GO

/*	Debug:

	SELECT * FROM Projectuser.Vw_ExpenseDetails a
	WHERE a.CEANumber = '20220046'

*/
