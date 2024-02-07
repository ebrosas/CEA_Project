/**************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetCEAAssignedPerson
*	Description: This functions is used to get the current assigned person of the CEA request
*
*	Date:			Author:		Rev.#:		Comments:
*	03/09/2023		Ervin		1.0			Created
**************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetCEAAssignedPerson
(
	@ceaNo	VARCHAR(50)
)
RETURNS  @rtnTable TABLE  
(   
	EmpNo				INT,  
	EmpName				VARCHAR(50),
	CostCenter			VARCHAR(50),
	StatusCode			VARCHAR(50),
	StatusDesc			VARCHAR(50),
	StatusHandlingCode	VARCHAR(10),
	ApprovalStatus		VARCHAR(50)
) 
AS
BEGIN

	DECLARE @assignedEmpNo			INT = 0,  
			@assignedEmpName		VARCHAR(50) = '',
			@assignedCostCenter		VARCHAR(50) = '',
			@statusCode				VARCHAR(50) = '',
			@statusDesc				VARCHAR(50) = '',
			@statusHandlingCode		VARCHAR(10) = '',
			@approvalStatus			VARCHAR(50) = ''

	SELECT	@assignedEmpNo = e.AssignedEmpNo, 
			@assignedEmpName = e.AssignedEmpName, 
			@assignedCostCenter = e.AssignedCostCenter,
			@statusCode = RTRIM(d.UDCCode), 
			@statusDesc = RTRIM(d.UDCDesc1),
			@statusHandlingCode = RTRIM(d.UDCSpecialHandlingCode), 
			@approvalStatus = c.ApprovalStatus
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
		INNER JOIN dbo.ApprovalStatus c WITH (NOLOCK) ON b.ApprovalStatusID = c.ApprovalStatusID
		INNER JOIN Projectuser.UserDefinedCode d WITH (NOLOCK) ON RTRIM(c.WFStatusCode) = RTRIM(d.UDCCode)
		OUTER APPLY
		(
			SELECT x.EmployeeNo AS AssignedEmpNo, RTRIM(x.FullName) AS AssignedEmpName, RTRIM(x.CostCenter) AS AssignedCostCenter
			FROM dbo.RequisitionStatusDetail v WITH (NOLOCK)
				INNER JOIN dbo.ApprovalStatus w WITH (NOLOCK) ON v.ApprovalStatusID = w.ApprovalStatusID AND RTRIM(w.StatusCode) IN ('SubmittedForApproval', 'AwaitingChairmanApproval')
				INNER JOIN dbo.ApplicationUser x WITH (NOLOCK) ON v.ApplicationUserID = x.ApplicationUserID
			WHERE v.RequisitionStatusID = b.RequisitionStatusID
		) e
	WHERE RTRIM(a.RequisitionNo) = LTRIM(RTRIM(@ceaNo))

	INSERT INTO @rtnTable 
	SELECT @assignedEmpNo, @assignedEmpName, @assignedCostCenter, @statusCode, @statusDesc, @statusHandlingCode, @approvalStatus

	RETURN 
END


/*	Debugging:
	
	SELECT * FROM Projectuser.fnGetCEAAssignedPerson('20230048')

*/
