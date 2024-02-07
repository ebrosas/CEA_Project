/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ApproveRequisition
*	Description: This stored procedure is used to fetch the employees who can upload CEA requisition into JDE
*
*	Date			Author		Rev. #		Comments:
*	08/09/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetCEAAdministratorEmailList 
(
	@ceaNo	VARCHAR(50)   
)
AS
BEGIN 
    
	SET NOCOUNT ON 

	DECLARE @empNo		INT = 0,
			@empName	VARCHAR(50) = '',
			@empEmail	VARCHAR(50) = '',
			@ceaDesc	VARCHAR(40) = ''

	--Get the CEA description
	SELECT @ceaDesc = RTRIM(a.RequisitionDescription)
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

	--Get the employee info
	SELECT	EmpNo, EmpName, EmpEmail, @ceaDesc AS CEADescription 
	FROM Projectuser.fnGetWFActionMember('CEAUPLOADR', 'ALL', 0)	

END 

/*	Debug:

PARAMETERS:
	@requisitionNo					VARCHAR(50),    
    @groupRountingSequence			INT,
    @statusCode						VARCHAR(50)

	EXEC Projectuser.Pr_GetCEAAdministratorEmailList 20210029

*/