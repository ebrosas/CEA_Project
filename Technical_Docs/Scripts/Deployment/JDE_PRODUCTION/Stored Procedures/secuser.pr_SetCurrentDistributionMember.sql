/************************************************************************************************************

Stored Procedure Name	:	secuser.pr_SetCurrentDistributionMember
Description				:	This stored procedure sets the current distribution member from the workflow.

							This SP is part of the Transaction Workflow that can be used from different
							projects.

Created By				:	Noel G. Francisco
Date Created			:	06 January 2008

Parameters
	@reqType			:	The type of request (e.g. Expense Request, Travel Request etc)
	@reqTypeNo			:	The request type no. as reference
	@actionType			:	The action type of the distribution members to retrieve, this can be
							approver, service provider or validator. This is reference from the UDC Table
							with UDCUDCGID = 11
	@distMemDistListID	:	The distribution list ID used by the Action Activity
	@distMemRoutineSeq	:	The routine sequence where the distribution members will be retrieved
	@createdModifiedBy	:	The employee no. of the user that calls this SP

	@retError			:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2008.01.06 14:04
	Created

	2.0					NGF					2008.03.31 08:46
	Included additional statement to update the progress status of the Distribution Members

	2.1					NGF					2008.04.10 12:05
	Added checking if validator and primary approver only

	2.2					NGF					2008.05.21 10:45
	Use the CostCenterApprover to locate the current approver of the cost center

	2.3					NGF					2008.08.13 07:54
	Added the Cash Advance Request functionality

	2.4					NGF					2009.09.10 09:48
	Added additional condition in case the current employee is the owner and the supervisor becomes
	the current approver has approved already

	2.5					NGF					2010.01.14 10:03
	Added addition code in case the first distribution member is by passed and check if there's
	more distribution next in the routine

	2.6					NGF					2010.01.17 11:09
	Modified the retrieval of employee's cost center for PR, based on working cost center

	2.7					NGF					2010.02.23 15:26
	Modified the retrieval of Cost Center for PAF and EPA

	2.8					NGF					2010.03.21 08:42
	Fixed the problem on transfer PAF

	2.9					NGF					2011.10.02 10:51
	Added necessary execution for TSR

	3.0					NGF					2012.02.21 12:24
	Modified the Max Leave Threshold to zero

	3.1					NGF					2012.04.18 14:07
	Modified the Max Leave Threshold to -1 so the request wil still be reassigned to the substitute if
	the current date is equal to the last day of leave

	3.2					NGF					2012.06.13 09:31
	Added the Clearance Form

	3.3					NGF					2012.12.02 10:54
	Set the action type to Validator for Clearance Form if last action type is an approver

	3.4					SAK					2013.04.10 11:06
	Modified to return charged cost center.

	3.5					NGF					2013.05.21 08:56
	Added validation on the last part if there's no current distribution selected

	3.6					NGF					2013.06.12 09:49
	Added history log if the distribution member is not included due to either on-leave or threshhold setup

	3.7					NGF					2013.09.02 13:42
	Added some hard coding for the CEO so it will not reassign to Adel Hamad if the originator and current approver is
	Graham Bruce

	3.8					NGF					2013.09.18 15:42
	Modified the call to distribution alternate by passing the cost center and request type

	3.9					Ervin				2014.01.21 08:32
	Added condition before inserting or updating records into the "CurrentDistributionMember" and "DistributionMember" tables. 
	Checks for a matching record from "DistributionMemberReplacement" table in Gen_Purpose database.

	4.0					Ervin				2014.06.02 09:12
	Implemented the new logic of getting the employee susbtitute if it's defined in the "Workflow Substitute Settings" form in the ISMS system

	4.1					SAK					2014.06.10 09:50
	Commented out the addition of routine history when bypassing item category approvers.

	4.2					Ervin				2014.06.13 12:12
	Refactored the code in fetching the substiture of the current distribution member from the "Workflow Substitute Settings" form.

	4.3					Ervin				2014.08.19 09:24
	Added extra validation that will check if the original assignee which has beeen substituted already has existing record in the "CurrentDistributionMember" table.
	Added these variables @substitutedEmpNo, @substitutedEmpName, @substitutedEmpEmail 	 

	4.4					Ervin				2015.01.27 14:24
	Refactored the logic in fetching the substitute. The workflow will first check for substitute definition in the following order: 1). ISMS 2) GAP - Leave Request 3) Common Admin 

	4.5					Ervin				2015.02.25 11:30
	Added condition to check if leave approval flag (LRY58VCAFG) is equal to 'A' or 'N' when fetching the substitute of the approver

	4.6					Ervin				2015.03.02 08:25
	Disabled the code that fetches the substitute from the Common Admin System when the assignee is on leave

	4.7					Shoukhat			2015.03.15 07:30
	Modified the initial value of @tempCEO variable from 10006141 to 10003696

	4.8					Shoukhat			2015.04.29 11:00
	Modified to reset the substitute and substitutedemployee settings at each loop becuase this was duplicating approvers for parallel approvers if any substitutes found.
	Reference helpdesk No. 28439

	4.9					Ervin				2015.05.31 15:30
	Added condition that checks if the substitute of the original assignee is equal to the originator of the leave request.
	If true, then assign the request to the Supervisor of the original assignee

	5.0					Shoukhat			2015.06.09 09:10
	Modified the code to handle the new Recruitment Requisition

	5.1					Ervin				2015.07.30 12:30
	Check if the Supervisor of the original assignee is null

	5.2					Ervin				2016.03.15 13:43
	Implemented workflow substitute settings for Supplier Invoice Approval System

	5.3					Shoukhat			13-Mar-2016 1:00 PM
	Modified the code to handle Invoice Requisition

	5.4					Shoukhat			30-Mar-2017 10:25 AM
	Modified the code to retreive the value of @tempCEO variable from common admin instead of hard coding

	5.5					Ervin				17-Oct-2017 11:20 AM
	Replace the Cost Center Manager with the CFO if the originator employee's cost center is 7600

	5.6					Ervin				29-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	5.7					Shoukhat			25-Feb-2020 03:20 PM
	Modified the code to handle Employee Contract Renewal Requisition

	5.8					Ervin				24-Aug-2021 03:00 PM
	Implemented a new logic that will bypass the approval process if the Originator is the CRO as per HR request

	5.9					Ervin				12-Jun-2022 13:41
	Converted the value of "@distMemEmpEmail" parameter to empty string if it's null

	6.0					Ervin				30-Aug-2023 09:52 AM
    Modified code to implement the CEA workflow
****************************************************************************************************************************************************************************/

