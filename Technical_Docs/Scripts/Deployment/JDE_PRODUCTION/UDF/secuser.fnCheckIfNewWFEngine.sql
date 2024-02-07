/****************************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: secuser.fnCheckIfNewWFEngine
*	Description: This function is used to check if the requisition uses the new workflow engine
*
*	Date			Author		Rev. #		Comments:
*	03/03/2019		Ervin		1.0			Created
*	23/04/2019		Ervin		1.1			Implemented the logic for Recruitment Requisition
*	30/04/2019		Ervin		1.2			Implemented the logic for Clearance Form
*	05/05/2019		Ervin		1.3			Implemented the logic for Invoice Requisition
*	07/05/2019		Ervin		1.4			Implemented the logic for Purchase Requisition
*	11/06/2019		Ervin		1.5			Implemented the logic for EPMS
*	18/08/2019		Ervin		1.6			Implemented the logic for Probationary Assessment Requisition
*	22/04/2020		Shoukhat	1.7			Implemented the logic for Employee Contract Renewal
*	30/08/2023		Ervin		1.8			Implemented the logic for CEA workflow
****************************************************************************************************************************************************************************************************************/

ALTER FUNCTION secuser.fnCheckIfNewWFEngine
(
	@reqType		INT,
	@reqTypeNo		INT
)
RETURNS @rtnTable 
TABLE 
(
	IsNewWFEngine BIT
) 
AS
BEGIN

	--Define constants
	DECLARE @REQUEST_TYPE_LEAVE			INT,
			@REQUEST_TYPE_PR			INT,
			@REQUEST_TYPE_TSR			INT,
			@REQUEST_TYPE_PAF			INT,
			@REQUEST_TYPE_EPA			INT,
			@REQUEST_TYPE_CLRFRM		INT,
			@REQUEST_TYPE_RR			INT,
			@REQUEST_TYPE_IR			INT,
			@REQUEST_TYPE_ECR			INT,
			@REQUEST_TYPE_PROBY			INT,
			@REQUEST_TYPE_CEA			INT		--Rev. #1.8

	--Initialize constants
	SELECT	@REQUEST_TYPE_LEAVE			= 4,
			@REQUEST_TYPE_PR			= 5,
			@REQUEST_TYPE_TSR			= 6,
			@REQUEST_TYPE_PAF			= 7,
			@REQUEST_TYPE_EPA			= 11,
			@REQUEST_TYPE_CLRFRM		= 16,
			@REQUEST_TYPE_RR			= 18,
			@REQUEST_TYPE_IR			= 19,
			@REQUEST_TYPE_ECR			= 20,
			@REQUEST_TYPE_PROBY			= 21,
			@REQUEST_TYPE_CEA			= 22	--Rev. #1.8

	DECLARE	@isNewWFEngine BIT 
	SET @isNewWFEngine = 0

	IF @reqType = @REQUEST_TYPE_PAF				--PAF
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.PAFIsNewWF, 0)
		FROM secuser.PAFWF a WITH (NOLOCK) 
		WHERE a.PAFNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_LEAVE		--Annual Leave Requisition
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.LeaveIsNewWF, 0)
		FROM secuser.LeaveRequisitionWF a WITH (NOLOCK) 
		WHERE a.LeaveNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_TSR		--TSR
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.TSRIsNewWF, 0)
		FROM secuser.TSRWF a WITH (NOLOCK) 
		WHERE a.TSRNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_RR			--Recruitment Requisition
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.RRIsNewWF, 0)
		FROM secuser.RecruitmentRequisitionWF a WITH (NOLOCK) 
		WHERE a.RRNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_CLRFRM		--Clearance Form	
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.ClrIsNewWF, 0)
		FROM secuser.ClearanceFormWF a WITH (NOLOCK) 
		WHERE a.ClrFormNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_IR			--Invoice Requisition
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.IRIsNewWF, 0)
		FROM secuser.InvoiceRequisitionWF a WITH (NOLOCK) 
		WHERE a.IRNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_PR			--Purchase Requisition
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.PRIsNewWF, 0)
		FROM secuser.PurchaseRequisitionWF a WITH (NOLOCK) 
		WHERE a.PRDocNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_EPA		--EPMS
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.EPAIsNewWF, 0)
		FROM secuser.EPAWF a WITH (NOLOCK) 
		WHERE a.EPANo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_PROBY		--Probationary Assessment Request
	BEGIN

		SELECT @isNewWFEngine = ISNULL(a.PARIsNewWF, 0)
		FROM secuser.ProbationaryRequisitionWF a WITH (NOLOCK) 
		WHERE a.PARRequisitionNo = @reqTypeNo
    END 

	ELSE IF @reqType = @REQUEST_TYPE_ECR		-- ECR
	BEGIN

		SELECT @isNewWFEngine = 1
    END 

	ELSE IF @reqType = @REQUEST_TYPE_CEA		-- CEA
	BEGIN

		SELECT @isNewWFEngine = 1
    END 

	INSERT INTO @rtnTable 
	SELECT @isNewWFEngine

	RETURN 
END

/*	Debug:

PARAMETERS:
	@reqType		INT,
	@reqTypeNo		INT

	SELECT * FROM secuser.fnCheckIfNewWFEngine(7, 155)			--PAF
	SELECT * FROM secuser.fnCheckIfNewWFEngine(4, 144036)		--Leave Requisition
	SELECT * FROM secuser.fnCheckIfNewWFEngine(6, 40113695)		--TSR
	SELECT * FROM secuser.fnCheckIfNewWFEngine(18, 126)			--Recruitment Requisition
	SELECT * FROM secuser.fnCheckIfNewWFEngine(16, 27)			--Clearance Form
	SELECT * FROM secuser.fnCheckIfNewWFEngine(11, 450)			--EPMS
	SELECT * FROM secuser.fnCheckIfNewWFEngine(21, 1)			--EPMS
	SELECT * FROM secuser.fnCheckIfNewWFEngine(20, 1003)		--ECR
*/
