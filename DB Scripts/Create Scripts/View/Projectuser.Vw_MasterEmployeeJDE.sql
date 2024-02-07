/********************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Vw_MasterEmployeeJDE
*	Description: Get the employee information from the Employee Master Table
*
*	Date:			Author:		Rev. #:		Comments:
*	13/04/2023		Ervin		1.0			Created
*
*********************************************************************************************************************************************************************************/

ALTER VIEW Projectuser.Vw_MasterEmployeeJDE
AS

	SELECT     
		CAST(a.YAAN8 AS INT) AS EmpNo, 
		LTRIM(RTRIM(a.YAALPH)) AS EmpName, 
		LTRIM(RTRIM(g.DRDL01)) + ' ' + LTRIM(RTRIM(g.DRDL02)) AS Position,
		LTRIM(RTRIM(a.YAEEOM)) AS ReligionCode, 
		LTRIM(RTRIM(a.YAEEOJ)) AS JobCategoryCode, 
		LTRIM(RTRIM(a.YASEX)) AS SexCode, 
		CASE WHEN ISNULL(b.WorkingBusinessUnit, '') <> ''
			THEN LTRIM(RTRIM(b.WorkingBusinessUnit))
			ELSE
				CASE WHEN LTRIM(RTRIM(c.ABAT1)) = 'E' THEN LTRIM(RTRIM(a.YAHMCU))
					WHEN LTRIM(RTRIM(c.ABAT1)) IN ('UG', 'X') THEN LTRIM(RTRIM(c.ABMCU)) 
				END
		END AS BusinessUnit,	
		LTRIM(RTRIM(a.YAHMCO)) AS Company, 
		CASE WHEN ISNUMERIC(ISNULL(a.YAPGRD, '0')) = 1 
			THEN CONVERT(INT, LTRIM(RTRIM(ISNULL(a.YAPGRD, '0')))) 
			ELSE 0 
		END AS GradeCode,
		CASE WHEN ISNULL(d.T3EFT, 0) = 0 
			THEN Projectuser.ConvertFromJulian(ISNULL(a.YADST, 0)) 
			ELSE Projectuser.ConvertFromJulian(d.T3EFT) 
		END AS DateJoined,
		Projectuser.ConvertFromJulian(a.YADT) AS DateResigned,
		CASE WHEN (a.YAPAST IN ('R', 'T', 'E', 'X') AND GETDATE() < Projectuser.ConvertFromJulian(a.YADT)  OR UPPER(LTRIM(RTRIM(a.YAPAST))) IN ('I', 'A', 'P')) THEN '0' ELSE a.YAPAST END AS PayStatus,
		Projectuser.ConvertFromJulian(a.YADOB) AS DateOfBirth,
		CASE WHEN LTRIM(RTRIM(c.ABAT1)) = 'E' THEN LTRIM(RTRIM(a.YAHMCU))
			WHEN LTRIM(RTRIM(c.ABAT1)) IN ('UG', 'X') THEN LTRIM(RTRIM(c.ABMCU)) 
		END AS ActualCostCenter,
		ROUND
		(
			CONVERT(FLOAT,
			DATEDIFF
			(
				MONTH, 
				CASE WHEN ISNULL(d.T3EFT, 0) = 0 
					THEN Projectuser.ConvertFromJulian(ISNULL(a.YADST, 0)) 
					ELSE Projectuser.ConvertFromJulian(d.T3EFT) 
				END,
				GETDATE() 
			)) 
		/ 12, 2) AS YearsOfService,
		CASE WHEN LTRIM(RTRIM(ISNULL(f.EAEMAL, ''))) = 'payment.confirmation@garmco.com'	--Rev. #1.2
			THEN NULL
			ELSE LTRIM(RTRIM(ISNULL(f.EAEMAL, ''))) 
		END AS EmpEmail,
		CAST(a.YAANPA AS INT) AS SupervisorNo
	FROM Projectuser.sy_F060116 a WITH (NOLOCK)
		LEFT JOIN Projectuser.sy_Master_EmployeeAdditional b WITH (NOLOCK) ON CAST(a.YAAN8 AS INT) = b.EmpNo
		LEFT JOIN Projectuser.sy_F0101 c WITH (NOLOCK) ON a.YAAN8 = c.ABAN8
		LEFT JOIN Projectuser.sy_F00092 d WITH (NOLOCK) ON a.YAAN8 = d.T3SBN1 AND LTRIM(RTRIM(d.T3TYDT)) = 'WH' AND LTRIM(RTRIM(d.T3SDB)) = 'E'
		LEFT JOIN Projectuser.sy_F01151 f WITH (NOLOCK) ON a.YAAN8 = f.EAAN8 AND f.EAIDLN = 0 AND f.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(f.EAETP))) = 'E' --AND f.EAEHIER = 1 
		LEFT JOIN Projectuser.sy_F0005 g WITH (NOLOCK) ON LTRIM(RTRIM(a.YAJBCD)) = LTRIM(RTRIM(g.DRKY)) AND RTRIM(LTRIM(g.DRSY)) = '06' AND RTRIM(LTRIM(g.DRRT)) = 'G'	--Rev. #1.3
	WHERE a.YAAN8 > 10000000

GO 