ALTER PROCEDURE secuser.pr_SetCurrentDistributionMember
(
	@reqType				INT,
	@reqTypeNo				INT,
	@actionType				INT,
	@distMemDistListID		INT,
	@distMemRoutineSeq		INT,
	@createdModifiedBy		INT,
	@retError				INT OUTPUT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SELECT @RETURN_OK			= 0
	SELECT @RETURN_ERROR		= -1

	-- Initialize output
	SELECT @retError = @RETURN_OK

	-- Member Type
	DECLARE @MEMBER_TYPE_SUPERINTENDENT varchar(10)
	DECLARE @MEMBER_TYPE_COST_CENTER_HEAD varchar(10)
	DECLARE @MEMBER_TYPE_INDIVIDUAL_USER varchar(10)
	DECLARE @MEMBER_TYPE_USER varchar(10)
	DECLARE @MEMBER_TYPE_DISTRIBUTION_GROUP varchar(10)
	DECLARE @MEMBER_TYPE_IMMEDIATE_SUPERVISOR varchar(10)
	DECLARE @MEMBER_TYPE_PARAMETER varchar(10)
	DECLARE @WFObjectCode varchar(20)

	SELECT @MEMBER_TYPE_SUPERINTENDENT			= 'SINT'
	SELECT @MEMBER_TYPE_COST_CENTER_HEAD		= 'CCH'
	SELECT @MEMBER_TYPE_INDIVIDUAL_USER			= 'INVEMP'
	SELECT @MEMBER_TYPE_USER					= 'USR'
	SELECT @MEMBER_TYPE_DISTRIBUTION_GROUP		= 'DISTGRP'
	SELECT @MEMBER_TYPE_IMMEDIATE_SUPERVISOR	= 'IMSUPERV'
	SELECT @MEMBER_TYPE_PARAMETER				= 'PARAM'
	SELECT @WFObjectCode						= ''

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_TSR int
	DECLARE @REQUEST_TYPE_PAF int
	DECLARE @REQUEST_TYPE_EPA int
	DECLARE @REQUEST_TYPE_CLRFRM int
	DECLARE @REQUEST_TYPE_RR int		--Ver 5.0
	DECLARE @REQUEST_TYPE_SIA INT		--Rev. #5.2
	DECLARE @REQUEST_TYPE_PROBY INT		--Rev. #5.6
	DECLARE @REQUEST_TYPE_ECR int	    --ver 5.7
	DECLARE @REQUEST_TYPE_CEA INT		--Rev. #6.0

	SELECT @REQUEST_TYPE_LEAVE	= 4
	SELECT @REQUEST_TYPE_PR		= 5
	SELECT @REQUEST_TYPE_TSR	= 6
	SELECT @REQUEST_TYPE_PAF	= 7
	SELECT @REQUEST_TYPE_EPA	= 11
	SELECT @REQUEST_TYPE_CLRFRM	= 16
	SELECT @REQUEST_TYPE_RR		= 18	--Ver 5.0
	SELECT @REQUEST_TYPE_SIA	= 19	--Rev. #5.2
	SELECT @REQUEST_TYPE_ECR	= 20	--ver 5.7
	SELECT @REQUEST_TYPE_PROBY	= 21	--Rev. #5.6
	SELECT @REQUEST_TYPE_CEA	= 22	--Rev. #6.0

	-- Define Action Type
	DECLARE @ACTION_TYPE_APPROVER int
	DECLARE @ACTION_TYPE_SERVICE_PROVIDER int
	DECLARE @SERV_TYPE_VALIDATOR int

	SELECT @ACTION_TYPE_APPROVER = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'APP'

	SELECT @ACTION_TYPE_SERVICE_PROVIDER = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'SERVPROV'

	SELECT @SERV_TYPE_VALIDATOR = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'VAL'

	-- Define Approval Setting
	DECLARE @APPROVAL_PRIMARY tinyint
	DECLARE @APPROVAL_AT_LEAST_ONE tinyint
	DECLARE @APPROVAL_ALL_APPROVERS tinyint

	SELECT @APPROVAL_PRIMARY		= 1
	SELECT @APPROVAL_AT_LEAST_ONE	= 2
	SELECT @APPROVAL_ALL_APPROVERS	= 3

	-- Declare necessary variables
	DECLARE @distMemID int
	DECLARE @distMemType int
	DECLARE @distMemEmpNo int
	DECLARE @distMemEmpName varchar(50)
	DECLARE @distMemEmpEmail varchar(150)
	DECLARE @distMemPrimary bit
	DECLARE @distMemApproval tinyint
	DECLARE @distMemThreshold int
	DECLARE @distMemEscalate int
	DECLARE @distMemIgnoreOL bit
	DECLARE @distMemSeq int
	DECLARE @distMemStatusID int
	DECLARE @distMemIncluded bit
	DECLARE @memberTypeCode varchar(10)
	DECLARE @historyDate datetime
	DECLARE @statusDesc varchar(300)
	DECLARE @statusHandlingCode	VARCHAR(50)
	DECLARE @autoApprove bit
	DECLARE @byPass bit
	DECLARE @reqTypeOwner int
	DECLARE @reqTypeOwnerCostCenter varchar(12)
	DECLARE @reqTypeChargedCostCenter varchar(12)	
	DECLARE @createdModifiedName VARCHAR(50) = ''
	
	DECLARE @alreadyInTheList bit
	SELECT @alreadyInTheList = 0

	DECLARE @tempCEO INT
    DECLARE @tempCRO INT
	DECLARE @ownerCEO bit	

	-- ver 5.4 Start
    SELECT  @tempCEO = b.DistMemEmpNo
    FROM    [secuser].[GenPurposeDistributionList] a WITH (NOLOCK)
            INNER  JOIN [secuser].[GenPurposeDistributionMember] b WITH (NOLOCK) ON a.DistListID = b.DistMemDistListID
    WHERE   a.DistListCode = 'CEO';
	-- ver 5.4 End

	--Rev. #5.8 - Start
	SELECT  @tempCRO = b.DistMemEmpNo
    FROM    secuser.GenPurposeDistributionList a WITH (NOLOCK)
            INNER  JOIN secuser.GenPurposeDistributionMember b WITH (NOLOCK) ON a.DistListID = b.DistMemDistListID
    WHERE   a.DistListCode = 'CRO'
	--Rev. #5.8 - END

	SELECT @ownerCEO	= 0

	-- Set the maximum days on leave
	DECLARE @MAX_LEAVE_DAYS int
	--SELECT @MAX_LEAVE_DAYS = 2
	SELECT @MAX_LEAVE_DAYS = -1

	-- Get the current date
	DECLARE @currentDate smalldatetime
	SELECT @currentDate = CONVERT(smalldatetime, CONVERT(varchar(10), GETDATE(), 101))

	DECLARE @fromDate smalldatetime
	DECLARE @toDate smalldatetime
	DECLARE @duration int

	DECLARE @count int
	DECLARE @level int

	SELECT @level = 1

	DECLARE @distMemByPass bit
	SELECT @distMemByPass = 0

	--Declare variable that will store the Employee information of the Original Assignee that was being substituted
	DECLARE @substitutedEmpNo		int,
			@substitutedEmpName		varchar(50), 
			@substitutedEmpEmail	varchar(50),
			@SubstituteEmpNo		int

	-- End of necessary variables		

	-- Reset previous current Distribution Members
	UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0
		WHERE CurrentDistMemRoutineSeq = @distMemRoutineSeq - 1 AND
			CurrentDistMemReqType = @reqType AND CurrentDistMemReqType = @reqTypeNo AND
			CurrentDistMemActionType = @actionType

	IF @@ERROR = @RETURN_OK
	BEGIN

		-- Update the Progress Status of Distribution Member table
		EXEC secuser.pr_UpdateDistributionMemberProgressStatus @reqType, @reqTypeNo, @distMemRoutineSeq,
			@retError output

		IF @retError = @RETURN_OK
		BEGIN

			-- Create a temporary table to hold all Distribution List
	--		CREATE TABLE TempDistributionList(
	--			TempLevel int,
	--			TempDistListID int,
	--			TempDistMemID int NULL DEFAULT 0,
	--			TempAnotherDistListID int NULL DEFAULT 0,
	--			TempDistMemPrimary bit NULL DEFAULT 0,
	--			TempDistMemApproval tinyint NULL DEFAULT 0,
	--			TempDistMemRoutineSeq int NULL DEFAULT 0,
	--			TempDistMemSeq int NULL DEFAULT 0)

			-- Delete existing record first
			--DELETE secuser.TempDistributionList
			--	WHERE TempReqType = @reqType AND TempReqTypeNo = @reqTypeNo

			---- Insert the first Distribution List
			--INSERT INTO secuser.TempDistributionList(TempReqType, TempReqTypeNo, TempLevel, TempDistListID)
			--	VALUES(@reqType, @reqTypeNo, @level, @distMemDistListID)

			---- Check if there are Distribution List from the Distribution Member
			--SELECT @count = COUNT(1)
			--	FROM secuser.DistributionMember AS a
			--	WHERE a.DistMemAnotherDistListID > 0 AND a.DistMemDistListID = @distMemDistListID

			---- Loop if there are Distribution List
			--WHILE @count > 0 AND @retError = @RETURN_OK
			--BEGIN

			--	-- Increment level
			--	SELECT @level = @level + 1

			--	-- Insert into temporary table
			--	INSERT INTO secuser.TempDistributionList(TempReqType, TempReqTypeNo,
			--			TempLevel, TempDistListID, TempDistMemID, TempAnotherDistListID,
			--			TempDistMemPrimary, TempDistMemApproval, TempDistMemRoutineSeq, TempDistMemSeq)
			--		SELECT @reqType, @reqTypeNo, @level, a.DistMemDistListID, a.DistMemID, a.DistMemAnotherDistListID, 
			--				CASE
			--					WHEN b.TempLevel = 1 THEN a.DistMemPrimary
			--					ELSE b.TempDistMemPrimary
			--				END,
			--				CASE
			--					WHEN b.TempLevel = 1 THEN a.DistMemApproval
			--					ELSE b.TempDistMemApproval
			--				END,
			--				CASE
			--					WHEN b.TempLevel = 1 THEN a.DistMemRoutineSeq
			--					ELSE b.TempDistMemRoutineSeq
			--				END,
			--				CASE
			--					WHEN b.TempLevel = 1 THEN a.DistMemSeq
			--					ELSE b.TempDistMemSeq
			--				END
			--			FROM secuser.DistributionMember AS a INNER JOIN
			--				secuser.TempDistributionList AS b ON a.DistMemDistListID = b.TempDistListID AND
			--					b.TempLevel = @level - 1 AND (a.DistMemRoutineSeq = @distMemRoutineSeq OR b.TempLevel > 1) LEFT JOIN
			--				secuser.GenPurposeDistributionMember AS c ON a.DistMemAnotherDistListIDOrig = c.DistMemDistListID
			--			WHERE b.TempReqType = @reqType AND b.TempReqTypeNo = @reqTypeNo AND a.DistMemAnotherDistListID > 0 AND
			--				a.DistMemAnotherDistListID NOT IN (SELECT b.TempDistListID
			--											FROM secuser.TempDistributionList AS b)

			--	-- Check for error
			--	IF @@ERROR = @RETURN_OK
			--	BEGIN

			--		-- Check if there are still Distribution List
			--		SELECT @count = COUNT(1)
			--			FROM secuser.DistributionMember AS a INNER JOIN
			--				secuser.TempDistributionList AS b ON (a.DistMemDistListID = b.TempDistListID AND a.DistMemDistListID = b.TempAnotherDistListID) AND
			--					b.TempLevel = @level AND (a.DistMemRoutineSeq = @distMemRoutineSeq OR b.TempLevel > 1)
			--			WHERE a.DistMemAnotherDistListID > 0

			--	END

			--	ELSE
			--		SELECT @retError = @RETURN_ERROR

			--END

			-- Retrieve all the current distribution members
			DECLARE distMemCursor CURSOR READ_ONLY FOR
			SELECT a.DistMemID, a.DistMemType,
					CASE WHEN a.DistMemAnotherDistListID = 0 THEN a.DistMemEmpNo
						WHEN c.DistMemEmpNo IS NULL OR c.DistMemEmpNo = 0 THEN b.DistMemEmpNo
						ELSE c.DistMemEmpNo
					END AS DistMemEmpNo,
					CASE WHEN a.DistMemAnotherDistListID = 0 THEN a.DistMemEmpName
						WHEN c.DistMemEmpNo IS NULL OR c.DistMemEmpNo = 0 THEN b.DistMemEmpName
						ELSE c.DistMemEmpName
					END AS DistMemEmpName,
					CASE WHEN a.DistMemAnotherDistListID = 0 THEN a.DistMemEmpEmail
						WHEN c.DistMemEmpNo IS NULL OR c.DistMemEmpNo = 0 THEN b.DistMemEmpEmail
						ELSE c.DistMemEmpEmail
					END AS DistMemEmpEmail,
					a.DistMemPrimary, a.DistMemApproval, a.DistMemThreshold, a.DistMemEscalate, a.DistMemIgnoreOL,
					a.DistMemRoutineSeq, a.DistMemSeq,
					d.UDCCode
				FROM secuser.DistributionMember AS a WITH (NOLOCK) LEFT JOIN
					secuser.DistributionMember AS b WITH (NOLOCK) ON a.DistMemAnotherDistListID = b.DistMemDistListID LEFT JOIN
					secuser.GenPurposeDistributionMember AS c WITH (NOLOCK) ON a.DistMemAnotherDistListIDOrig = c.DistMemDistListID LEFT JOIN
					secuser.UserDefinedCode AS d WITH (NOLOCK) ON a.DistMemType = d.UDCID
				WHERE a.DistMemDistListID = @distMemDistListID AND a.DistMemRoutineSeq = @distMemRoutineSeq
				ORDER BY a.DistMemRoutineSeq, a.DistMemPrimary DESC, a.DistMemSeq
			--SELECT CASE
			--			WHEN a.TempAnotherDistListID = 0 THEN  c.DistMemID
			--			ELSE a.TempDistMemID
			--		END,
			--		c.DistMemType,
			--		c.DistMemEmpNo, c.DistMemEmpName, c.DistMemEmpEmail,
			--		CASE
			--			WHEN a.TempDistMemID = 0 THEN c.DistMemPrimary
			--			ELSE a.TempDistMemPrimary
			--		END AS DistMemPrimary,
			--		CASE
			--			WHEN a.TempDistMemID = 0 THEN c.DistMemApproval
			--			ELSE a.TempDistMemApproval
			--		END AS DistMemApproval,
			--		c.DistMemThreshold, c.DistMemEscalate, c.DistMemIgnoreOL,
			--		CASE
			--			WHEN a.TempDistMemID = 0 THEN c.DistMemRoutineSeq
			--			ELSE a.TempDistMemRoutineSeq
			--		END AS DistMemRoutineSeq,
			--		CASE
			--			WHEN a.TempDistMemID = 0 THEN c.DistMemSeq
			--			ELSE a.TempDistMemSeq
			--		END AS DistMemSeq,
			--		d.UDCCode
			--	FROM secuser.TempDistributionList AS a INNER JOIN
			--		secuser.DistributionList AS b ON (a.TempDistListID = b.DistListID AND a.TempAnotherDistListID = 0) OR
			--			a.TempAnotherDistListID = b.DistListID INNER JOIN
			--		secuser.DistributionMember AS c ON b.DistListID = c.DistMemDistListID AND c.DistMemAnotherDistListID = 0 AND
			--			(c.DistMemRoutineSeq = @distMemRoutineSeq OR a.TempLevel > 1) INNER JOIN
			--		secuser.UserDefinedCode AS d ON c.DistMemType = d.UDCID
			--	WHERE a.TempReqType = @reqType AND a.TempReqTypeNo = @reqTypeNo
			--	ORDER BY DistMemRoutineSeq, DistMemPrimary DESC, DistMemSeq, a.TempLevel

			-- Open the Distribution Member Cursor and fetch the data
			OPEN distMemCursor
			FETCH NEXT FROM distMemCursor
			INTO @distMemID, @distMemType,
				@distMemEmpNo, @distMemEmpName, @distMemEmpEmail,
				@distMemPrimary, @distMemApproval, @distMemThreshold, @distMemEscalate, @distMemIgnoreOL,
				@distMemRoutineSeq, @distMemSeq,
				@memberTypeCode

			WHILE @@FETCH_STATUS = 0 AND @retError = @RETURN_OK
			BEGIN

				-- Reset Substitute employee details
				SELECT	@substitutedEmpNo		= 0,
						@substitutedEmpName		= '',
						@substitutedEmpEmail	= '',
						@SubstituteEmpNo		= 0

				-- Retrieve the owner of the request
				IF @reqType = @REQUEST_TYPE_LEAVE
					SELECT @reqTypeOwner = a.EmpNo, @reqTypeOwnerCostCenter = a.BusinessUnit
						FROM secuser.LeaveRequisition AS a WITH (NOLOCK)
						WHERE a.RequisitionNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_PR
					SELECT @reqTypeOwner = a.PREmpNo, @reqTypeOwnerCostCenter = secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter)--b.CostCenter
						FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PREmpNo = b.EmpNo
						WHERE a.PRDocNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_TSR
					SELECT @reqTypeOwner = a.TSREmpNo, @reqTypeOwnerCostCenter = secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter)--b.CostCenter
						FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.TSREmpNo = b.EmpNo
						WHERE a.TSRNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_PAF
					SELECT @reqTypeOwner = a.PAFEmpNo,
							@reqTypeOwnerCostCenter = (CASE WHEN a.PAFNewCostCenter = 1 THEN LTRIM(RTRIM(PAMCU))
															ELSE b.CostCenter END)
															--ELSE secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter) END)
						FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PAFEmpNo = b.EmpNo INNER JOIN
							secuser.F55PAF AS c WITH (NOLOCK) ON a.PAFReqTypeCode = c.PAG55PAFP AND a.PAFAutoID = c.PAG55AUTO AND a.PAFEmpNo = c.PAAN8 AND
										a.PAFEffectiveDate = c.PADEF
						WHERE a.PAFNo = @reqTypeNo
	--				SELECT @reqTypeOwner = a.PAFEmpNo, @reqTypeOwnerCostCenter = secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter)
	--					FROM secuser.PAFWF AS a INNER JOIN
	--						secuser.EmployeeMaster AS b ON a.PAFEmpNo = b.EmpNo
	--					WHERE a.PAFNo = @reqTypeNo
	--				SELECT @reqTypeOwner = a.PAFEmpNo, @reqTypeOwnerCostCenter = a.PAFEmpCostCenter
	--					FROM secuser.PAFWF AS a
	--					WHERE a.PAFNo = @reqTypeNo

				--Start of Rev. #5.6
				ELSE IF @reqType = @REQUEST_TYPE_PROBY
				BEGIN
                
					SELECT	@reqTypeOwner = a.PAREmpNo, 
							@reqTypeOwnerCostCenter = a.PAREmpCostCenter
					FROM secuser.ProbationaryRequisitionWF a WITH (NOLOCK)
					WHERE a.PARRequisitionNo = @reqTypeNo
				END 
				--End of Rev. #5.6

				ELSE IF @reqType = @REQUEST_TYPE_EPA
					SELECT @reqTypeOwner = a.EPAEmpNo, @reqTypeOwnerCostCenter = b.CostCenter--secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter)
						FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.EPAEmpNo = b.EmpNo
						WHERE a.EPANo = @reqTypeNo
	--				SELECT @reqTypeOwner = a.EPAEmpNo, @reqTypeOwnerCostCenter = a.EPAEmpCostCenter
	--					FROM secuser.EPAWF AS a
	--					WHERE a.EPANo = @reqTypeNo

	--				SELECT @reqTypeOwner = a.PREmpNo, @reqTypeOwnerCostCenter = a.PRCostCenter
	--					FROM secuser.PurchaseRequisitionWF AS a
	--					WHERE a.PRDocNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
					SELECT @reqTypeOwner = a.ClrFormEmpNo, @reqTypeOwnerCostCenter = b.CostCenter--secuser.CurrentCostCenter(b.CostCenter, b.WorkCostCenter)
						FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.ClrFormEmpNo = b.EmpNo
						WHERE a.ClrFormNo = @reqTypeNo

				-- *** ver 5.0 Start
				ELSE IF @reqType = @REQUEST_TYPE_RR
					SELECT @reqTypeOwner = a.RRCreatedBy, @reqTypeOwnerCostCenter = a.RRCostCenter
						FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) 
						WHERE a.RRNo = @reqTypeNo
				-- *** ver 5.0 End

				-- *** ver 5.3 Start
				ELSE IF @reqType = @REQUEST_TYPE_SIA
					SELECT @reqTypeOwner = a.IRCreatedByEmpNo, @reqTypeOwnerCostCenter = a.IRCostCenter
						FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) 
						WHERE a.IRNo = @reqTypeNo
				-- *** ver 5.3 End

				-- *** ver 5.7 Start
				ELSE IF @reqType = @REQUEST_TYPE_ECR
					SELECT @reqTypeOwner = a.ECREmpNo, @reqTypeOwnerCostCenter = a.ECRCostCenter
						FROM secuser.EmployeeContractRenewalWF AS a WITH (NOLOCK) 
						WHERE a.ECRNo = @reqTypeNo 
				-- *** ver 5.7 End

				-- *** ver 6.0 Start
				ELSE IF @reqType = @REQUEST_TYPE_CEA
					SELECT @reqTypeOwner = a.CEAEmpNo, @reqTypeOwnerCostCenter = RTRIM(a.CEACostCenter)
					FROM secuser.CEAWF AS a WITH (NOLOCK) 
					WHERE a.CEARequisitionNo = @reqTypeNo 
				-- *** ver 6.0 End

				-- Retrieve the cost center head or superintendent
				IF	@memberTypeCode = @MEMBER_TYPE_COST_CENTER_HEAD OR
					@memberTypeCode = @MEMBER_TYPE_SUPERINTENDENT
				BEGIN

					-- SAK: Modification to get charged cost center Start
					IF @reqType = @REQUEST_TYPE_PR AND EXISTS(SELECT a.PRDiffCostCenter FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) WHERE a.PRDocNo = @reqTypeNo AND a.PRDiffCostCenter = 1)
					BEGIN
							--Get the charged cost center of the PO
							SELECT @reqTypeChargedCostCenter =  PRChargeCostCenter FROM secuser.PurchaseRequisitionWF WITH (NOLOCK) WHERE PRDocNo = @reqTypeNo

							-- Find the charged cost center approver
							EXEC secuser.pr_GetCostCenterApprover @memberTypeCode OUTPUT,
								@reqTypeOwner, @reqTypeChargedCostCenter,
								@distMemEmpNo OUTPUT, @distMemEmpName OUTPUT, @distMemEmpEmail OUTPUT
					END
					-- *** ver 5.3 Start
					ELSE IF @reqType = @REQUEST_TYPE_SIA AND EXISTS(SELECT a.IRDiffCostCenter FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) WHERE a.IRNo = @reqTypeNo AND a.IRDiffCostCenter = 1)
					BEGIN
							--Get the charged cost center of the Invoice Requisition
							SELECT @reqTypeChargedCostCenter =  IRChargedCostCenter FROM secuser.InvoiceRequisitionWF WITH (NOLOCK) WHERE IRNo = @reqTypeNo

							-- Find the charged cost center approver
							EXEC secuser.pr_GetCostCenterApprover @memberTypeCode OUTPUT,
								@reqTypeOwner, @reqTypeChargedCostCenter,
								@distMemEmpNo OUTPUT, @distMemEmpName OUTPUT, @distMemEmpEmail OUTPUT
					END
					-- *** ver 5.3 End
					ELSE
					BEGIN
							-- Find the cost center approver
							EXEC secuser.pr_GetCostCenterApprover @memberTypeCode OUTPUT,
								@reqTypeOwner, @reqTypeOwnerCostCenter,
								@distMemEmpNo OUTPUT, @distMemEmpName OUTPUT, @distMemEmpEmail OUTPUT
					END
					-- SAK: Modification to get charged cost center End

					--Start of Rev. #5.5 - Replace the Cost Center Manager with the CFO if cost center is 7600
					IF	@memberTypeCode = @MEMBER_TYPE_COST_CENTER_HEAD AND
						@reqType = @REQUEST_TYPE_PAF AND
                        RTRIM(@reqTypeOwnerCostCenter) = '7600'
					BEGIN

						SELECT	@distMemEmpNo = a.DistMemEmpNo,
								@distMemEmpName = RTRIM(a.DistMemEmpName),
								@distMemEmpEmail = RTRIM(a.DistMemEmpEmail)
						FROM secuser.GenPurposeDistributionMember a WITH (NOLOCK)
						WHERE DistMemDistListID = 
						(
							SELECT TOP 1 DistListID 
							FROM secuser.GenPurposeDistributionList WITH (NOLOCK) 
							WHERE UPPER(RTRIM(DistListCode)) = 'CFO'
						)
                    END 
					--End of Rev. #5.5
				END

				-- Retrieve The immediate supervisor
				ELSE IF @memberTypeCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR	
					--Note: If the Supervisor is inactive, then the workflow will fetch the Superintendent
					SELECT @distMemEmpNo = (CASE
								WHEN (ISNUMERIC(b.Status) = 1 OR b.Status = 'I') THEN a.SupervisorNo
								ELSE c.SuperintendentNo
							END),
							@distMemEmpName = (CASE
								WHEN (ISNUMERIC(b.Status) = 1 OR b.Status = 'I') THEN b.EmpName
								ELSE d.EmpName
							END), @distMemEmpEmail = ''
						FROM secuser.EmployeeMaster AS a WITH (NOLOCK) LEFT JOIN
							secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo LEFT JOIN
							secuser.CostCenter AS c WITH (NOLOCK) ON a.CostCenter = c.CostCenter LEFT JOIN
							secuser.EmployeeMaster AS d WITH (NOLOCK) ON c.SuperintendentNo = d.EmpNo
						WHERE a.EmpNo = @reqTypeOwner

	--				SELECT @distMemEmpNo = a.SupervisorNo, @distMemEmpName = b.EmpName, @distMemEmpEmail = ''
	--					FROM secuser.EmployeeMaster AS a INNER JOIN
	--						secuser.EmployeeMaster AS b ON a.SupervisorNo = b.EmpNo
	--					WHERE a.EmpNo = @reqTypeOwner

				-- Retrieve the actual employee based on the parameter
				ELSE IF @memberTypeCode = @MEMBER_TYPE_PARAMETER
					SELECT @distMemEmpNo = c.EmpNo, @distMemEmpName = c.EmpName, @distMemEmpEmail = ''
						FROM secuser.ProcessWF AS a WITH (NOLOCK) INNER JOIN
							secuser.TransParameter AS b WITH (NOLOCK) ON a.ProcessID = b.ParamProcessID INNER JOIN
							secuser.EmployeeMaster AS c WITH (NOLOCK) ON CONVERT(INT, b.ParamValue) = c.EmpNo
						WHERE a.ProcessReqType = @reqType AND a.ProcessReqTypeNo = @reqTypeNo AND b.ParamName = @distMemEmpName

				-- Set the flag and reset the from date
				SELECT @distMemIncluded	= 1
				SELECT @fromDate		= NULL

				-- Check the Action Threshold
				EXEC secuser.pr_GetActionThreshold @reqType, @reqTypeNo, @distMemID, @distMemIncluded output

				-- If Included
				IF @distMemIncluded = 1
				BEGIN

					-- Check the availability of the member
	--				SELECT @toDate = a.ToDate
	--					FROM secuser.EmployeeAvailability AS a
	--					WHERE a.EmpNo = @distMemEmpNo AND
	--						@currentDate >= a.FromDate AND @currentDate <= a.ToDate
					SELECT @toDate = NULL
					SELECT TOP 1 @toDate = a.ToDate
						FROM (SELECT CAST(a.LRAN8 AS int) AS EmpNo,
									dbo.ConvertFromJulian(a.LRY58VCOFD) AS FromDate,
									dbo.ConvertFromJulian(a.LRY58VCOTD) AS ToDate,
									CAST(a.LRY58VCVCD AS char(3))AS LeaveCode,
									CAST(a.LRY58VCVDR AS int) / 10000 AS Duration,
									'' AS Reason
								FROM secuser.F58LV13 AS a WITH (NOLOCK)
								WHERE a.LRY58VCAFG IN ('A', 'N') AND dbo.ConvertToJulian(@currentDate) >= a.LRY58VCOFD AND
									a.LRY58VCOTD >= dbo.ConvertToJulian(@currentDate) AND a.LRAN8 = @distMemEmpNo
							UNION
							SELECT DISTINCT a.EmpNo,
									a.EffectiveDate AS FromDate,
									a.EndingDate AS ToDate,
									a.AbsenceReasonCode AS LeaveCode,
									DATEDIFF(dd, a.EffectiveDate, a.EndingDate) +  1 AS Duration,
									b.DRDL01 AS Reason
								FROM tas2.tas.Tran_Absence AS a WITH (NOLOCK) INNER JOIN
									secuser.F0005 AS b WITH (NOLOCK) ON a.AbsenceReasonCode = LTRIM(b.DRKY) AND
										--SUBSTRING(b.DRDL02,1,2) IN ('XL  ','OS  ','ML  ','LF  ','BT  ','DO  ','FT  ') AND
										LTRIM(RTRIM(b.DRKY)) IN ('XL','OS','ML','LF','BT','DO','FT') AND
										b.DRSY = '55' AND b.DRRT = 'RA'
								WHERE dbo.ConvertToJulian(@currentDate) >= dbo.ConvertToJulian(a.EffectiveDate) AND dbo.ConvertToJulian(a.EndingDate) >= dbo.ConvertToJulian(@currentDate) AND
									a.EmpNo = @distMemEmpNo) AS a

					-- Compute the number of days
					IF @toDate IS NOT NULL
					BEGIN

						SELECT @duration = DATEDIFF(dd, @currentDate, @toDate)
						IF @duration > @MAX_LEAVE_DAYS AND @distMemIgnoreOL = 1
							SELECT @distMemIncluded = 0

						/**************************** Part of Revision No. 4.6 *******************************************************/
						--ELSE IF @duration > @MAX_LEAVE_DAYS
						--BEGIN

						--	-- Retrieve Distribution Member Alternate
						--	EXEC secuser.pr_GetDistributionMemberAlternate @distMemID,
						--		@distMemEmpNo output, @distMemEmpName output, @distMemEmpEmail output,
						--		@currentDate, @reqType, @reqTypeOwnerCostCenter, @MAX_LEAVE_DAYS

						--END
						/**************************** End of Revision No. 4.6 *******************************************************/
					END
				END

				-- Check the Action Type and set the initial Status
				IF @actionType = @ACTION_TYPE_APPROVER
				BEGIN

					-- Checks if request type is Clearance Form and
					IF @reqType = @REQUEST_TYPE_CLRFRM AND EXISTS(SELECT a.TranChkListEmpNo
																	FROM secuser.TransCheckList AS a WITH (NOLOCK)
																	WHERE a.TranChkListReqTypeNo = @reqTypeNo AND TranChkListRoutineNo = @distMemRoutineSeq AND
																		TranChkListEmpNo = @distMemEmpNo AND TranChkListActionType = 1)
					BEGIN

						-- Set initial status
						SELECT @distMemStatusID = a.UDCID, @statusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1
							FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
							WHERE a.UDCUDCGID = 9 AND a.UDCCode = '16'

						-- Sets to validator
						SET @actionType = @SERV_TYPE_VALIDATOR

					END

					ELSE
					BEGIN

						-- Set initial status
						SELECT @distMemStatusID = a.UDCID, @statusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1
							FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
							WHERE a.UDCUDCGID = 9 AND a.UDCCode = '05'

					END

					-- Check the approval type
					IF @distMemApproval = @APPROVAL_PRIMARY AND @distMemPrimary = 0
						SELECT @distMemIncluded = 0

				END

				ELSE IF @actionType = @ACTION_TYPE_SERVICE_PROVIDER
				BEGIN

					-- Set initial status
					SELECT @distMemStatusID = a.UDCID, @statusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1
						FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
						WHERE a.UDCUDCGID = 9 AND a.UDCCode = '10'

					-- Check the approval type
					IF @distMemApproval = @APPROVAL_PRIMARY AND @distMemPrimary = 0
						SELECT @distMemIncluded = 0

				END

				-- Validator
				ELSE
				BEGIN

					-- Set initial status
					SELECT @distMemStatusID = a.UDCID, @statusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1
						FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
						WHERE a.UDCUDCGID = 9 AND a.UDCCode = '16'

					-- Check the approval type
					IF @distMemApproval = @APPROVAL_PRIMARY AND @distMemPrimary = 0
						SELECT @distMemIncluded = 0

				END

				-- Include the Distribution Member -------------------------------------------------------------
				IF @distMemIncluded = 1
				BEGIN

					-- Retrieve the owner of the request
	--				IF @reqType = @REQUEST_TYPE_LEAVE
	--					SELECT @reqTypeOwner = a.EmpNo, @reqTypeOwnerCostCenter = a.BusinessUnit
	--						FROM secuser.LeaveRequisition AS a
	--						WHERE a.RequisitionNo = @reqTypeNo
	--
	--				-- Retrieve the cost center head or superintendent
	--				IF @memberTypeCode = @MEMBER_TYPE_COST_CENTER_HEAD OR
	--					@memberTypeCode = @MEMBER_TYPE_SUPERINTENDENT
	--				BEGIN
	--
	--					-- Find the cost center approver
	--					EXEC secuser.pr_GetCostCenterApprover @memberTypeCode output,
	--						@reqTypeOwner, @reqTypeOwnerCostCenter,
	--						@distMemEmpNo output, @distMemEmpName output, @distMemEmpEmail output
	--
	--				END
	--
	--				-- Retrieve The immediate supervisor
	--				ELSE IF @memberTypeCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR
	--					SELECT @distMemEmpNo = a.SupervisorNo, @distMemEmpName = b.EmpName, @distMemEmpEmail = ''
	--						FROM secuser.EmployeeMaster AS a INNER JOIN
	--							secuser.EmployeeMaster AS b ON a.SupervisorNo = b.EmpNo
	--						WHERE a.EmpNo = @reqTypeOwner

					/******************************************************************************************************************************************
						Fetch the current Distribution Member substitute if it's defined in the "Workflow Substitute Settings" form in ISMS
					*******************************************************************************************************************************************/
					-- Get the Workflow Request Type
					IF @reqType = @REQUEST_TYPE_LEAVE
						SET @WFObjectCode = 'WFLEAVE'

					ELSE IF @reqType = @REQUEST_TYPE_PR
						SET @WFObjectCode = 'WFPR'

					ELSE IF @reqType = @REQUEST_TYPE_TSR
						SET @WFObjectCode = 'WFTSR'

					ELSE IF @reqType = @REQUEST_TYPE_PAF
						SET @WFObjectCode = 'WFPAF'

					ELSE IF @reqType = @REQUEST_TYPE_PROBY
						SET @WFObjectCode = 'WFPAF'

					ELSE IF @reqType = @REQUEST_TYPE_EPA
						SET @WFObjectCode = 'WFEPA'

					ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
						SET @WFObjectCode = 'WFCLRFRM'

					ELSE IF @reqType = @REQUEST_TYPE_SIA	--Rev. #5.2
						SET @WFObjectCode = 'WFINVOICE'

					ELSE IF @reqType = @REQUEST_TYPE_CEA	--Rev. #6.0
						SET @WFObjectCode = 'WFCEA'

					-- Search for active substitute defined through the "Workflow Substitute Settings" form in ISMS
					IF EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter))
					BEGIN

						/*****************************************************************************
							Revision #4.9 - Check if substitute is equal to the originator
						******************************************************************************/
						IF @reqTypeOwner = (SELECT SubstituteEmpNo FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter))
						BEGIN

							--Rev. #5.1 - Check if Supervisor is not null 
							IF ISNULL(
							(
								SELECT a.SupervisorNo
								FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
									LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
								WHERE a.EmpNo = @distMemEmpNo
							), 0) > 0
							BEGIN

								--Get the Supervisor of the original assignee
								SELECT	@distMemEmpNo	= a.SupervisorNo,
										@distMemEmpName = b.EmpName,
										@distMemEmpEmail = ''
								FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
									LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
								WHERE a.EmpNo = @distMemEmpNo
							END
						END

						ELSE
						BEGIN

							--Get the substitute
							SELECT	@distMemEmpNo = SubstituteEmpNo, 
									@distMemEmpName = SubstituteEmpName, 
									@distMemEmpEmail = SubstituteEmpEmail
							FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter)
						END
						/******************************************************************************/

						--Store original assignee info to the variables
						SELECT	@substitutedEmpNo = @distMemEmpNo,
								@substitutedEmpName	= @distMemEmpName,
								@substitutedEmpEmail = @distMemEmpEmail
					END

					ELSE
					BEGIN

						--Check if the current assignee has an approved leave request in GAP
						IF EXISTS (SELECT EmpNo FROM secuser.Vw_EmployeeAvailability
							WHERE EmpNo = @distMemEmpNo AND CONVERT(DATETIME, GETDATE(), 101) BETWEEN FromDate AND ToDate)
						BEGIN

							--The current assignee is on-leave, so get the substitute
							SELECT TOP 1 @SubstituteEmpNo = LRAN81
							FROM secuser.F58LV13 WITH (NOLOCK) 
							WHERE LRAN8 = @distMemEmpNo
								AND LTRIM(RTRIM(LRY58VCVCD)) = 'AL'								
								AND CONVERT(VARCHAR, GETDATE(), 12) BETWEEN CONVERT(VARCHAR, dbo.ConvertFromJulian(ISNULL(LRY58VCALF, LRY58VCOFD)), 12) AND CONVERT(VARCHAR, dbo.ConvertFromJulian(ISNULL(LRY58VCARD, LRY58VCOFD)), 12) 
								AND LRY58VCAFG IN ('A', 'N')	--Revision #4.5
							ORDER BY LRY58VCRQN DESC

							IF @SubstituteEmpNo > 0
							BEGIN

								/*****************************************************************************
									Revision #4.9 - Check if substitute is equal to the originator
								******************************************************************************/
								IF @reqTypeOwner = @SubstituteEmpNo
								BEGIN

									--Rev. #5.1 - Check if Supervisor is not null 
									IF ISNULL(
									(
										SELECT a.SupervisorNo
										FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
											LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
										WHERE a.EmpNo = @distMemEmpNo
									), 0) > 0
									BEGIN

										--Get the Supervisor of the original assignee
										SELECT	@distMemEmpNo	= a.SupervisorNo,
												@distMemEmpName = b.EmpName,
												@distMemEmpEmail = ''
										FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
											LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
										WHERE a.EmpNo = @distMemEmpNo
									END
								END

								ELSE
								BEGIN

									--Get the substitute specified in leave request
									SELECT	TOP 1 @distMemEmpNo = EmpNo, 
											@distMemEmpName = EmpName, 
											@distMemEmpEmail = RTRIM(b.EAEMAL)
									FROM secuser.EmployeeMasterGAP a WITH (NOLOCK)
										LEFT JOIN secuser.F01151 b WITH (NOLOCK) ON a.EmpNo = b.EAAN8
									WHERE a.EmpNo = @SubstituteEmpNo
								END
								/*******************************************************************************/

								--Store original assignee info to the variables
								SELECT	@substitutedEmpNo = @distMemEmpNo,
										@substitutedEmpName	= @distMemEmpName,
										@substitutedEmpEmail = @distMemEmpEmail
							END
						END
					END
					/************************** End of fetching the Substitute in the Workflow Substitute Settings *********************************************/


					-- Retrieve the Auto-Approve and By Pass flags
					SELECT @autoApprove	= 0
					SELECT @byPass		= 0
					SELECT @autoApprove = ISNULL(a.ActionAutoApprove, 0), @byPass = ISNULL(a.ActionByPass, 0)
								FROM secuser.ActivityAction AS a WITH (NOLOCK) INNER JOIN
									secuser.TransActivity AS b WITH (NOLOCK) ON a.ActionActID = b.ActID INNER JOIN
									secuser.ProcessWF AS c WITH (NOLOCK) ON b.ActProcessID = c.ProcessID
								WHERE a.ActionType = @ACTION_TYPE_APPROVER AND b.ActCurrent = 1 AND
									c.ProcessReqType = @reqType AND c.ProcessReqTypeNo = @reqTypeNo

					-- Start if Distribution Member Employee is not yet in the current list -----------------------
					IF NOT EXISTS(SELECT a.CurrentDistMemEmpNo
								  FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
								  WHERE a.CurrentDistMemReqType = @reqType 
										AND a.CurrentDistMemReqTypeNo = @reqTypeNo 
										AND a.CurrentDistMemActionType = @actionType 										
										--AND a.CurrentDistMemApproval = @distMemApproval 
										AND
										(
											a.CurrentDistMemEmpNo = @distMemEmpNo
											OR (a.CurrentDistMemEmpNo = @substitutedEmpNo AND ISNULL(@substitutedEmpNo, 0) > 0)
										)
								  )
					BEGIN

						--Rev. #5.8 - Start
						IF	@autoApprove = 0
							AND @actionType = @ACTION_TYPE_APPROVER
							AND (@reqTypeOwner > 0 AND @reqTypeOwner = @tempCRO)
						BEGIN

							--Bypass all approvals since the Originator is the CRO
							--SELECT @ownerCEO = 1
							SELECT @byPass = 1
                        END 
						----Rev. #5.8 - End

						ELSE
                        BEGIN
                        
							-- Checks if not auto approve and current approver is the owner of the request
							IF @autoApprove = 0 AND @distMemEmpNo = @reqTypeOwner AND
								@actionType = @ACTION_TYPE_APPROVER
							BEGIN

								-- *** SAK Start: Added to allow the originator to approve during non-stock approval of PO ***
								--IF @reqType <> @REQUEST_TYPE_PR AND 
								--		(SELECT PHDCTO FROM secuser.F4301 WHERE PHDOCO = @reqTypeNo) <> 'OP' AND
								--		(SELECT PROriginatorsApproval FROM secuser.PurchaseRequisitionWF WHERE PRDocNo = @reqTypeNo) <> 1		
								IF @reqType <> @REQUEST_TYPE_PR AND 
									EXISTS(SELECT a.PHDCTO FROM secuser.F4301 AS a WITH (NOLOCK) INNER JOIN
										secuser.PurchaseRequisitionWF AS b WITH (NOLOCK) ON a.PHDOCO= b.PRDocNo
									WHERE a.PHDOCO = @reqTypeNo AND a.PHDCTO <> 'OP' AND ISNULL(b.PROriginatorsApproval , 0) <> 1)						
								BEGIN							
									-- Find the immediate supervisor of the current distribution member
									IF EXISTS(SELECT a.EmpNo
												FROM secuser.EmployeeMaster AS a WITH (NOLOCK)
												WHERE a.EmpNo = @distMemEmpNo AND ISNULL(a.SupervisorNo, 0) <> 0) AND @distMemEmpNo <> @tempCEO
									BEGIN

										SELECT @distMemEmpNo = b.EmpNo, @distMemEmpName = b.EmpName, @distMemEmpEmail = ''
											FROM secuser.EmployeeMaster AS a WITH (NOLOCK) INNER JOIN
												secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo
											WHERE a.EmpNo = @distMemEmpNo

										/******************************************************************************************************************************************
											Fetch the substitute of the Immediate Supervisor if it's defined in the "Workflow Substitute Settings" form in ISMS
										*******************************************************************************************************************************************/
										-- Get the Workflow Request Type
										IF @reqType = @REQUEST_TYPE_LEAVE
											SET @WFObjectCode = 'WFLEAVE'

										ELSE IF @reqType = @REQUEST_TYPE_PR
											SET @WFObjectCode = 'WFPR'

										ELSE IF @reqType = @REQUEST_TYPE_TSR
											SET @WFObjectCode = 'WFTSR'

										ELSE IF @reqType = @REQUEST_TYPE_PAF
											SET @WFObjectCode = 'WFPAF'

										ELSE IF @reqType = @REQUEST_TYPE_PROBY
											SET @WFObjectCode = 'WFPAF'

										ELSE IF @reqType = @REQUEST_TYPE_EPA
											SET @WFObjectCode = 'WFEPA'

										ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
											SET @WFObjectCode = 'WFCLRFRM'

										ELSE IF @reqType = @REQUEST_TYPE_SIA	--Rev. #5.2
											SET @WFObjectCode = 'WFINVOICE'

										ELSE IF @reqType = @REQUEST_TYPE_CEA	--Rev. #6.0
											SET @WFObjectCode = 'WFCEA'

										-- Search for active substitute defined through the "Workflow Substitute Settings" form in ISMS
										IF EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter))
										BEGIN

											/*****************************************************************************
												Revision #4.9 - Check if substitute is equal to the originator
											******************************************************************************/
											IF @reqTypeOwner = (SELECT SubstituteEmpNo FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter))
											BEGIN

												--Rev. #5.1 - Check if Supervisor is not null 
												IF ISNULL(
												(
													SELECT a.SupervisorNo
													FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
														LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
													WHERE a.EmpNo = @distMemEmpNo
												), 0) > 0
												BEGIN

													--Get the Supervisor of the original assignee
													SELECT	@distMemEmpNo	= a.SupervisorNo,
															@distMemEmpName = b.EmpName,
															@distMemEmpEmail = ''
													FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
														LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
													WHERE a.EmpNo = @distMemEmpNo
												END
											END

											ELSE
											BEGIN

												--Get the substitute
												SELECT	@distMemEmpNo = SubstituteEmpNo, 
														@distMemEmpName = SubstituteEmpName, 
														@distMemEmpEmail = SubstituteEmpEmail
												FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@distMemEmpNo, @WFObjectCode, @reqTypeOwnerCostCenter)
											END

											--Store original assignee info to the variables
											SELECT	@substitutedEmpNo = @distMemEmpNo,
													@substitutedEmpName	= @distMemEmpName,
													@substitutedEmpEmail = @distMemEmpEmail
										END

										ELSE
										BEGIN

											--Check if the current assignee has an approved leave request in GAP
											IF EXISTS (SELECT EmpNo FROM secuser.Vw_EmployeeAvailability
												WHERE EmpNo = @distMemEmpNo AND CONVERT(DATETIME, GETDATE(), 101) BETWEEN FromDate AND ToDate)
											BEGIN

												--The current assignee is on-leave, so get the substitute
												SELECT @SubstituteEmpNo = LRAN81
												FROM secuser.F58LV13 WITH (NOLOCK) 
												WHERE LRAN8 = @distMemEmpNo
													AND LTRIM(RTRIM(LRY58VCVCD)) = 'AL'
													AND CONVERT(VARCHAR, GETDATE(), 12) BETWEEN CONVERT(VARCHAR, dbo.ConvertFromJulian(ISNULL(LRY58VCALF, LRY58VCOFD)), 12) AND CONVERT(VARCHAR, dbo.ConvertFromJulian(ISNULL(LRY58VCARD, LRY58VCOFD)), 12) 
													AND LRY58VCAFG IN ('A', 'N')	--Revision #4.5
												ORDER BY LRY58VCRQN DESC

												IF @SubstituteEmpNo > 0
												BEGIN

													/*****************************************************************************
														Revision #4.9 - Check if substitute is equal to the originator
													******************************************************************************/
													IF @reqTypeOwner = @SubstituteEmpNo
													BEGIN

														--Rev. #5.1 - Check if Supervisor is not null 
														IF ISNULL(
														(
															SELECT a.SupervisorNo
															FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
																LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
															WHERE a.EmpNo = @distMemEmpNo
														), 0) > 0
														BEGIN

															--Get the Supervisor of the original assignee
															SELECT	@distMemEmpNo	= a.SupervisorNo,
																	@distMemEmpName = b.EmpName,
																	@distMemEmpEmail = ''
															FROM secuser.EmployeeMaster AS a WITH (NOLOCK) 
																LEFT JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.SupervisorNo = b.EmpNo 
															WHERE a.EmpNo = @distMemEmpNo
														END
													END

													ELSE
													BEGIN

														--Get the substitute specified in the leave request
														SELECT TOP 1 @distMemEmpNo = EmpNo, 
																@distMemEmpName = EmpName, 
																@distMemEmpEmail = RTRIM(b.EAEMAL)
														FROM secuser.EmployeeMasterGAP a WITH (NOLOCK)
															LEFT JOIN secuser.F01151 b WITH (NOLOCK) ON a.EmpNo = b.EAAN8
														WHERE a.EmpNo = @SubstituteEmpNo
													END
													/******************************************************************************/

													--Store original assignee info to the variables
													SELECT	@substitutedEmpNo = @distMemEmpNo,
															@substitutedEmpName	= @distMemEmpName,
															@substitutedEmpEmail = @distMemEmpEmail
												END
											END
										END
										/************************** End of fetching the Substitute of the Immediate Supervisor in the Workflow Substitute Settings *********************************************/


										-- Checks if to be by passed
										IF @byPass = 1 AND EXISTS(SELECT a.CurrentDistMemEmpNo
																  FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
																  WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
																		a.CurrentDistMemActionType = @actionType 
																		AND
																		(
																			a.CurrentDistMemEmpNo = @distMemEmpNo
																			OR (a.CurrentDistMemEmpNo = @substitutedEmpNo AND ISNULL(@substitutedEmpNo, 0) > 0)
																		)
																 )
										BEGIN

											-- Add History Routine Record
											SELECT @historyDate = GETDATE()
											SELECT @statusDesc = 'Bypassed - ' + @distMemEmpName
											EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @statusDesc, @createdModifiedBy, '',
												@historyDate, @retError OUTPUT

										END

										-- Reset the bypass flag so the current assigned person can be added even though the activity can be bypassed
										ELSE 
											SELECT @byPass = 0

									END

									-- No immediate supervisor, so it's the CEO
									ELSE
										SELECT @ownerCEO = 1
								END
								-- *** SAK End:***
							END

							-- Reset the bypass flag so the current assigned person can be added even though the activity can be bypassed
							ELSE
								SELECT @byPass = 0		
						END 				

						-- Check if distribution member is the CEO
						IF @ownerCEO = 1
						BEGIN

							-- Update the status of the Current Distribution Member
							-- As well as the Employee Info if Cost Center Head
							UPDATE secuser.DistributionMember SET DistMemStatusID = (SELECT a.UDCID
																				FROM secuser.UserDefinedCode AS a
																				WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'),
									DistMemEmpNo = @distMemEmpNo, DistMemEmpName = @distMemEmpName,
									DistMemEmpEmail = @distMemEmpEmail
								WHERE DistMemID = @distMemID

							
							-- Checks for error
							IF @@ERROR = @RETURN_OK
							BEGIN

								-- Retrieve approve status
								DECLARE @reqStatusID int
								SELECT @reqStatusID = a.UDCID
									FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
									WHERE a.UDCUDCGID = 9 AND a.UDCCode = '120'

								-- Update the status of the request
								IF @reqType = @REQUEST_TYPE_LEAVE
									UPDATE secuser.LeaveRequisitionWF SET LeaveReqStatusID = @reqStatusID, LeaveReqStatusCode = '120',
											LeaveModifiedBy = @createdModifiedBy, LeaveModifiedName = '',
											LeaveModifiedEmail = '', LeaveModifiedDate = GETDATE()
										WHERE LeaveNo = @reqTypeNo

								ELSE IF @reqType = @REQUEST_TYPE_PR
									UPDATE secuser.PurchaseRequisitionWF SET PRReqStatusID = @reqStatusID, PRReqStatusCode = '120',
											PRModifiedBy = @createdModifiedBy, PRModifiedName = '',
											PRModifiedEmail = '', PRModifiedDate = GETDATE()
										WHERE PRDocNo = @reqTypeNo

								ELSE IF @reqType = @REQUEST_TYPE_TSR
									UPDATE secuser.TSRWF SET TSRReqStatusID = @reqStatusID, TSRReqStatusCode = '120',
											TSRModifiedBy = @createdModifiedBy, TSRModifiedName = '',
											TSRModifiedEmail = '', TSRModifiedDate = GETDATE()
										WHERE TSRNo = @reqTypeNo

								ELSE IF @reqType = @REQUEST_TYPE_PAF
									UPDATE secuser.PAFWF SET PAFReqStatusID = @reqStatusID, PAFReqStatusCode = '120',
											PAFModifiedBy = @createdModifiedBy, PAFModifiedName = '',
											PAFModifiedEmail = '', PAFModifiedDate = GETDATE()
										WHERE PAFNo = @reqTypeNo

								ELSE IF @reqType = @REQUEST_TYPE_ECR
									UPDATE secuser.EmployeeContractRenewalWF SET ECRStatusID = @reqStatusID, ECRStatusCode = '120',
											ECRLastModifiedBy = @createdModifiedBy, ECRLastModifiedDate = GETDATE()
										WHERE ECRNo = @reqTypeNo

								--Start of Rev. #5.6
								ELSE IF @reqType = @REQUEST_TYPE_PROBY
								BEGIN                                																				

									--Get the status details
									SELECT	@statusDesc= RTRIM(a.UDCDesc1),
											@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
									FROM secuser.UserDefinedCode a WITH (NOLOCK) 
									WHERE UDCUDCGID = 9 
										AND RTRIM(a.UDCCOde) = '120'

									UPDATE secuser.ProbationaryRequisitionWF 
									SET PARStatusID = @reqStatusID, 
										PARStatusCode = '120',
										PARStatusDesc = @statusDesc,
										PARStatusHandlingCode = @statusHandlingCode,
										PARLastModifiedByEmpNo = @createdModifiedBy, 
										PARLastModifiedByEmpName = '',
										PARLastModifiedByEmpEmail = secuser.fnGetEmployeeEmail(@createdModifiedBy), 
										PARLastModifiedDate = GETDATE()
									WHERE PARRequisitionNo = @reqTypeNo
								END 
								--End of Rev. #5.6

								--Start of Rev. #6.0
								ELSE IF @reqType = @REQUEST_TYPE_CEA
								BEGIN                                																				

									--Get the status details
									SELECT	@statusDesc= RTRIM(a.UDCDesc1),
											@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
									FROM secuser.UserDefinedCode a WITH (NOLOCK) 
									WHERE UDCUDCGID = 9 
										AND RTRIM(a.UDCCOde) = '120'

									--Get the employee name
									SELECT @createdModifiedName = rtrim(a.EmpName)
									FROM secuser.EmployeeMaster a
									WHERE a.EmpNo = @createdModifiedBy

									UPDATE secuser.CEAWF 
									SET CEAStatusID = @reqStatusID, 
										CEAStatusCode = '120',
										CEAStatusHandlingCode = @statusHandlingCode,
										CEAModifiedBy = @createdModifiedBy, 
										CEAModifiedName = @createdModifiedName,
										CEAModifiedEmail = secuser.fnGetEmployeeEmail(@createdModifiedBy), 
										CEAModifiedDate = GETDATE()
									WHERE CEARequisitionNo = @reqTypeNo
								END 
								--End of Rev. #6.0

								ELSE IF @reqType = @REQUEST_TYPE_EPA
									UPDATE secuser.EPAWF SET EPAReqStatusID = @reqStatusID, EPAReqStatusCode = '120',
											EPAModifiedBy = @createdModifiedBy, EPAModifiedName = '',
											EPAModifiedEmail = '', EPAModifiedDate = GETDATE()
										WHERE EPANo = @reqTypeNo

								ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
									UPDATE secuser.ClearanceFormWF SET ClrFormStatusID = @reqStatusID, ClrFormStatusCode = '120',
											ClrFormModifiedBy = @createdModifiedBy, ClrFormModifiedName = '',
											ClrFormModifiedEmail = '', ClrFormModifiedDate = GETDATE()
										WHERE ClrFormNo = @reqTypeNo

							END

							ELSE
								SELECT @retError = @RETURN_ERROR

						END

						ELSE IF @byPass = 0
						BEGIN

							/*********************************** Old code in getting the substitute is commented ******************************************************** 
								--Assigns the old requests to replacement employee for the requests being created before the master setup in common admin or EmployeeMaster
								IF EXISTS(SELECT TOP 1 DistMemID FROM secuser.DistributionMemberReplacement	
									WHERE DistMemFromEmpNo = @distMemEmpNo and isnull(IsEnabled,0) = 1)
								BEGIN
									SELECT	@distMemEmpNo = a.DistMemToEmpNo, 
											@distMemEmpName = b.EmpName, 
											@distMemEmpEmail = RTRIM(a.DistMemToEmpEmail)
									FROM secuser.DistributionMemberReplacement a
										INNER JOIN secuser.EmployeeMaster b ON a.DistMemToEmpNo = b.EmpNo
									WHERE 
										a.DistMemFromEmpNo = @distMemEmpNo
								END
							********************************************************************************************************************************************/


							-- Insert the current distribution member
							INSERT INTO secuser.CurrentDistributionMember(CurrentDistMemRefID, CurrentDistMemCurrent,
									CurrentDistMemReqType, CurrentDistMemReqTypeNo,
									CurrentDistMemEmpNo, CurrentDistMemEmpName, CurrentDistMemEmpEmail,
									CurrentDistMemActionType, CurrentDistMemApproval, CurrentDistMemRoutineSeq, CurrentDistMemStatusID,
									CurrentDistMemModifiedBy, CurrentDistMemModifiedDate)
								VALUES(@distMemID, 1, @reqType, @reqTypeNo,
									@distMemEmpNo, @distMemEmpName, ISNULL(@distMemEmpEmail, ''),	--Rev. #5.9
									@actionType, @distMemApproval, @distMemRoutineSeq, @distMemStatusID,
									@createdModifiedBy, GETDATE())

							IF @@ERROR = @RETURN_OK
							BEGIN

								-- Update the status of the Current Distribution Member
								-- As well as the Employee Info if Cost Center Head
								UPDATE secuser.DistributionMember SET DistMemStatusID = (SELECT a.UDCID
																					FROM secuser.UserDefinedCode AS a
																					WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'IN'),
										DistMemEmpNo = @distMemEmpNo, DistMemEmpName = @distMemEmpName,
										DistMemEmpEmail = @distMemEmpEmail
									WHERE DistMemID = @distMemID

								-- Checks for error
								IF @@ERROR = @RETURN_OK
								BEGIN

									-- Add History Routine Record
									SELECT @historyDate = GETDATE()
									SELECT @statusDesc = @statusDesc + ' (' + @distMemEmpName + ')'
									EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @statusDesc, @createdModifiedBy, '',
										@historyDate, @retError OUTPUT

								END

								ELSE
									SELECT @retError = @RETURN_ERROR

							END

							ELSE
								SELECT @retError = @RETURN_ERROR

						END
					END
					-- End if Distribution Member Employee is not yet in the current list -------------------------


					-- Start if the Distribution Member Employee is already in the current list -------------------
					ELSE
					BEGIN

						-- Checks if not to by pass
						IF @byPass = 0
						BEGIN
							
							/*********************************** Old code in getting the substitute ******************************************************** 
								--Assigns the old requests to replacement employee for the requests being created before the master setup in common admin or EmployeeMaster
								IF EXISTS(SELECT TOP 1 DistMemID FROM secuser.DistributionMemberReplacement	
									WHERE DistMemFromEmpNo = @distMemEmpNo and isnull(IsEnabled,0) = 1)
								BEGIN
									SELECT	@distMemEmpNo = a.DistMemToEmpNo, 
											@distMemEmpName = b.EmpName, 
											@distMemEmpEmail = RTRIM(a.DistMemToEmpEmail)
									FROM secuser.DistributionMemberReplacement a
										INNER JOIN secuser.EmployeeMaster b ON a.DistMemToEmpNo = b.EmpNo
									WHERE 
										a.DistMemFromEmpNo = @distMemEmpNo
								END
							*********************************************************************************************************************************************/
							
							IF ISNULL(@substitutedEmpNo, 0) = 0
							BEGIN

								UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 1,
										CurrentDistMemRoutineSeq = @distMemRoutineSeq, CurrentDistMemRefID = @distMemID,
										CurrentDistMemModifiedBy = @createdModifiedBy, CurrentDistMemModifiedDate = GETDATE()
									WHERE CurrentDistMemReqType = @reqType AND CurrentDistMemReqTypeNo = @reqTypeNo AND
										CurrentDistMemActionType = @actionType AND CurrentDistMemApproval = @distMemApproval AND
										CurrentDistMemEmpNo = @distMemEmpNo
							END
							ELSE
							BEGIN

								UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 1,
										CurrentDistMemRoutineSeq = @distMemRoutineSeq, CurrentDistMemRefID = @distMemID,
										CurrentDistMemModifiedBy = @createdModifiedBy, CurrentDistMemModifiedDate = GETDATE()
									WHERE CurrentDistMemReqType = @reqType AND CurrentDistMemReqTypeNo = @reqTypeNo AND
										CurrentDistMemActionType = @actionType AND CurrentDistMemApproval = @distMemApproval AND
										CurrentDistMemEmpNo = @substitutedEmpNo
							END

							IF @@ERROR = @RETURN_OK
							BEGIN

								-- Update the status of the Current Distribution Member
								-- As well as the Employee Info if Cost Center Superintendent / Head
								IF ISNULL(@substitutedEmpNo, 0) = 0
								BEGIN
								
									--No substitute
									UPDATE secuser.DistributionMember 
									SET DistMemStatusID = (SELECT a.UDCID FROM secuser.UserDefinedCode AS a WITH (NOLOCK) WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'IN'),
										DistMemEmpNo = @distMemEmpNo, 
										DistMemEmpName = @distMemEmpName,
										DistMemEmpEmail = @distMemEmpEmail
									WHERE DistMemID = @distMemID
								END
								ELSE
								BEGIN
									
									--Udate the original assignee info
									UPDATE secuser.DistributionMember 
									SET DistMemStatusID = (SELECT a.UDCID FROM secuser.UserDefinedCode AS a WITH (NOLOCK) WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'IN'),
										DistMemEmpNo = @substitutedEmpNo, 
										DistMemEmpName = @substitutedEmpName,
										DistMemEmpEmail = @substitutedEmpEmail
									WHERE DistMemID = @distMemID
								END

								-- Checks for error
								IF @@ERROR = @RETURN_OK
								BEGIN

									-- Add History Routine Record
									SELECT @historyDate = GETDATE()

									IF ISNULL(@substitutedEmpNo, 0) > 0 AND ISNULL(@substitutedEmpName, '') <> ''
										SET @distMemEmpName = RTRIM(@substitutedEmpName)

									SELECT @statusDesc = @statusDesc + ' (' + @distMemEmpName + ')'
									EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @statusDesc, @createdModifiedBy, '',
										@historyDate, @retError OUTPUT

								END

								ELSE
									SELECT @retError = @RETURN_ERROR

							END

							ELSE
								SELECT @retError = @RETURN_ERROR

						END

						ELSE
						BEGIN

							-- Add History Routine Record
							SELECT @historyDate = GETDATE()

							IF ISNULL(@substitutedEmpNo, 0) > 0 AND ISNULL(@substitutedEmpName, '') <> ''
								SET @distMemEmpName = RTRIM(@substitutedEmpName)

							SELECT @statusDesc = 'Bypassed - ' + @distMemEmpName
							EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @statusDesc, @createdModifiedBy, '',
								@historyDate, @retError output

							-- Set the by pass
							SELECT @distMemByPass = 1 

						END
					END
					-- End if the Distribution Member Employee is already in the current list ---------------------

				END
				-- End of including the Distribution Member ----------------------------------------------------

				-- Update the progress status
				ELSE
				BEGIN

					UPDATE secuser.DistributionMember SET DistMemStatusID = (SELECT a.UDCID
																		FROM secuser.UserDefinedCode AS a
																		WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'S')
						WHERE DistMemID = @distMemID

					-- Checks for error
					IF @@ERROR = @RETURN_OK
					BEGIN

						-- Add History Routine Record
						SELECT @historyDate = GETDATE()
						--SELECT @statusDesc = 'Bypassed - ' + @distMemEmpName + ' (Due to either on-leave or threshhold setup)'
						--EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @statusDesc, @createdModifiedBy, '',
						--	@historyDate, @retError output

					END

					ELSE
						SELECT @retError = @RETURN_ERROR

				END

				-- Fetch next data
				IF @retError = @RETURN_OK
				BEGIN

					FETCH NEXT FROM distMemCursor
					INTO @distMemID, @distMemType,
						@distMemEmpNo, @distMemEmpName, @distMemEmpEmail,
						@distMemPrimary, @distMemApproval, @distMemThreshold, @distMemEscalate,
						@distMemIgnoreOL, @distMemRoutineSeq, @distMemSeq,
						@memberTypeCode

				END
			END

			-- Close and deallocate
			CLOSE distMemCursor
			DEALLOCATE distMemCursor

			-- Checks if by passed and there's another member of the distribution group (Revision 2.5)
			IF (
					@distMemByPass = 1 
					OR NOT EXISTS
					(
						SELECT a.CurrentDistMemID
						FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
						WHERE a.CurrentDistMemReqType = @reqType 
							AND a.CurrentDistMemReqTypeNo = @reqTypeNo 
							AND a.CurrentDistMemCurrent = 1
					)
				) 
				AND EXISTS
				(
					SELECT a.DistMemID
					FROM secuser.DistributionMember AS a WITH (NOLOCK)
					WHERE a.DistMemDistListID = @distMemDistListID 
						AND a.DistMemRoutineSeq > @distMemRoutineSeq
				)
				AND @reqType <> @REQUEST_TYPE_PAF
			BEGIN

				-- Increment the routine sequence
				SELECT @distMemRoutineSeq = @distMemRoutineSeq + 1
				EXEC secuser.pr_SetCurrentDistributionMember @reqType, @reqTypeNo, @actionType, @distMemDistListID,
					@distMemRoutineSeq, @createdModifiedBy, @retError OUTPUT

			END
		END
	END

	ELSE
		SELECT @retError = @RETURN_ERROR

END


/*	Debugging:

	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10001757, 'WFLEAVE', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10003191, 'WFLEAVE', '')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10003191, '', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10003191, 'WFEPA', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10003512, 'WFEPA', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10001871, 'WFEPA', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10006141, 'WFEPA', '7600')
	SELECT * FROM Gen_Purpose.genuser.fnGetActiveSubstitute(10001168, 'WFEPA', '7600')

*/




