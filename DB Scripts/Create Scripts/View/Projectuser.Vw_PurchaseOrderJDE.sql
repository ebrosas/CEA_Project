/******************************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Vw_PurchaseOrderJDE
*	Description: Get the PO information from JDE
*
*	Date:			Author:		Rev. #:		Comments:
*	08/08/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************************************************/

ALTER VIEW Projectuser.Vw_PurchaseOrderJDE
AS

	SELECT	LTRIM(RTRIM(a.PDKCOO)) AS Company,
			LTRIM(RTRIM(a.PDMCU)) AS CostCenter,
			a.PDDOCO AS OrderNumber,
			a.PDLNID/1000  AS [LineNo],
			Projectuser.ConvertFromJulian(a.PDTRDJ) AS OrderDate,
			LTRIM(RTRIM(b.ABALPH)) AS Vendor,
			LTRIM(RTRIM(a.pddsc1)) AS Description1, 
			LTRIM(RTRIM(a.PDDSC2)) AS Description2,
			(a.PDUORG + a.PDUCHG)/1000 AS Quantity, 
			(a.PDAEXP + a.PDACHG)/1000 AS AmountInBD, 
			LTRIM(RTRIM(a.PDCRCD)) AS CurrencyCode,
			a.PDFEA + a.PDFCHG/100 AS CurrencyAmount,
			LTRIM(RTRIM(a.PDAID)) AS AccountID,
			LTRIM(RTRIM(a.PDSBL)) AS CEANumber
	FROM Projectuser.sy_F4311 a WITH (NOLOCK)
		INNER JOIN Projectuser.sy_F0101 b WITH (NOLOCK) ON a.PDAN8 = b.ABAN8
	WHERE LTRIM(RTRIM(a.PDDCTO)) = 'OP' 
		AND LTRIM(RTRIM(a.PDLTTR)) <> '980' 
	
	UNION ALL

	SELECT	LTRIM(RTRIM(a.GLKCO)) AS Company,
			LTRIM(RTRIM(a.GLMCU)) AS CostCenter,
			a.GLDOC AS OrderNumber,
			a.GLJELN AS [LineNo],
			Projectuser.ConvertFromJulian(a.GLDICJ) AS OrderDate,
			LTRIM(RTRIM(b.ABALPH)) AS Vendor,
			LTRIM(RTRIM(a.GLEXA)) AS Description1,
			LTRIM(RTRIM(a.GLEXR)) AS Description2,
			0 AS Quantity,
			a.GLAA/1000 AS AmountInBD,
			'BD' AS CurrencyCode,
			0 AS CurrencyAmount,
			LTRIM(RTRIM(a.GLAID)) AS AccountID,
			LTRIM(RTRIM(a.GLSBL)) AS CEANumber 
	FROM Projectuser.sy_F0911 a WITH (INDEX (F0911_32))
		INNER JOIN Projectuser.sy_F0101 b WITH (NOLOCK) ON a.GLAN8 = b.ABAN8
	WHERE LTRIM(RTRIM(a.GLSBL)) <> '' 
		AND LTRIM(RTRIM(a.GLLT)) = 'AA' 
		AND a.GLPO = 0

GO 


/*	Debug:

	SELECT TOP 10 * FROM  Projectuser.Vw_PurchaseOrderJDE a

*/

	
