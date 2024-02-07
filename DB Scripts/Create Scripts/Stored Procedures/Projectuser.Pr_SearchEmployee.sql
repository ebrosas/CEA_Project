/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_SearchEmployee
*	Description: This stored procedure returns the list of all employees in the company based on search criteria
*
*	Date			Author		Rev. #		Comments:
*	07/05/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SearchEmployee
(
	@empNo			INT = 0,
	@empName		VARCHAR(50) = '',
	@costCenter		VARCHAR(12) = ''	
)
AS
BEGIN

	SET NOCOUNT ON 

	--Validate parameters
	IF ISNULL(@empNo, 0) = 0
		SET @empNo = NULL 
	ELSE
	BEGIN

		IF LEN(@empNo) = 4
			SET @empNo = 10000000 + @empNo
    END 

	IF ISNULL(@empName, '') = ''
		SET @empName = NULL 

	IF ISNULL(@costCenter, '') = ''
		SET @costCenter = NULL 

	SELECT * FROM
	(
		SELECT	CAST(a.YAAN8 AS INT) AS EmpNo, 
				LTRIM(RTRIM(a.YAALPH)) AS EmpName, 
				CASE WHEN LTRIM(RTRIM(b.ABAT1)) = 'E' THEN LTRIM(RTRIM(a.YAHMCU)) WHEN LTRIM(RTRIM(b.ABAT1)) = 'UG' THEN LTRIM(RTRIM(b.ABMCU)) END AS CostCenter,
				LTRIM(RTRIM(d.MCDC)) AS CostCenterName, 
				CASE WHEN ISNUMERIC(ISNULL(a.YAPGRD, '0')) = 1 
					THEN CONVERT(INT, LTRIM(RTRIM(ISNULL(a.YAPGRD, '0')))) 
					ELSE 0 
				END AS PayGrade,
				CASE WHEN (a.YAPAST IN ('R', 'T', 'E', 'X') AND GETDATE() < Projectuser.ConvertFromJulian(a.YADT)  OR UPPER(LTRIM(RTRIM(a.YAPAST))) IN ('I', 'A', 'P')) THEN '0' ELSE a.YAPAST END AS PayStatus,		
				CASE WHEN ISNULL(c.T3EFT, 0) = 0 
					THEN Projectuser.ConvertFromJulian(ISNULL(a.YADST, 0)) 
					ELSE Projectuser.ConvertFromJulian(c.T3EFT) 
				END AS DateJoined,
				CAST(a.YAANPA AS INT) AS SupervisorEmpNo,
				f.SupervisorEmpName,
				LTRIM(RTRIM(ISNULL(e.EAEMAL, ''))) AS Email
		FROM Projectuser.sy_F060116 a WITH (NOLOCK)
			INNER JOIN Projectuser.F0101 b WITH (NOLOCK) ON a.YAAN8 = b.ABAN8
			LEFT JOIN Projectuser.sy_F00092 c WITH (NOLOCK) ON a.YAAN8 = c.T3SBN1 AND LTRIM(RTRIM(c.T3TYDT)) = 'WH' AND LTRIM(RTRIM(c.T3SDB)) = 'E'
			LEFT JOIN Projectuser.sy_F0006 d WITH (NOLOCK) ON CASE WHEN LTRIM(RTRIM(b.ABAT1)) = 'E' THEN LTRIM(RTRIM(a.YAHMCU)) WHEN LTRIM(RTRIM(b.ABAT1)) = 'UG' THEN LTRIM(RTRIM(b.ABMCU)) END = LTRIM(RTRIM(d.MCMCU))
			LEFT JOIN Projectuser.sy_F01151 e WITH (NOLOCK) ON a.YAAN8 = e.EAAN8 AND e.EAIDLN = 0 AND e.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(e.EAETP))) = 'E' 
			OUTER APPLY
			(
				SELECT LTRIM(RTRIM(YAALPH)) AS SupervisorEmpName  
				FROM Projectuser.sy_F060116 
				WHERE YAAN8 = a.YAANPA
			) f
	) x
	WHERE (x.EmpNo = @empNo OR @empNo is NULL)
		AND (UPPER(RTRIM(x.EmpName)) LIKE '%' + @empName + '%' OR @empName IS NULL)
		AND (x.CostCenter = @costCenter OR @costCenter IS NULL)
		AND ISNUMERIC(x.PayStatus) = 1
		AND x.EmpNo > 10000000
		AND ISNULL(x.CostCenter, '') <> ''
	ORDER BY x.CostCenter, x.EmpName

END 

/*	Debug:

PARAMETERS:	
	@empNo			INT = 0,
	@empName		VARCHAR(50) = '',
	@costCenter		VARCHAR(12) = ''	

	EXEC Projectuser.Pr_SearchEmployee

*/

