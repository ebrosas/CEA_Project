/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetLookupTable
*	Description: This stored procedure returns multiple result sets to populate the combo box list items
*
*	Date			Author		Rev. #		Comments:
*	13/04/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetEmployeeList
(
	@empNo	INT = 0
)
AS
BEGIN
	
	SET NOCOUNT ON 
		
	IF ISNULL(@empNo, 0) = 0
		SET @empNo = NULL 

	SELECT	a.EmpNo,
			RTRIM(a.EmpName) AS EmpName,
			RTRIM(a.EmpEmail) AS EmpEmail,
			a.Company,
			RTRIM(a.BusinessUnit) AS CostCenter,
			a.GradeCode AS PayGrade,
			a.Position
	FROM Projectuser.Vw_MasterEmployeeJDE a WITH (NOLOCK)
	WHERE a.DateResigned IS NULL
		AND ISNUMERIC(a.PayStatus) = 1
		AND RTRIM(a.Company) IN ('00100')
		AND (a.EmpNo = @empNo OR @empNo IS NULL)

END 

/*	Debug:

	EXEC Projectuser.Pr_GetEmployeeList
	EXEC Projectuser.Pr_GetEmployeeList 10003632

*/