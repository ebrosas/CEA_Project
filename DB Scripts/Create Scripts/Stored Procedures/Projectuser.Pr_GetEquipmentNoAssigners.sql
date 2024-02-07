/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetEquipmentNoAssigners
*	Description: This stored procedure is used to fetch the list of employees who are authorized to assign equipment no. to a CEA request
*
*	Date			Author		Rev. #		Comments:
*	10/09/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetEquipmentNoAssigners 
(
	@ceaNo	VARCHAR(50)   
)
AS
BEGIN 
    
	SET NOCOUNT ON 

	SELECT	d.EmpNo,
			d.EmpName,
			d.EmpEmail,
			RTRIM(a.RequisitionDescription) AS CEADescription
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
		INNER JOIN dbo.EquipmentRoutingExpenditureType c WITH (NOLOCK) ON RTRIM(b.ExpenditureType) = RTRIM(c.ExpenditureType)
		OUTER APPLY
		(
			SELECT	EmpNo, EmpName, EmpEmail
			FROM Projectuser.fnGetWFActionMember('EQUIPADMIN', 'ALL', 0)
		) d	 	
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

END 

/*	Debug:

PARAMETERS:
	@requisitionNo					VARCHAR(50),    
    @groupRountingSequence			INT,
    @statusCode						VARCHAR(50)

	EXEC Projectuser.Pr_GetEquipmentNoAssigners 20210029

*/