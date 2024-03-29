/*************************************************************************************************************************************************************************

Stored Procedure Name	:	secuser.pr_ApproveRejectServiceRequest
Description				:	This stored procedure creates a record if the Request has been approved or not.
                            It also updates the Status ID and Status Code of the Request, as well as the
                            status of the activity. If the request is approved, it assigned the Request
                            to the next approver

                            This SP is part of the Travel and Expense Management Module Project.

Created By				:	Noel G. Francisco
Date Created			:	08 January 2008

Parameters
    @reqType					:	The request type (1 - Expense, 2 - Travel)
    @reqTypeNo					:	The Request No
    @appApproved				:	Determines if the request is approved (1) or not (0)
    @appRemarks					:	The remark why the request is approved or not
    @actID						:	The activity id as reference, it will contain also the next activity in
                                    the workflow
    @actStatusID				:	The status of the activity
    @reqStatusID				:	The status of the request
    @reqStatusCode				:	The status code of the request
    @currentDistMemRoutineSeq	:	The current routine sequence
    @reqModifiedBy				:	The employee no. of the user who calls the SP
    @reqModifiedName			:	The employee name/username of the use who calls the Sp

    @retError					:	The return code, 0 is successful otherwise -1

Revision History:
    1.0					NGF					2008.01.08 10:35
    Created

    1.2					NGF					2008.08.27 16:51
    Added the Personal Action Form

    1.3					NGF					2009.11.08 08:49
    Added the Employee Performance Appraisal form

    1.4					NGF					2010.01.07 11:35
    Added the rejection feature for validator

    1.5					NGF					2010.05.18 14:39
    Reset the planned reference no if rejected

    1.6					NGF					2011.10.02 08:50
    Added necessary execution for TSR

    1.7					NGF					2012.05.22 10:07
    Update the status of Work Order during rejection

    1.8					NGF					2012.06.13 08:57
    Added the Clearance Form

    1.9					SAK					2013.04.03 07:42
    Modified to update status of the PO if rejected.

    1.8					NGF					2013.04.28 10:12
    Added the inserting order detail history

    1.9					NGF					2013.05.09 10:45
    Modified the status code being set to order requisition once it is rejected

    2.0					NGF					2013.05.21 14:55
    Insert order detail history after updating the order details, and during rejection

    2.1					SAK					2015.03.16 09:38
    Insert order detail history after updating the order details, and during rejection

    2.2					EOB					2015.03.25 11:50
    Implemented the half day leave. Set the value of "LRY58VCAFG" (leave approval flag) field in "F58LV13" table  to 'R' when leave request is rejected.

    2.3					SAK					2015.04.14 12:15
    Modified the code to approve reject recruitment requests

    2.4					SAK					22-Mar-2016 2:10PM
    Modified the code to approve reject invoice requests

	2.5					SAK					17-Apr-2016 12:10PM
    Modified the code to insert appropriate history when Invoice Requisitions are reassigned to originator

	2.6					SAK					16-Apr-2017 12:10PM
    Modified the code to trim the value of @reqModifiedName to 10 chars 

	2.7					EOB					17-Feb-2019 02:10PM
    Refactored the code to enhance data retrieval performance

	2.8					EOB					29-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.9					EOB					19-Aug-2019 14:35PM
    Set the value of "@reqModifiedName" to the employee's full name for probationary requisition

	3.0					SAK					03-Nov-2019 10:35AM
    Unhold a PO before approval or rejection. As part of Helpdesk No. 74726.

	3.1					SAK					26-Apr-2020 11:35AM
    Modified the code to approve reject ECR - Employee Contract Renewal Requests.

	3.2					EOB					30-Aug-2023 09:52 AM
    Implemented the CEA workflow
**************************************************************************************************************************************************************************/

