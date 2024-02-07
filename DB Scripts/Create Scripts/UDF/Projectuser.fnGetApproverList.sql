/**************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetApproverList
*	Description: This function is used to fetch the approver list based on the CEA requisition number
*
*	Date:			Author:		Rev.#:		Comments:
*	12/09/2023		Ervin		1.0			Created
**************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetApproverList
(
	@ceaNo	VARCHAR(50)
)
RETURNS  @rtnTable TABLE  
(   
	RequisitionID		INT,  
	RequisitionNo		VARCHAR(50),
	EmpNo		        INT,
	EmpName				VARCHAR(50),
	ApplicationUserID	INT,
	IsAnonymousUser		BIT 
) 
AS
BEGIN

	DECLARE @requisitionID		INT = 0,  
			@requisitionNo		VARCHAR(50) = 0,
			@empNo		        INT = 0,
			@empName			VARCHAR(50) = '',
			@applicationUserID	INT = 0,
			@asAnonymousUser	BIT = 0

	--Get the approvers list
	INSERT INTO @rtnTable 
	SELECT a.RequisitionID, a.RequisitionNo, d.EmpNo, RTRIM(d.EmpName), d.ApplicationUserID, c.IsAnonymousUser
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
		INNER JOIN dbo.RequisitionStatusDetail c WITH (NOLOCK) ON b.RequisitionStatusID = c.RequisitionStatusID
		CROSS APPLY
		(
			SELECT x.EmployeeNo AS EmpNo, x.FullName AS EmpName, x.ApplicationUserID 
			FROM dbo.ApplicationUser x WITH (NOLOCK)
			WHERE x.ApplicationUserID = c.ApplicationUserID

			UNION
            
			SELECT x.EmpNo, x.EmpName, x.EmpNo AS ApplicationUserID 
			FROM Projectuser.Vw_MasterEmployeeJDE x
			WHERE x.EmpNo = c.ApplicationUserID
				AND c.IsAnonymousUser = 1
		) d
	WHERE RTRIM(a.RequisitionNo) = LTRIM(RTRIM(@ceaNo))

	RETURN 

END


/*	Debugging:
	
	SELECT * FROM Projectuser.fnGetApproverList('20230060')

*/
