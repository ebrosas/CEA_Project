/************************************************************************************************************

Stored Procedure Name	:	pr_CheckAssignedDistributionMember
Description				:	This stored procedure closes the service request and updates the workflow.

							This SP is part of the Transaction Workflow that can be used from different
							projects.

Created By				:	Noel G. Francisco
Date Created			:	17 August 2008

Parameters
	@reqType			:	The Request Type to close
	@reqTypeNo			:	The Request Type No to close
	@reqModifiedBy		:	The employee no. of the user that calls this SP
	@reqModifiedName	:	The employee name of the user that calls this SP

	@retError			:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2008.08.17 12:07
	Created

************************************************************************************************************/

ALTER PROCEDURE secuser.pr_CheckAssignedDistributionMember
(
	@reqType int,
	@reqTypeNo int,
	@currentDistMemEmpNo int,
	@currentDistMemActionType int,
	@currentDistMemRoutineSeq int,
	@currentDistMemCurrent bit OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON

	-- Initialize output
	SELECT @currentDistMemCurrent = 0

	-- Checks if current assigned distribution member
	SELECT @currentDistMemCurrent = ISNULL(a.CurrentDistMemCurrent, 0)
	FROM SecUser.CurrentDistributionMember a WITH (NOLOCK)
	WHERE a.CurrentDistMemReqType = @reqType 
		AND a.CurrentDistMemReqTypeNo = @reqTypeNo 
		AND a.CurrentDistMemEmpNo = @currentDistMemEmpNo 
		AND a.CurrentDistMemActionType = @currentDistMemActionType 
		AND a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq 
		AND a.CurrentDistMemCurrent = 1

END 





