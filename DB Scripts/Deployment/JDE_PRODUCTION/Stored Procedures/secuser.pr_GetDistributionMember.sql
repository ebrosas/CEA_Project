/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.05.04 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			21-Mar-2016
	Modified the code to handle the new Invoice Requisition

	2.2					Shoukhat			27-Feb-2020
	Modified the code to handle Employee Contract Renewal Requisition

	2.3					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_GetDistributionMember
(
	@reqType			INT,
	@reqTypeNo			INT,
	@actionType			INT,
	@distMemDistListID  INT
)
AS
BEGIN 

	SET NOCOUNT ON 

	-- Member Type
	DECLARE @MEMBER_TYPE_SUPERINTENDENT varchar(10)
	DECLARE @MEMBER_TYPE_COST_CENTER_HEAD varchar(10)
	DECLARE @MEMBER_TYPE_INDIVIDUAL_USER varchar(10)
	DECLARE @MEMBER_TYPE_USER varchar(10)
	DECLARE @MEMBER_TYPE_DISTRIBUTION_GROUP varchar(10)
	DECLARE @MEMBER_TYPE_PARAMETER varchar(10)

	SELECT @MEMBER_TYPE_SUPERINTENDENT		= 'SINT'
	SELECT @MEMBER_TYPE_COST_CENTER_HEAD	= 'CCH'
	SELECT @MEMBER_TYPE_INDIVIDUAL_USER		= 'INVEMP'
	SELECT @MEMBER_TYPE_USER				= 'USR'
	SELECT @MEMBER_TYPE_DISTRIBUTION_GROUP	= 'DISTGRP'
	SELECT @MEMBER_TYPE_PARAMETER			= 'PARAM'

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_RR int		-- ver 2.0
	DECLARE @REQUEST_TYPE_IR int		-- ver 2.1
	DECLARE @REQUEST_TYPE_ECR int		-- ver 2.2
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 2.3

	SELECT @REQUEST_TYPE_LEAVE	= 4
	SELECT @REQUEST_TYPE_PR		= 5
	SELECT @REQUEST_TYPE_RR		= 18	-- ver 2.0
	SELECT @REQUEST_TYPE_RR		= 19	-- ver 2.1
	SELECT @REQUEST_TYPE_ECR	= 20	-- ver 2.2
	SELECT @REQUEST_TYPE_CEA	= 22	-- ver 2.3

	-- Define Action Type
	DECLARE @ACTION_TYPE_APPROVER int
	DECLARE @ACTION_TYPE_SERVICE_PROVIDER int

	SELECT @ACTION_TYPE_APPROVER			= 64
	SELECT @ACTION_TYPE_SERVICE_PROVIDER	= 65

	-- Check the action type
	SELECT a.DistMemID, a.DistMemDistListID, a.DistMemType, a.DistMemAnotherDistListID,
		-- Distribution Member Employee No
		CASE
			WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT o.SuperintendentNo
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.BusinessUnit = o.CostCenter
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT o.SuperintendentNo
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.PRCostCenter = o.CostCenter
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT o.SuperintendentNo
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.RRCostCenter = o.CostCenter
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End

							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT o.SuperintendentNo
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.IRChargedCostCenter = o.CostCenter
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
							
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN -- ver 2.2 Start
								(SELECT o.SuperintendentNo
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.ECRCostCenter = o.CostCenter
									WHERE n.ECRNo = m.ProcessReqTypeNo) -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN	-- ver 2.3 Start
								(SELECT o.SuperintendentNo
								FROM SecUser.CEAWF AS n WITH (NOLOCK) 
									INNER JOIN SecUser.CostCenter AS o WITH (NOLOCK) ON RTRIM(n.CEACostCenter) = RTRIM(o.CostCenter)
								WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)			-- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)
			WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT o.ManagerNo
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.BusinessUnit = o.CostCenter
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT o.ManagerNo
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.PRCostCenter = o.CostCenter
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT o.ManagerNo
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.RRCostCenter = o.CostCenter
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End

							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT o.ManagerNo
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.IRChargedCostCenter = o.CostCenter
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
							
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN -- ver 2.2 Start
								(SELECT o.ManagerNo
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.ECRCostCenter = o.CostCenter
									WHERE n.ECRNo = m.ProcessReqTypeNo) -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN -- ver 2.3 Start
								(SELECT o.ManagerNo
									FROM SecUser.CEAWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON RTRIM(n.CEACostCenter) = RTRIM(o.CostCenter)
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo) -- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)
			WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.DistMemEmpNo
			WHEN b.UDCCode = @MEMBER_TYPE_USER THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT n.EmpNo
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK)
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT n.PREmpNo
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK)
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT n.RRCreatedBy
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK)
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End

							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT n.IRCreatedByEmpNo
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK)
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
														
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN 	-- ver 2.2 Start
								(SELECT n.ECRCreatedBy
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK)
									WHERE n.ECRNo = m.ProcessReqTypeNo)  -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN 	-- ver 2.3 Start
								(SELECT n.CEACreatedBy
									FROM SecUser.CEAWF AS n WITH (NOLOCK)
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)  -- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)

			WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN 0

			WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN
				(SELECT CONVERT(INT, e.ParamValue)
							FROM SecUser.ProcessWF AS d WITH (NOLOCK) INNER JOIN
								SecUser.TransParameter AS e WITH (NOLOCK) ON d.ProcessID = e.ParamProcessID
							WHERE d.ProcessReqType = @reqType AND d.ProcessReqTypeNo = @reqTypeNo AND
								e.ParamName = a.DistMemEmpName)

		END AS DistMemEmpNo,
		-- Distribution Member Employee Name
		CASE
			WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT p.EmpName
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.BusinessUnit = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT p.EmpName
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.PRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT p.EmpName
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.RRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End

							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT p.EmpName
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.IRChargedCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
														
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN  -- ver 2.2 Start
								(SELECT p.EmpName
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.ECRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.ECRNo = m.ProcessReqTypeNo)  -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN  -- ver 2.3 Start
								(SELECT p.EmpName
									FROM SecUser.CEAWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON RTRIM(n.CEACostCenter) = RTRIM(o.CostCenter) INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.SuperintendentNo = p.EmpNo
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)		-- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)
			WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT p.EmpName
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.BusinessUnit = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT p.EmpName
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.PRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT p.EmpName
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.RRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End
							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT p.EmpName
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.IRChargedCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
														
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN  -- ver 2.2 Start
								(SELECT p.EmpName
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON n.ECRCostCenter = o.CostCenter INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.ECRNo = m.ProcessReqTypeNo)  -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN  -- ver 2.3 Start
								(SELECT p.EmpName
									FROM SecUser.CEAWF AS n WITH (NOLOCK) INNER JOIN
										SecUser.CostCenter AS o WITH (NOLOCK) ON RTRIM(n.CEACostCenter) = RTRIM(o.CostCenter) INNER JOIN
										SecUser.EmployeeMaster AS p WITH (NOLOCK) ON o.ManagerNo = p.EmpNo
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)		-- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)
			WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.DistMemEmpName
			WHEN b.UDCCode = @MEMBER_TYPE_USER THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT n.EmpName
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK)
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)

							WHEN m.ProcessReqType = @REQUEST_TYPE_PR THEN
								(SELECT n.PREmpName
									FROM SecUser.PurchaseRequisitionWF AS n WITH (NOLOCK)
									WHERE n.PRDocNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT n.RRCreatedByName
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK)
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End
							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT n.IRCreatedByEmpNo
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK)
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN  -- ver 2.2 Start
								(SELECT n.ECREmpNo
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK)
									WHERE n.ECRNo = m.ProcessReqTypeNo)  -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN  -- ver 2.3 Start
								(SELECT n.CEAEmpNo
									FROM SecUser.CEAWF AS n WITH (NOLOCK)
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)		-- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)

			WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN ''

			WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN
				(SELECT f.EmpName
							FROM SecUser.ProcessWF AS d WITH (NOLOCK) INNER JOIN
								SecUser.TransParameter AS e WITH (NOLOCK) ON d.ProcessID = e.ParamProcessID INNER JOIN
								SecUser.EmployeeMaster AS f WITH (NOLOCK) ON CONVERT(INT, e.ParamValue) = f.EmpNo
							WHERE d.ProcessReqType = @reqType AND d.ProcessReqTypeNo = @reqTypeNo AND
								e.ParamName = a.DistMemEmpName)

		END AS DistMemEmpName,
		-- Distribution Member Employee Email
		CASE
			WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD THEN ''
			WHEN b.UDCCode = @MEMBER_TYPE_INDIVIDUAL_USER THEN a.DistMemEmpEmail
			WHEN b.UDCCode = @MEMBER_TYPE_USER THEN
				(SELECT CASE
							WHEN m.ProcessReqType = @REQUEST_TYPE_LEAVE THEN
								(SELECT n.EmpEmail
									FROM SecUser.LeaveRequisition AS n WITH (NOLOCK)
									WHERE n.RequisitionNo = m.ProcessReqTypeNo)
							-- ver 2.0 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_RR THEN
								(SELECT n.RRCreatedByEmail
									FROM SecUser.RecruitmentRequisitionWF AS n WITH (NOLOCK)
									WHERE n.RRNo = m.ProcessReqTypeNo)
							-- ver 2.0 End
							-- ver 2.1 Start
							WHEN m.ProcessReqType = @REQUEST_TYPE_IR THEN
								(SELECT n.IRCreatedByEmpEmail
									FROM SecUser.InvoiceRequisitionWF AS n WITH (NOLOCK)
									WHERE n.IRNo = m.ProcessReqTypeNo)
							-- ver 2.1 End
							
							WHEN m.ProcessReqType = @REQUEST_TYPE_ECR THEN  -- ver 2.2 Start
								(SELECT  mm.EmpEmail
									FROM SecUser.EmployeeContractRenewalWF AS n WITH (NOLOCK)
										INNER JOIN secuser.EmployeeMaster AS mm WITH (NOLOCK) ON mm.EmpNo = n.ECREmpNo
									WHERE n.ECRNo = m.ProcessReqTypeNo)  -- ver 2.2 End

							WHEN m.ProcessReqType = @REQUEST_TYPE_CEA THEN			-- ver 2.3 Start
								(SELECT  mm.EmpEmail
									FROM SecUser.CEAWF AS n WITH (NOLOCK)
										INNER JOIN secuser.EmployeeMaster AS mm WITH (NOLOCK) ON mm.EmpNo = n.CEAEmpNo
									WHERE n.CEARequisitionNo = m.ProcessReqTypeNo)  -- ver 2.3 End
							
						END
					FROM SecUser.ProcessWF AS m WITH (NOLOCK)
					WHERE m.ProcessReqType = @reqType AND m.ProcessReqTypeNo = @reqTypeNo)
			WHEN b.UDCCode = @MEMBER_TYPE_DISTRIBUTION_GROUP THEN ''
			WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN ''
		END AS DistMemEmpEmail,
		a.DistMemPrimary, a.DistMemApproval, a.DistMemThreshold, a.DistMemEscalate, a.DistMemRoutineSeq,
		a.DistMemSeq, a.DistMemStatusID
	FROM SecUser.DistributionMember AS a WITH (NOLOCK) INNER JOIN
		SecUser.UserDefinedCode AS b WITH (NOLOCK) ON a.DistMemType = b.UDCID
	WHERE a.DistMemDistListID = @distMemDistListID AND a.DistMemCurrent = 1
	ORDER BY a.DistMemRoutineSeq, a.DistMemSeq

END 