ALTER PROCEDURE secuser.pr_ApproveRejectServiceRequest
    @reqType INT,
    @reqTypeNo INT,
    @appApproved BIT,
    @appRemarks VARCHAR(300),
    @actID INT OUTPUT,
    @actStatusID INT OUTPUT,
    @reqStatusID INT OUTPUT,
    @reqStatusCode VARCHAR(10) OUTPUT,
    @currentDistMemRoutineSeq INT OUTPUT,
    @reqModifiedBy INT,
    @reqModifiedName VARCHAR(50),
    @retError INT OUTPUT
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

    DECLARE @RETURN_OK INT
    DECLARE @RETURN_ERROR INT

    SET @RETURN_OK    = 0
    SET @RETURN_ERROR = -1

    SET @retError = @RETURN_OK

    DECLARE @REQUEST_TYPE_LEAVE INT
    DECLARE @REQUEST_TYPE_PR INT
    DECLARE @REQUEST_TYPE_TSR INT
    DECLARE @REQUEST_TYPE_PAF INT
    DECLARE @REQUEST_TYPE_EPA INT
    DECLARE @REQUEST_TYPE_CLRFRM INT
    DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT		-- ver 2.4
	DECLARE @REQUEST_TYPE_PROBY INT		-- ver 2.8
	DECLARE @REQUEST_TYPE_ECR INT		-- ver 3.1
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 3.2

    SET @REQUEST_TYPE_LEAVE		= 4
    SET @REQUEST_TYPE_PR		= 5
    SET @REQUEST_TYPE_TSR		= 6
    SET @REQUEST_TYPE_PAF		= 7
    SET @REQUEST_TYPE_EPA		= 11
    SET @REQUEST_TYPE_CLRFRM	= 16
    SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.4
	SET @REQUEST_TYPE_ECR		= 20	-- ver 3.1
	SET @REQUEST_TYPE_PROBY		= 21	-- ver 2.8
	SET @REQUEST_TYPE_CEA		= 22	-- ver 3.2

    DECLARE @SERV_ROLE_APPROVER INT
    DECLARE @SERV_ROLE_VALIDATOR INT

    SELECT @SERV_ROLE_APPROVER = a.UDCID
    FROM   secuser.UserDefinedCode AS a
    WHERE  a.UDCUDCGID = 11 AND
           a.UDCCode = 'APP'

    SELECT @SERV_ROLE_VALIDATOR = a.UDCID
    FROM   secuser.UserDefinedCode AS a
    WHERE  a.UDCUDCGID = 11 AND
           a.UDCCode = 'VAL'

    DECLARE @APPROVAL_PRIMARY TINYINT
    DECLARE @APPROVAL_AT_LEAST_ONE TINYINT
    DECLARE @APPROVAL_ALL_APPROVERS TINYINT

    SET @APPROVAL_PRIMARY       = 1
    SET @APPROVAL_AT_LEAST_ONE  = 2
    SET @APPROVAL_ALL_APPROVERS = 3

    DECLARE @currentDistMemID INT
    DECLARE @currentDistMemActionType INT
    DECLARE @currentDistMemApproval TINYINT
    DECLARE @distMemID INT

    DECLARE @distMemDistListID INT

    DECLARE @historyDate DATETIME
    DECLARE @reqStatusDesc VARCHAR(300)
    DECLARE @leaveApprovalFlag CHAR(1)

    DECLARE @assignNext BIT
    DECLARE @endActivity BIT
    DECLARE @countCurrentDist INT
    DECLARE @origRoutineSeq INT

    SET @endActivity = 0

    DECLARE @actionAutoApprove BIT
    DECLARE @actionByPass BIT
    DECLARE @reqTypeEmpNo INT
    DECLARE @reqTypeEmpName VARCHAR(50)
    DECLARE @leaveEmpNo FLOAT
    DECLARE @leavePlanRefNo FLOAT
    DECLARE @leaveCompany CHAR(5)
	DECLARE	@statusDesc VARCHAR(50)
	DECLARE	@statusHandlingCode	VARCHAR(50)
	DECLARE @approverEmailList VARCHAR(1000) = ''
	
	--Truncate and trim the @reqModifiedName value to ver 2.6
	SET @reqModifiedName = SUBSTRING(@reqModifiedName, 1, 10)

    IF	@reqType = @REQUEST_TYPE_RR OR 
		@reqType = @REQUEST_TYPE_PROBY	--Rev. #1.9
    BEGIN

        SELECT @reqModifiedName = EmpName
        FROM secuser.EmployeeMaster WITH (NOLOCK)
        WHERE EmpNo = @reqModifiedBy
    END

    SET @appRemarks = LTRIM(RTRIM(@appRemarks))

    SET XACT_ABORT ON

    -- Checks if the approver is still part of the current list
    IF NOT EXISTS (
           SELECT a.CurrentDistMemEmpNo
           FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
           WHERE  a.CurrentDistMemReqType = @reqType AND
                  a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                  a.CurrentDistMemCurrent = 1 AND
                  a.CurrentDistMemEmpNo = @reqModifiedBy
       )
    BEGIN
        SET XACT_ABORT OFF
        RETURN
    END

	-- Unhold a PO before approval or Rejection
	IF EXISTS (SELECT 1 FROM secuser.PurchaseRequisitionWF WHERE PRDocNo = @reqTypeNo AND PROrderType = 'OP' AND CAST(LTRIM(RTRIM(PRReqStatusCode)) AS INT) = 18)
	BEGIN
	    EXEC secuser.pr_HoldUnholdRequest @reqTypeNo, @reqType,  0, @reqModifiedBy,   @reqModifiedName,  '' 	    
	END

    -- Create an Approval Record
    SELECT @actID = b.ActID
    FROM   secuser.ProcessWF AS a WITH (NOLOCK) INNER JOIN
           secuser.TransActivity AS b WITH (NOLOCK) ON
           a.ProcessID = b.ActProcessID
    WHERE  a.ProcessReqType = @reqType AND
           a.ProcessReqTypeNo = @reqTypeNo AND
           b.ActCurrent = 1



    INSERT INTO secuser.Approval (
                    AppReqType,
                    AppReqTypeNo,
                    AppApproved,
                    AppRemarks,
                    AppActID,
                    AppRoutineSeq,
                    AppCreatedBy,
                    AppCreatedName,
                    AppCreatedDate,
                    AppModifiedBy,
                    AppModifiedName,
                    AppModifiedDate
                )
    VALUES      (
                    @reqType,
                    @reqTypeNo,
                    @appApproved,
                    @appRemarks,
                    @actID,
                    @currentDistMemRoutineSeq,
                    @reqModifiedBy,
                    @reqModifiedName,
                    GETDATE(),
                    @reqModifiedBy,
                    @reqModifiedName,
                    GETDATE()
                )

    -- Check for errors
    IF @@ERROR = @RETURN_OK
    BEGIN
        -- Update the status of the Current Distribution Member
        -- Request Approved
        IF @appApproved = 1
        BEGIN
            SELECT @reqStatusID = a.UDCID,
                   @reqStatusCode = a.UDCCode,
                   @reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1,
				   @statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode),
                   @leaveApprovalFlag = 'W'
            FROM   secuser.UserDefinedCode AS a WITH (NOLOCK)
            WHERE  a.UDCUDCGID = 9 AND
                   a.UDCCode = '120'
        END

        -- Request Rejected
        ELSE
        BEGIN
            -- Retrieve the action type
            SELECT TOP 1
                   @currentDistMemActionType = a.CurrentDistMemActionType
            FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
            WHERE  a.CurrentDistMemReqType = @reqType AND
                   a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                   a.CurrentDistMemCurrent = 1 AND
                   a.CurrentDistMemEmpNo = @reqModifiedBy

            IF @currentDistMemActionType = @SERV_ROLE_VALIDATOR
            BEGIN
                SELECT @reqStatusID = a.UDCID,
                       @reqStatusCode = a.UDCCode,
                       @reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1,
                       @leaveApprovalFlag = 'R'
                FROM   secuser.UserDefinedCode AS a WITH (NOLOCK)
                WHERE  a.UDCUDCGID = 9 AND
                       a.UDCCode = '112'
            END

            ELSE
            BEGIN
                SELECT @reqStatusID = a.UDCID,
                       @reqStatusCode = a.UDCCode,
                       @reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1,
                       @leaveApprovalFlag = 'R'
                FROM   secuser.UserDefinedCode AS a WITH (NOLOCK)
                WHERE  a.UDCUDCGID = 9 AND
                       a.UDCCode = '110'
            END
        END

        -- Add History Routine Record
        SET @historyDate   = DATEADD(ss, -1, GETDATE())
        SET @reqStatusDesc = @reqStatusDesc + ' (' + @reqModifiedName + ')'

		-- ver 2.5 Start
		 --EXEC secuser.pr_InsertRequestHistory
   --          @reqType,
   --          @reqTypeNo,
   --          @reqStatusDesc,
   --          @reqModifiedBy,
   --          @reqModifiedName,
   --          @historyDate,
   --          @retError output

		IF @reqType = @REQUEST_TYPE_IR AND @appApproved = 0 AND EXISTS(SELECT IRNo FROM secuser.InvoiceRequisitionWF WHERE IRNo = @reqTypeNo AND IRIsReassignedToOriginator = 1)
			EXEC secuser.pr_InsertRequestHistory
				 @reqType,
				 @reqTypeNo,
				 'Reassigned back to originator by Cost Center Manager',
				 @reqModifiedBy,
				 @reqModifiedName,
				 @historyDate,
				 @retError OUTPUT
		ELSE
			EXEC secuser.pr_InsertRequestHistory
				 @reqType,
				 @reqTypeNo,
				 @reqStatusDesc,
				 @reqModifiedBy,
				 @reqModifiedName,
				 @historyDate,
				 @retError OUTPUT

		-- ver 2.5 End


        --IF @retError = @RETURN_OK
        --BEGIN
            IF @reqType = @REQUEST_TYPE_CLRFRM
            BEGIN
                -- Retrieve the Approval Settings and other information
                SELECT TOP 1
                       @currentDistMemID = a.CurrentDistMemID,
                       @currentDistMemActionType = a.CurrentDistMemActionType,
                       @currentDistMemApproval = a.CurrentDistMemApproval,
                       @distMemDistListID = b.DistMemDistListID,
                       @distMemID = b.DistMemID,
                       @actID = c.ActionActID,
                       @actStatusID = d.ActStatusID,
                       @actionAutoApprove = c.ActionAutoApprove,
                       @actionByPass = c.ActionByPass
                FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                       INNER JOIN secuser.DistributionMember AS b WITH (NOLOCK) ON a.CurrentDistMemRefID = b.DistMemID
                       INNER JOIN secuser.ActivityAction AS c WITH (NOLOCK) ON b.DistMemDistListID = c.ActionDistListID
                       INNER JOIN secuser.TransActivity AS d WITH (NOLOCK) ON c.ActionActID = d.ActID
                WHERE  a.CurrentDistMemReqType = @reqType AND
                       a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                       a.CurrentDistMemEmpNo = @reqModifiedBy AND
                       a.CurrentDistMemCurrent = 1/* AND
                       a.CurrentDistMemActionType = 64*/
            END

            ELSE
            BEGIN
                -- Retrieve the Approval Settings and other information
                SELECT TOP 1
                       @currentDistMemID = a.CurrentDistMemID,
                       @currentDistMemActionType = a.CurrentDistMemActionType,
                       @currentDistMemApproval = a.CurrentDistMemApproval,
                       @distMemDistListID = b.DistMemDistListID,
                       @distMemID = b.DistMemID,
                       @actID = c.ActionActID,
                       @actStatusID = d.ActStatusID,
                       @actionAutoApprove = c.ActionAutoApprove,
                       @actionByPass = c.ActionByPass
                FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                       INNER JOIN secuser.DistributionMember AS b WITH (NOLOCK) ON
                       a.CurrentDistMemRefID = b.DistMemID
                       INNER JOIN secuser.ActivityAction AS c WITH (NOLOCK) ON
                       b.DistMemDistListID = c.ActionDistListID
                       INNER JOIN secuser.TransActivity AS d WITH (NOLOCK) ON
                       c.ActionActID = d.ActID
                WHERE  a.CurrentDistMemReqType = @reqType AND
                       a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                       a.CurrentDistMemEmpNo = @reqModifiedBy AND
                       a.CurrentDistMemCurrent = 1/* AND
                       a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq*/
            END

            -- Update the status of the Current Distribution Member
            UPDATE secuser.CurrentDistributionMember
            SET    CurrentDistMemCurrent = 0,
                   CurrentDistMemStatusID = @reqStatusID,
                   CurrentDistMemModifiedBy = @reqModifiedBy,
                   CurrentDistMemModifiedDate = GETDATE()
            WHERE  CurrentDistMemID = @currentDistMemID

            -- Check for errors
            IF @@ERROR = @RETURN_OK
            BEGIN
                -- Update the status of the Distribution Member
                UPDATE secuser.DistributionMember
                SET    DistMemStatusID = (
                           SELECT a.UDCID
                           FROM   secuser.UserDefinedCode AS a
                           WHERE  a.UDCUDCGID = 16 AND
                                  a.UDCCode = 'C'
                       )
                WHERE  DistMemID = @distMemID

                -- Checks for error
                IF @@ERROR = @RETURN_OK
                BEGIN
                    -- Check the approval type
                    IF @appApproved = 1 AND (@currentDistMemApproval = @APPROVAL_PRIMARY OR @currentDistMemApproval = @APPROVAL_AT_LEAST_ONE)
                    BEGIN
                        -- Set the next current distribution member and increment the routine sequence
                        SET @assignNext               = 1
                        SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1
                    END

                    ELSE IF @appApproved = 1 AND @currentDistMemApproval = @APPROVAL_ALL_APPROVERS
                    BEGIN
                        -- Check if no more Approvers on current routine sequence
                        IF NOT EXISTS (
                               SELECT a.CurrentDistMemEmpNo
                               FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                               WHERE  a.CurrentDistMemReqType = @reqType AND
                                      a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                                      a.CurrentDistMemCurrent = 1 AND
                                      a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq
                           )
                        BEGIN
                            -- Set the next current distribution member and increment the routine sequence
                            SET @assignNext               = 1
                            SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1
                        END
                    END

                    -- End the Activity if disapproved
                    ELSE IF @appApproved = 0 AND (@currentDistMemApproval = @APPROVAL_PRIMARY OR @currentDistMemApproval = @APPROVAL_ALL_APPROVERS)
                    BEGIN
                        SET @endActivity = 1
                    END

                    -- End the Activity if disapproved and if no more current approvers
                    ELSE IF @appApproved = 0 AND @currentDistMemApproval = @APPROVAL_AT_LEAST_ONE
                    BEGIN
                        -- Check if no more current Approvers
                        IF NOT EXISTS (
                               SELECT a.CurrentDistMemEmpNo
                               FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                               WHERE  a.CurrentDistMemReqType = @reqType AND
                                      a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                                      a.CurrentDistMemCurrent = 1 AND
                                      a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq
                           )
                        BEGIN
                            SET @endActivity = 1
                        END
                    END

                    -- Update the Request Status
                    IF @assignNext = 1 OR @endActivity = 1
                    BEGIN
                        IF @reqType = @REQUEST_TYPE_LEAVE
                        BEGIN
                            UPDATE secuser.LeaveRequisitionWF
                            SET    LeaveApprovalFlag = @leaveApprovalFlag,
                                   LeaveReqStatusID = @reqStatusID,
                                   LeaveReqStatusCode = @reqStatusCode,
                                   LeaveModifiedBy = @reqModifiedBy,
                                   LeaveModifiedName = @reqModifiedName,
                                   LeaveModifiedEmail = '',
                                   LeaveModifiedDate = GETDATE()
                            WHERE  LeaveNo = @reqTypeNo

                            -- Checks for error
                            IF @@ERROR = @RETURN_OK AND @appApproved = 0
                            BEGIN
                                /****************************** Part of Revision No. 2.2 ***************************************/
                                -- Retrieve the leave planned reference no
                                SELECT @leaveEmpNo = a.EmpNo,
                                       @leavePlanRefNo = a.LeavePlannedNo,
                                       @leaveCompany = LTRIM(RTRIM(a.Company))
                                FROM   secuser.LeaveRequisition AS a WITH (NOLOCK)
                                WHERE  a.RequisitionNo = @reqTypeNo

                                -- Remove the Leave Planned Reference No.
                                UPDATE secuser.F58LV21 
                                SET    LVNUM2 = 0
                                WHERE  LVAN8 = @leaveEmpNo AND
                                       LVY58VCTRN = @leavePlanRefNo

                                IF @appApproved = 0
                                BEGIN
                                    --Set the leave approval flag  when leave request is rejected
                                    UPDATE secuser.F58LV13 
                                    SET    LRY58VCAFG = 'R'
                                    WHERE  LRY58VCRQN = @reqTypeNo AND
                                           LTRIM(RTRIM(LRCO)) = @leaveCompany AND
                                           LRAN8 = @leaveEmpNo
                                END
                                /****************************** End of Revision No. 2.2 ***************************************/
                            END
                        END

                        ELSE IF @reqType = @REQUEST_TYPE_PR
                        BEGIN
                            DECLARE @prDocType varchar(2)

                            SELECT @prDocType = a.PHDCTO
                            FROM   secuser.F4301 AS a WITH (NOLOCK)
                            WHERE  a.PHDOCO = @reqTypeNo AND
                                   PHSFXO = '000'

                            UPDATE secuser.PurchaseRequisitionWF
                            SET    PRReqStatusID = @reqStatusID,
                                   PRReqStatusCode = @reqStatusCode,
                                   PRModifiedBy = @reqModifiedBy,
                                   PRModifiedName = @reqModifiedName,
                                   PRModifiedEmail = '',
                                   PRModifiedDate = GETDATE()
                            WHERE  PRDocNo = @reqTypeNo

                            --Update the F4311 table with the status if the PO was rejected
                            IF @@ERROR = @RETURN_OK AND @appApproved = 0 
                            BEGIN
                                -- Sets the appropriate status code
                                IF @prDocType IN ('OP', 'MO') --ver 2.1
                                BEGIN
                                    UPDATE secuser.F4311
                                    SET    PDLTTR = PDNXTR,
                                           PDNXTR = '360',
                                           PDPODC01 = 'R'
                                    WHERE  PDDOCO = @reqTypeNo AND
                                           PDDCTO = @prDocType AND
                                           PDSFXO = '000' AND
                                           PDNXTR <> '999'
                                END

                                ELSE
                                BEGIN
                                    -- Checks if order is a PR Stock Item
                                    IF @prDocType = 'OR' AND
                                       EXISTS (
                                           SELECT a.PDDOCO
                                           FROM   secuser.F4311 AS a WITH (NOLOCK)
                                           WHERE   PDDOCO = @reqTypeNo AND
                                                   PDDCTO = @prDocType AND
                                                   PDSFXO = '000' AND
                                                   PDNXTR <> '999' AND
                                                   PDLNTY = 'S'
                                       )
                                    BEGIN
                                        UPDATE secuser.F4311
                                        SET    PDLTTR = PDNXTR,
                                               PDNXTR = '135',
                                               PDPODC01 = 'R'
                                        WHERE  PDDOCO = @reqTypeNo AND
                                               PDDCTO = @prDocType AND
                                               PDSFXO = '000' AND
                                               PDNXTR <> '999'
                                    END

                                    ELSE
                                    BEGIN
                                        UPDATE secuser.F4311
                                        SET    PDLTTR = '980',
                                               PDNXTR = '999',
                                               PDPODC01 = 'R'
                                        WHERE  PDDOCO = @reqTypeNo AND
                                               PDDCTO = @prDocType AND
                                               PDSFXO = '000' AND
                                               PDNXTR <> '999'
                                    END
                                END

                                -- Checks for error
                                IF @@ERROR = @RETURN_OK
                                BEGIN
                                    -- Inserts order detail history
                                    EXEC secuser.pr_InsertOrderDetailHistory
                                         @reqTypeNo,
                                         @prDocType,
                                         @reqModifiedBy,
                                         @reqModifiedName,
                                         @retError OUTPUT
                                END
                            END
                        END

                        ELSE IF @reqType = @REQUEST_TYPE_TSR
                        BEGIN
                            UPDATE secuser.TSRWF
                            SET    TSRReqStatusID = @reqStatusID,
                                   TSRReqStatusCode = @reqStatusCode,
                                   TSRModifiedBy = @reqModifiedBy,
                                   TSRModifiedName = @reqModifiedName,
                                   TSRModifiedEmail = '',
                                   TSRModifiedDate = GETDATE()
                            WHERE  TSRNo = @reqTypeNo

                            IF @appApproved = 0 AND @@ERROR = @RETURN_OK
                            BEGIN
                                UPDATE secuser.F4801
                                SET    WASRST = 'MM',
                                       WAUSER = LEFT(@reqModifiedName, 10),
                                       WAUPMJ = dbo.ConvertToJulian(GETDATE()),
                                       WATDAY = CONVERT(float, REPLACE(CONVERT(varchar(100), GETDATE(), 108), ':', ''))
                                WHERE  WADOCO = @reqTypeNo

                                -- Checks for error
                                IF @@ERROR = @RETURN_OK
                                BEGIN
                                    DECLARE @woEquipNo float
                                    DECLARE @currentDate datetime
                                    DECLARE @woStatusCreatedModifiedName char(10)

                                    SET @currentDate                 = GETDATE()
                                    SET @woStatusCreatedModifiedName = LEFT(@reqModifiedName, 10)

                                    SELECT @woEquipNo = a.WANUMB
                                    FROM   secuser.F4801 AS a
                                    WHERE  a.WADCTO = 'WO' AND
                                           a.WADOCO = @reqTypeNo

                                    EXEC secuser.pr_InsertUpdateDeleteWorkOrderStatus
                                         @woEquipNo,
                                         0,
                                         '2',
                                         @reqTypeNo,
                                         'MM',
                                         @currentDate,
                                         NULL,
                                         'Work Order Rejected',
                                         @woStatusCreatedModifiedName,
                                         'GAP',
                                         '',
                                         @retError OUTPUT
                                END

                                ELSE
                                BEGIN
                                    SET @retError = @RETURN_ERROR
                                END
                            END
                        END

                        ELSE IF @reqType = @REQUEST_TYPE_PAF
                        BEGIN
                            UPDATE secuser.PAFWF
                            SET    PAFReqStatusID =  @reqStatusID,
                                   PAFReqStatusCode = @reqStatusCode,
                                   PAFModifiedBy = @reqModifiedBy,
                                   PAFModifiedName = @reqModifiedName,
                                   PAFModifiedEmail = '',
                                   PAFModifiedDate = GETDATE()
                            WHERE  PAFNo = @reqTypeNo

                            IF @appApproved = 0 AND @@ERROR = @RETURN_OK
                            BEGIN
                                UPDATE secuser.F55PAF SET PAY58VCAFG = 'R'
                                WHERE  PAG55AUTO = (
                                           SELECT TOP 1
                                                  a.PAFAutoID
                                           FROM   secuser.PAFWF AS a
                                           WHERE  a.PAFNo = @reqTypeNo
                                       )
                            END
                        END

						-- ver 2.8 Start
						ELSE IF @reqType = @REQUEST_TYPE_PROBY
                        BEGIN

							--Get the status details
							SELECT	@statusDesc= RTRIM(a.UDCDesc1),
									@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
							FROM secuser.UserDefinedCode a WITH (NOLOCK) 
							WHERE UDCUDCGID = 9 
								AND RTRIM(a.UDCCOde) = RTRIM(@reqStatusCode)

                            UPDATE secuser.ProbationaryRequisitionWF
                            SET    PARStatusID =  @reqStatusID,
                                   PARStatusCode = @reqStatusCode,
								   PARStatusDesc = @statusDesc,
								   PARStatusHandlingCode = @statusHandlingCode,
                                   PARLastModifiedByEmpNo = @reqModifiedBy,
                                   PARLastModifiedByEmpName = @reqModifiedName,
                                   PARLastModifiedByEmpEmail = secuser.fnGetEmployeeEmail(@reqModifiedBy),
                                   PARLastModifiedDate = GETDATE()
                            WHERE  PARRequisitionNo = @reqTypeNo
                        END
						-- ver 2.8 End

                        ELSE IF @reqType = @REQUEST_TYPE_EPA
                        BEGIN
                            UPDATE secuser.EPAWF
                            SET    EPAReqStatusID =  @reqStatusID,
                                   EPAReqStatusCode = @reqStatusCode,
                                   EPAModifiedBy = @reqModifiedBy,
                                   EPAModifiedName = @reqModifiedName,
                                   EPAModifiedEmail = '',
                                   EPAModifiedDate = GETDATE()
                            WHERE  EPANo = @reqTypeNo
                        END

                        ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
                        BEGIN
                            UPDATE secuser.ClearanceFormWF
                            SET    ClrFormStatusID = @reqStatusID,
                                   ClrFormStatusCode = @reqStatusCode,
                                   ClrFormModifiedBy = @reqModifiedBy,
                                   ClrFormModifiedName= @reqModifiedName,
                                   ClrFormModifiedEmail = '',
                                   ClrFormModifiedDate = GETDATE()
                            WHERE  ClrFormNo = @reqTypeNo
                        END

                        ELSE IF @reqType = @REQUEST_TYPE_RR
                        BEGIN
                            UPDATE secuser.RecruitmentRequisitionWF
                            SET    RRReqStatusID = @reqStatusID,
                                   RRReqStatusCode = @reqStatusCode,
                                   RRModifiedBy = @reqModifiedBy,
                                   RRModifiedName = @reqModifiedName,
                                   RRModifiedEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy),
                                   RRModifiedDate = GETDATE()
                            WHERE  RRNo = @reqTypeNo

                            -- Update the main table with the status
                            IF @appApproved = 0 AND @@ERROR = @RETURN_OK
                            BEGIN
                                UPDATE secuser.RecruitmentRequisition
                                SET    RRStatus = 'Rejected'
                                WHERE  RRNo = @reqTypeNo
                            END
                        END

						-- ver 2.4 Start
						ELSE IF @reqType = @REQUEST_TYPE_IR
                        BEGIN
                            UPDATE secuser.InvoiceRequisitionWF
                            SET     IRStatusID = @reqStatusID,
                                   IRStatusCode = @reqStatusCode,
                                   IRLastModifiedByEmpNo = @reqModifiedBy,
                                   IRLastModifiedByEmpName = @reqModifiedName,
                                   IRLastModifiedByEmpEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy),
                                   IRLastModifiedDate = GETDATE()
                            WHERE  IRNo = @reqTypeNo

                            -- Update the main table with the status
                            IF @appApproved = 0 AND @@ERROR = @RETURN_OK
                            BEGIN
                                UPDATE secuser.InvoiceRequisition
                                SET StatusID = @reqStatusID, StatusCode = @reqStatusCode, StatusDesc = @reqStatusDesc
                                WHERE InvoiceRequisitionNo = @reqTypeNo
                            END
                        END
						-- ver 2.4 End		
						
						-- ver 3.1 Start
						ELSE IF @reqType = @REQUEST_TYPE_ECR
                        BEGIN
                            UPDATE secuser.EmployeeContractRenewalWF
                            SET    ECRStatusID =  @reqStatusID,
                                   ECRStatusCode = @reqStatusCode,
                                   ECRLastModifiedBy = @reqModifiedBy,
                                   ECRLastModifiedDate = GETDATE()
                            WHERE  ECRNo = @reqTypeNo
                        END
						-- ver 3.1 End

						-- ver 3.2 Start
						ELSE IF @reqType = @REQUEST_TYPE_CEA
                        BEGIN

							--Get the email address of all approvers who have approved the request							
							SELECT @approverEmailList = secuser.fnGetApproverEmail(@reqTypeNo)

                            UPDATE secuser.CEAWF
                            SET    CEAStatusID =  @reqStatusID,
                                   CEAStatusCode = @reqStatusCode,
								   CEAStatusHandlingCode = @statusHandlingCode,
                                   CEAModifiedBy = @reqModifiedBy,
                                   CEAModifiedDate = GETDATE(),
								   CEARejectEmailGroup = ISNULL(@approverEmailList, ''),
								   CEARejectionRemarks = RTRIM(@appRemarks)
                            WHERE  CEARequisitionNo = @reqTypeNo
                        END
						-- ver 3.2 End

                        -- Checks for error
                        IF @@ERROR <> @RETURN_OK
                        BEGIN
                            SET @retError = @RETURN_ERROR
                        END
                    END

                    -- Checks for error
                    IF @retError = @RETURN_OK
                    BEGIN
                        -- Check if assigning to next approver / service provider
                        IF @assignNext = 1
                        BEGIN
                            -- Store the current routine sequence
                            SET @origRoutineSeq = @currentDistMemRoutineSeq

                            -- Check if there's succeeding current distribution members
                            WHILE EXISTS (
                                      SELECT b.DistMemEmpNo
                                      FROM   secuser.ActivityAction AS a WITH (NOLOCK)
                                             INNER JOIN secuser.DistributionMember AS b WITH (NOLOCK) ON
                                             a.ActionDistListID = b.DistMemDistListID
                                             INNER JOIN secuser.TransActivity AS c WITH (NOLOCK) ON
                                             a.ActionActID = c.ActID
                                             INNER JOIN secuser.ProcessWF AS d WITH (NOLOCK) ON
                                             c.ActProcessID = d.ProcessID
                                      WHERE  d.ProcessReqType = @reqType AND
                                             d.ProcessReqTypeNo = @reqTypeNo AND
                                             a.ActionActID = @actID AND
                                             b.DistMemRoutineSeq = @currentDistMemRoutineSeq
                                  ) AND
                                             --a.ActionActID = @actID AND b.DistMemRoutineSeq > @origRoutineSeq) AND
                                  @retError = @RETURN_OK
                            BEGIN
                                -- Set the next Approver / Service Provider
                                EXEC secuser.pr_SetCurrentDistributionMember
                                     @reqType,
                                     @reqTypeNo,
                                     @currentDistMemActionType,
                                     @distMemDistListID,
                                     @currentDistMemRoutineSeq,
                                     @reqModifiedBy,
                                     @retError output

                                -- Checks for error
                                IF @retError = @RETURN_OK
                                BEGIN
                                    -- Checks if No Current Distribution Member was set
                                    SET @countCurrentDist = 0

                                    SELECT @countCurrentDist = COUNT(1)
                                    FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                                    WHERE  a.CurrentDistMemReqType = @reqType AND
                                           a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                                           a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq

                                    IF @countCurrentDist = 0
                                    BEGIN
                                        -- Increment the routine sequence
                                        SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1
                                    END

                                    -- Update the Service Request
                                    ELSE
                                    BEGIN
                                        -- Set the status to waiting for approval
                                        SELECT @reqStatusID = a.UDCID,
                                               @reqStatusCode = a.UDCCode
                                        FROM   secuser.UserDefinedCode AS a WITH (NOLOCK)
                                        WHERE  a.UDCUDCGID = 9 AND
                                               a.UDCCode = '05'

                                        IF @reqType = @REQUEST_TYPE_LEAVE
                                        BEGIN
                                            UPDATE secuser.LeaveRequisitionWF
                                            SET    LeaveReqStatusID = @reqStatusID,
                                                   LeaveReqStatusCode = @reqStatusCode,
                                                   LeaveModifiedBy = @reqModifiedBy,
                                                   LeaveModifiedName = @reqModifiedName,
                                                   LeaveModifiedEmail = '',
                                                   LeaveModifiedDate = GETDATE()
                                            WHERE  LeaveNo = @reqTypeNo
                                        END

                                        ELSE IF @reqType = @REQUEST_TYPE_PR
                                        BEGIN
                                            UPDATE secuser.PurchaseRequisitionWF
                                            SET    PRReqStatusID = @reqStatusID,
                                                   PRReqStatusCode = @reqStatusCode,
                                                   PRModifiedBy = @reqModifiedBy,
                                                   PRModifiedName = @reqModifiedName,
                                                   PRModifiedEmail = '',
                                                   PRModifiedDate = GETDATE()
                                            WHERE  PRDocNo = @reqTypeNo
                                        END

                                        ELSE IF @reqType = @REQUEST_TYPE_TSR
                                        BEGIN
                                            UPDATE secuser.TSRWF
                                            SET    TSRReqStatusID = @reqStatusID,
                                                   TSRReqStatusCode = @reqStatusCode,
                                                   TSRModifiedBy = @reqModifiedBy,
                                                   TSRModifiedName = @reqModifiedName,
                                                   TSRModifiedEmail = '',
                                                   TSRModifiedDate = GETDATE()
                                            WHERE  TSRNo = @reqTypeNo
                                        END

                                        ELSE IF @reqType = @REQUEST_TYPE_PAF
                                        BEGIN
                                            UPDATE secuser.PAFWF
                                            SET    PAFReqStatusID = @reqStatusID,
                                                   PAFReqStatusCode = @reqStatusCode,
                                                   PAFModifiedBy = @reqModifiedBy,
                                                   PAFModifiedName = @reqModifiedName,
                                                   PAFModifiedEmail = '',
                                                   PAFModifiedDate = GETDATE()
                                            WHERE  PAFNo = @reqTypeNo
                                        END

										-- ver 2.8 Start
										ELSE IF @reqType = @REQUEST_TYPE_PROBY
										BEGIN
											
											--Get the status details
											SELECT	@statusDesc= RTRIM(a.UDCDesc1),
													@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
											FROM secuser.UserDefinedCode a WITH (NOLOCK) 
											WHERE UDCUDCGID = 9 
												AND RTRIM(a.UDCCOde) = RTRIM(@reqStatusCode)

											UPDATE secuser.ProbationaryRequisitionWF
											SET    PARStatusID =  @reqStatusID,
												   PARStatusCode = @reqStatusCode,
												   PARStatusDesc = @statusDesc,
												   PARStatusHandlingCode = @statusHandlingCode,
												   PARLastModifiedByEmpNo = @reqModifiedBy,
												   PARLastModifiedByEmpName = @reqModifiedName,
												   PARLastModifiedByEmpEmail = secuser.fnGetEmployeeEmail(@reqModifiedBy),
												   PARLastModifiedDate = GETDATE()
											WHERE  PARRequisitionNo = @reqTypeNo
										END
										-- ver 2.8 End

                                        ELSE IF @reqType = @REQUEST_TYPE_EPA
                                        BEGIN
                                            UPDATE secuser.EPAWF
                                            SET    EPAReqStatusID = @reqStatusID,
                                                   EPAReqStatusCode = @reqStatusCode,
                                                   EPAModifiedBy = @reqModifiedBy,
                                                   EPAModifiedName = @reqModifiedName,
                                                   EPAModifiedEmail = '',
                                                   EPAModifiedDate = GETDATE()
                                            WHERE  EPANo = @reqTypeNo
                                        END

                                        ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
                                        BEGIN
                                            UPDATE secuser.ClearanceFormWF
                                            SET    ClrFormStatusID = @reqStatusID,
                                                   ClrFormStatusCode = @reqStatusCode,
                                                   ClrFormModifiedBy = @reqModifiedBy,
                                                   ClrFormModifiedName = @reqModifiedName,
                                                   ClrFormModifiedEmail = '',
                                                   ClrFormModifiedDate = GETDATE()
                                            WHERE  ClrFormNo = @reqTypeNo
                                        END

                                        ELSE IF @reqType = @REQUEST_TYPE_RR
                                        BEGIN
                                            UPDATE secuser.RecruitmentRequisitionWF
                                            SET    RRReqStatusID = @reqStatusID,
                                                   RRReqStatusCode = @reqStatusCode,
                                                   RRModifiedBy = @reqModifiedBy,
                                                   RRModifiedName = @reqModifiedName,
                                                   RRModifiedEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy),
                                                   RRModifiedDate = GETDATE()
                                            WHERE RRNo = @reqTypeNo
                                        END

										-- ver 2.4 Start
										ELSE IF @reqType = @REQUEST_TYPE_IR
                                        BEGIN
                                            UPDATE secuser.InvoiceRequisitionWF
                                            SET    IRStatusID = @reqStatusID,
                                                   IRStatusCode = @reqStatusCode,
                                                   IRLastModifiedByEmpNo = @reqModifiedBy,
                                                   IRLastModifiedByEmpName = @reqModifiedName,
                                                   IRLastModifiedByEmpEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy),
                                                   IRLastModifiedDate = GETDATE()
                                            WHERE IRNo = @reqTypeNo
                                        END
										-- ver 2.4 End

										-- ver 3.1 Start
										ELSE IF @reqType = @REQUEST_TYPE_ECR
                                        BEGIN
                                            UPDATE secuser.EmployeeContractRenewalWF
											SET    ECRStatusID =  @reqStatusID,
												   ECRStatusCode = @reqStatusCode,
												   ECRLastModifiedBy = @reqModifiedBy,
												   ECRLastModifiedDate = GETDATE()
											WHERE  ECRNo = @reqTypeNo
                                        END
										-- ver 3.1 End

										-- ver 3.2 Start
										ELSE IF @reqType = @REQUEST_TYPE_CEA
                                        BEGIN

											--Get the email address of all approvers who have approved the request											
											SELECT @approverEmailList = secuser.fnGetApproverEmail(@reqTypeNo)

                                            UPDATE secuser.CEAWF
											SET    CEAStatusID =  @reqStatusID,
												   CEAStatusCode = @reqStatusCode,
												   CEAModifiedBy = @reqModifiedBy,
												   CEAModifiedDate = GETDATE(),
												   CEARejectEmailGroup = ISNULL(@approverEmailList, ''),
												   CEARejectionRemarks = RTRIM(@appRemarks)
											WHERE  CEARequisitionNo = @reqTypeNo
                                        END
										-- ver 3.2 End

                                        -- Checks for error
                                        IF @@ERROR <> @RETURN_OK
                                        BEGIN
                                            SET @retError = @RETURN_ERROR
                                        END

                                        -- Break the loop
                                        BREAK
                                    END
                                END
                            END
                            -- End of checking if there's succeeding current distribution members -----------------------

                            -- Checks if there's current distribution member
                            SET @countCurrentDist = 0

                            SELECT @countCurrentDist = COUNT(1)
                            FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                            WHERE  a.CurrentDistMemReqType = @reqType AND
                                   a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                                   a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq AND
                                   a.CurrentDistMemCurrent = 1

                            -- End the Activity
                            IF @countCurrentDist = 0
                            BEGIN
                                SET @endActivity              = 1
                                SET @currentDistMemRoutineSeq = @origRoutineSeq - 1
                            END
                        END

                        -- Check if end of activity
                        IF @endActivity = 1 AND @retError = @RETURN_OK
                        BEGIN
                            -- Update all current distribution members
                            UPDATE secuser.CurrentDistributionMember
                            SET    CurrentDistMemCurrent = 0
                            WHERE  CurrentDistMemReqType = @reqType AND
                                   CurrentDistMemReqTypeNo = @reqTypeNo AND
                                   CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq

                            -- Check for errors
                            IF @@ERROR = @RETURN_OK
                            BEGIN
                                -- Retrieve the Activity Status ID
                                SELECT @actStatusID = a.UDCID
                                FROM   secuser.UserDefinedCode AS a WITH (NOLOCK)
                                WHERE  a.UDCUDCGID = 16 AND
                                       a.UDCCode = 'C'

                                -- End the Activity Action
                                EXEC secuser.pr_UpdateTransactionActivity
                                     @actID,
                                     @actStatusID,
                                     @reqModifiedBy,
                                     @retError output

                                -- Set current routine sequence to -1
                                SET @currentDistMemRoutineSeq = -1
                            END

                            ELSE
                            BEGIN
                                SET @retError = @RETURN_ERROR
                            END
                        END

                        -- Update all parameters
                        IF @retError = @RETURN_OK
                        BEGIN
                            EXEC secuser.pr_UpdateAllTransactionParameters
                                 @reqType,
                                 @reqTypeNo,
                                 @reqModifiedBy,
                                 @retError output
                        END

                        -- Print
                        --PRINT 'Auto Approve: ' + CONVERT(varchar(2), @actionAutoApprove)

                        -- Checks if auto approve
                        IF @retError = @RETURN_OK AND @actionAutoApprove = 1 AND @endActivity = 0
                        BEGIN
                            --PRINT 'Auto approval...'

                            -- Retrieve the Employee No of the Requestor
                            IF @reqType = @REQUEST_TYPE_LEAVE
                            BEGIN
                                SELECT @reqTypeEmpNo = a.EmpNo,
                                       @reqTypeEmpName = a.EmpName
                                FROM   secuser.LeaveRequisition AS a WITH (NOLOCK)
                                WHERE  a.RequisitionNo = @reqTypeNo
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_PR
                            BEGIN
                                SELECT @reqTypeEmpNo = a.PREmpNo,
                                       @reqTypeEmpName = a.PREmpName
                                FROM   secuser.PurchaseRequisitionWF AS a WITH (NOLOCK)
                                WHERE  a.PRDocNo = @reqTypeNo
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_TSR
                            BEGIN
                                SELECT @reqTypeEmpNo = a.TSREmpNo,
                                       @reqTypeEmpName = a.TSREmpName
                                FROM   secuser.TSRWF AS a WITH (NOLOCK)
                                WHERE a.TSRNo = @reqTypeNo
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_PAF
                            BEGIN
                                SELECT @reqTypeEmpNo = a.PAFEmpNo,
                                       @reqTypeEmpName = a.PAFEmpName
                                FROM   secuser.PAFWF AS a WITH (NOLOCK)
                                WHERE  a.PAFNo = @reqTypeNo 
                            END

							ELSE IF @reqType = @REQUEST_TYPE_PROBY
                            BEGIN
                                SELECT @reqTypeEmpNo = a.PAREmpNo,
                                       @reqTypeEmpName = a.PAREmpName
                                FROM   secuser.ProbationaryRequisitionWF AS a WITH (NOLOCK)
                                WHERE  a.PARRequisitionNo = @reqTypeNo 
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_EPA
                            BEGIN
                                SELECT @reqTypeEmpNo = a.EPAEmpNo,
                                       @reqTypeEmpName = a.EPAEmpName
                                FROM   secuser.EPAWF AS a WITH (NOLOCK)
                                WHERE  a.EPANo = @reqTypeNo 
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
                            BEGIN
                                SELECT @reqTypeEmpNo = a.ClrFormEmpNo,
                                       @reqTypeEmpName = a.ClrFormEmpName
                                FROM   secuser.ClearanceFormWF AS a WITH (NOLOCK)
                                WHERE  a.ClrFormNo = @reqTypeNo
                            END

                            ELSE IF @reqType = @REQUEST_TYPE_RR
                            BEGIN
                                SELECT @reqTypeEmpNo = a.RRCreatedBy,
                                       @reqTypeEmpName = a.RRCreatedByName
                                FROM   secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK)
                                WHERE  a.RRNo = @reqTypeNo 
                            END

							-- ver 2.4 Start
							ELSE IF @reqType = @REQUEST_TYPE_IR
                            BEGIN
                                SELECT @reqTypeEmpNo = a.IRCreatedByEmpNo,
                                       @reqTypeEmpName = a.IRCreatedByEmpName
                                FROM   secuser.InvoiceRequisitionWF AS a WITH (NOLOCK)
                                WHERE  a.IRNo = @reqTypeNo 
                            END
							-- ver 2.4 End

							-- ver 3.1 Start
							ELSE IF @reqType = @REQUEST_TYPE_ECR
                            BEGIN
                                SELECT @reqTypeEmpNo = a.ECREmpNo,
                                       @reqTypeEmpName = a.ECREmpName
                                FROM   secuser.EmployeeContractRenewalWF AS a WITH (NOLOCK)
                                WHERE  a.ECRNo = @reqTypeNo 
                            END
							-- ver 3.1 End

							-- ver 3.2 Start
							ELSE IF @reqType = @REQUEST_TYPE_CEA
                            BEGIN

                                SELECT @reqTypeEmpNo = a.CEAEmpNo,
                                       @reqTypeEmpName = a.CEAEmpName
                                FROM   secuser.CEAWF AS a WITH (NOLOCK)
                                WHERE  a.CEARequisitionNo = @reqTypeNo 
                            END
							-- ver 3.2 End

                            -- Checks if the requestor is one of the current distribution member
                            IF EXISTS (
                                   SELECT a.CurrentDistMemEmpNo
                                   FROM   secuser.CurrentDistributionMember AS a WITH (NOLOCK)
                                   WHERE  a.CurrentDistMemEmpNo = @reqTypeEmpNo AND
                                          a.CurrentDistMemReqType = @reqType AND
                                          a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                                          a.CurrentDistMemActionType = @SERV_ROLE_APPROVER AND
                                          a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq AND
                                          a.CurrentDistMemCurrent = 1
                               )
                            BEGIN
                                -- Add some delays
                                WAITFOR DELAY '00:00:01'

                                SET @reqStatusID   = 0
                                SET @reqStatusCode = ''

                                -- Create auto approval
                                EXEC secuser.pr_ApproveRejectServiceRequest
                                     @reqType,
                                     @reqTypeNo,
                                     1,
                                    'Approve (Automatic Approval)',
                                    @actID,
                                    @actStatusID OUTPUT,
                                    @reqStatusID OUTPUT,
                                    @reqStatusCode OUTPUT,
                                    @currentDistMemRoutineSeq,
                                    @reqTypeEmpNo,
                                    @reqTypeEmpName,
                                    @retError OUTPUT
                            END
                        END
                    END
                END

                ELSE
                BEGIN
                    SET @retError = @RETURN_ERROR
                END
            END

            ELSE
            BEGIN
                SET @retError = @RETURN_ERROR
            END
        END
    --END

    --ELSE
    --BEGIN
    --    SET @retError = @RETURN_ERROR
    --END

    SET XACT_ABORT OFF
END


