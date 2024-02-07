/**************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetWFAssignedPerson
*	Description: This function is used to get the current assigned person of the CEA request based on the workflow setup
*
*	Date:			Author:		Rev.#:		Comments:
*	13/09/2023		Ervin		1.0			Created
**************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetWFAssignedPerson
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

	--Get the assigned person details
	SELECT
		@assignedEmpNo = CASE WHEN RTRIM(b.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN a.CEAOriginatorNo ELSE b.CurrentDistMemEmpNo END, --b.CurrentDistMemEmpNo,
		@assignedEmpName = CASE WHEN RTRIM(b.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN RTRIM(a.CEAOriginatorName) ELSE RTRIM(b.CurrentDistMemEmpName) END,	--RTRIM(b.CurrentDistMemEmpName),
		@assignedCostCenter = d.CostCenter,
		@statusCode = RTRIM(c.UDCCode),
		@statusDesc = RTRIM(c.UDCDesc1),
		@statusHandlingCode = RTRIM(C.UDCSpecialHandlingCode),
		@approvalStatus  = RTRIM(c.UDCDesc1)
	FROM Projectuser.sy_CEAWF a WITH (NOLOCK) 
		INNER JOIN Projectuser.sy_CurrentDistributionMember b WITH (NOLOCK) ON a.CEARequisitionNo = b.CurrentDistMemReqTypeNo AND b.CurrentDistMemCurrent = 1
		INNER JOIN Projectuser.UserDefinedCode c WITH (NOLOCK) ON a.CEAStatusID = c.UDCID AND c.UDCUDCGID = 9
		OUTER APPLY
		(
			SELECT LTRIM(RTRIM(x.YAHMCU)) AS CostCenter 
			FROM Projectuser.sy_F060116 x WITH (NOLOCK)
			WHERE CAST(x.YAAN8 AS INT) = CASE WHEN RTRIM(b.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN a.CEAOriginatorNo ELSE b.CurrentDistMemEmpNo END
		) d
	WHERE RTRIM(a.CEARequisitionNo) = LTRIM(RTRIM(@ceaNo))
		AND b.CurrentDistMemReqType = 22

	INSERT INTO @rtnTable 
	SELECT @assignedEmpNo, @assignedEmpName, @assignedCostCenter, @statusCode, @statusDesc, @statusHandlingCode, @approvalStatus

	RETURN 
END


/*	Debugging:
	
	SELECT * FROM Projectuser.fnGetWFAssignedPerson('20230085')
	SELECT * FROM Projectuser.fnGetWFAssignedPerson('20230093')	

*/
