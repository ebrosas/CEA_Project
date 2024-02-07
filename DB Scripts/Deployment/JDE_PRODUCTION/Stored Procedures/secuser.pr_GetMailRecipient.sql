/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.05.04 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			21-Mar-2016 1:00PM
	Modified the code to handle the new Invoice Requisition

	2.2					Ervin				17-Feb-2019 02:35 PM
	Refactored the code to enhance data retrieval performance

	2.3					Shoukhat			27-Feb-2020 5:00PM
	Modified the code to handle the Employmee Contract Renewal Requisition

	2.4					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_GetMailRecipient
(
	@mailRepMailID INT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

	-- Member Type
	DECLARE @MEMBER_TYPE_SUPERINTENDENT varchar(10)
	DECLARE @MEMBER_TYPE_COST_CENTER_HEAD varchar(10)
	DECLARE @MEMBER_TYPE_INDIVIDUAL_USER varchar(10)
	DECLARE @MEMBER_TYPE_USER varchar(10)
	DECLARE @MEMBER_TYPE_DISTRIBUTION_GROUP varchar(10)
	DECLARE @MEMBER_TYPE_PARAMETER varchar(10)
	DECLARE @MEMBER_TYPE_IMMEDIATE_SUPERVISOR varchar(10)

	SET @MEMBER_TYPE_SUPERINTENDENT			= 'SINT'
	SET @MEMBER_TYPE_COST_CENTER_HEAD		= 'CCH'
	SET @MEMBER_TYPE_INDIVIDUAL_USER		= 'INVEMP'
	SET @MEMBER_TYPE_USER					= 'USR'
	SET @MEMBER_TYPE_DISTRIBUTION_GROUP		= 'DISTGRP'
	SET @MEMBER_TYPE_PARAMETER				= 'PARAM'
	SET @MEMBER_TYPE_IMMEDIATE_SUPERVISOR	= 'IMSUPERV'

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_TSR int
	DECLARE @REQUEST_TYPE_PAF int
	DECLARE @REQUEST_TYPE_EPA int
	DECLARE @REQUEST_TYPE_CLRFRM int
	DECLARE @REQUEST_TYPE_SIR int
	DECLARE @REQUEST_TYPE_RR int	-- ver 2.0
	DECLARE @REQUEST_TYPE_IR int	-- ver 2.1
	DECLARE @REQUEST_TYPE_ECR int	-- ver 2.3
	DECLARE @REQUEST_TYPE_CEA INT	-- ver 2.4

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18	-- ver 2.0
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.1
	SET @REQUEST_TYPE_ECR		= 20	-- ver 2.3
	SET @REQUEST_TYPE_CEA		= 22	-- ver 2.4

	-- Declare necessary parameter
	DECLARE @reqType int
	DECLARE @reqTypeNo int
	DECLARE @memberType varchar(10)

	DECLARE @empNo int
	DECLARE @empName varchar(50)
	DECLARE @empEmail varchar(150)
	DECLARE @costCenter varchar(12)
	DECLARE @managerEmpNo int
	DECLARE @managerEmpName varchar(50)
	DECLARE @superintendentEmpNo int
	DECLARE @superintendentEmpName varchar(50)
	DECLARE @supervisorEmpNo int
	DECLARE @supervisorEmpName varchar(50)

	-- Retrieves the request type
	SELECT @reqType = a.ProcessReqType, @reqTypeNo = a.ProcessReqTypeNo
	FROM secuser.ProcessWF AS a WITH (NOLOCK) INNER JOIN
		secuser.TransActivity AS b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID INNER JOIN
		secuser.ActivityMailMessage AS c WITH (NOLOCK) ON b.ActID = c.MailActID
	WHERE c.MailID = @mailRepMailID

	-- Checks the Request Type
	IF @reqType = @REQUEST_TYPE_LEAVE
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.EmpNo, @empName = a.EmpName, @empEmail = a.EmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.BusinessUnit = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.RequisitionNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_PR
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.PREmpNo, @empName = a.PREmpName, @empEmail = a.PREmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.PRCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.PRDocNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_TSR
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.TSREmpNo, @empName = a.TSREmpName, @empEmail = a.TSREmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
				secuser.EmployeeMaster AS f WITH (NOLOCK) ON a.TSREmpNo = f.EmpNo INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON f.CostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.TSRNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_PAF
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.PAFEmpNo, @empName = a.PAFEmpName, @empEmail = a.PAFEmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
				secuser.F55PAF AS f WITH (NOLOCK) ON a.PAFAutoID = f.PAG55AUTO INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON LTRIM(RTRIM(CASE WHEN a.PAFNewCostCenter = 0 THEN a.PAFEmpCostCenter ELSE f.PAMCU END)) = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.PAFNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_EPA
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.EPAEmpNo, @empName = a.EPAEmpName, @empEmail = a.EPAEmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.EPAEmpCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.EPANo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.ClrFormEmpNo, @empName = a.ClrFormEmpName, @empEmail = a.ClrFormEmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.ClrFormCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.ClrFormNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_SIR
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.SIREmpNo, @empName = a.SIREmpName, @empEmail = a.SIREmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.SIRWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.SIREmpCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.SIRNo = @reqTypeNo

	END
	-- ver 2.0 Start
	ELSE IF @reqType = @REQUEST_TYPE_RR
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.RRCreatedBy, @empName = a.RRCreatedByName, @empEmail = a.RRCreatedByEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.RRCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.RRNo = @reqTypeNo

	END
	-- ver 2.0 Start End

	-- ver 2.1 Start
	ELSE IF @reqType = @REQUEST_TYPE_IR
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = a.IRCreatedByEmpNo, @empName = a.IRCreatedByEmpName, @empEmail = a.IRCreatedByEmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.IRChargedCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo
			WHERE a.IRNo = @reqTypeNo

	END
	-- ver 2.1 Start End

	ELSE IF @reqType = @REQUEST_TYPE_ECR  -- ver 2.3 Start
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = f.EmpNo, @empName = f.EmpName, @empEmail = f.EmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.EmployeeContractRenewalWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON a.ECRCostCenter = b.CostCenter INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo LEFT JOIN 
				secuser.EmployeeMaster AS f WITH (NOLOCK) ON f.EmpNo = a.ECRCreatedBy
			WHERE a.ECRNo = @reqTypeNo

	END  -- ver 2.3 Start End

	ELSE IF @reqType = @REQUEST_TYPE_CEA  -- ver 2.4 Start
	BEGIN

		-- Retrieves owner information
		SELECT @empNo = f.EmpNo, @empName = f.EmpName, @empEmail = f.EmpEmail, @costCenter = b.CostCenter,
				@managerEmpNo = b.ManagerNo, @managerEmpName = c.EmpName,
				@superintendentEmpNo = b.SuperintendentNo, @superintendentEmpName = d.EmpName,
				@supervisorEmpNo = c.SupervisorNo, @supervisorEmpName = ISNULL(e.EmpName, '')
			FROM secuser.CEAWF AS a WITH (NOLOCK) INNER JOIN
				secuser.CostCenter AS b WITH (NOLOCK) ON RTRIM(a.CEACostCenter) = RTRIM(b.CostCenter) INNER JOIN
				secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo INNER JOIN
				secuser.EmployeeMaster AS d WITH (NOLOCK) ON b.SuperintendentNo = d.EmpNo LEFT JOIN
				secuser.EmployeeMaster AS e WITH (NOLOCK) ON c.SupervisorNo = e.EmpNo LEFT JOIN 
				secuser.EmployeeMaster AS f WITH (NOLOCK) ON f.EmpNo = a.CEACreatedBy
			WHERE a.CEARequisitionNo = @reqTypeNo

	END  -- ver 2.4 Start End
	
	
	--SELECT @empNo, @empName, @empEmail, @costCenter,
	--	@managerEmpNo, @managerEmpName, @superintendentEmpNo, @superintendentEmpName,
	--	@supervisorEmpNo, @supervisorEmpName

	-- Returns the mail recipients
	SELECT a.MailRepID, a.MailRepMailID, a.MailRepType, a.MailRepValueType, a.MailRepDistListID,

			CASE WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT THEN @superintendentEmpNo
				WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN @managerEmpNo
				WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.MailRepEmpNo
				WHEN b.UDCCode = @MEMBER_TYPE_USER THEN @empNo
				WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN (SELECT n.DistMemEmpNo
																		FROM secuser.DistributionMember AS n WITH (NOLOCK)
																		WHERE n.DistMemDistListID = a.MailRepDistListID)
				WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN 0
				WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR THEN @supervisorEmpNo
			END AS MailRepEmpNo,

			CASE WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT THEN @superintendentEmpName
				WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN @managerEmpName
				WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.MailRepEmpName
				WHEN b.UDCCode = @MEMBER_TYPE_USER THEN @empName
				WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN (SELECT n.DistMemEmpName
																		FROM secuser.DistributionMember AS n WITH (NOLOCK)
																		WHERE n.DistMemDistListID = a.MailRepDistListID)
				WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN d.ParamValue
				WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR THEN @supervisorEmpName
			END AS MailRepEmpName,

			CASE WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT THEN ''
				WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN ''
				WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.MailRepEmpEmail
				WHEN b.UDCCode = @MEMBER_TYPE_USER THEN @empEmail
				WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN (SELECT n.DistMemEmpEmail
																		FROM secuser.DistributionMember AS n WITH (NOLOCK)
																		WHERE n.DistMemDistListID = a.MailRepDistListID)
				WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN d.ParamValue
				WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR THEN ''
			END AS MailRepEmpEmail,

			ISNULL(a.MailRepParamID, 0) AS MailRepParamID,
			ISNULL(c.DistListCode, '') AS MailRepDistListCode
		FROM secuser.MailRecipient AS a WITH (NOLOCK) INNER JOIN
			secuser.UserDefinedCode AS b WITH (NOLOCK) ON a.MailRepValueType = b.UDCID LEFT JOIN
			secuser.DistributionList AS c WITH (NOLOCK) ON a.MailRepDistListID = c.DistListID LEFT JOIN
			secuser.TransParameter AS d WITH (NOLOCK) ON a.MailRepParamID = d.ParamID
		WHERE a.MailRepMailID = @mailRepMailID
		ORDER BY a.MailRepType

END 