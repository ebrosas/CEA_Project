/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.05.04 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			21-Mar-2016 11:59 AM
	Modified the code to handle the new Invoice Requisition

	2.2					Ervin				07-Feb-2019 02:00 PM
	Refactored the code to enhance performance

	2.3					Shoukhat			27-Feb-2020 04:30PM
	Modified the code to handle Employee Contract Renewal Requisition

	2.4					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_GetCurrentDistributionMember
(
	@reqType INT,
	@reqTypeNo INT
)
AS
BEGIN 

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

    -- Define Request Type
    DECLARE @REQUEST_TYPE_LEAVE INT
    DECLARE @REQUEST_TYPE_PR INT
    DECLARE @REQUEST_TYPE_TSR INT
    DECLARE @REQUEST_TYPE_PAF INT
    DECLARE @REQUEST_TYPE_EPA INT
    DECLARE @REQUEST_TYPE_CLRFRM INT
	DECLARE @REQUEST_TYPE_RR INT		--ver 2.0
	DECLARE @REQUEST_TYPE_IR INT		--ver 2.1
	DECLARE @REQUEST_TYPE_ECR INT		--ver 2.3
	DECLARE @REQUEST_TYPE_CEA INT		--ver 2.4

    SELECT @REQUEST_TYPE_LEAVE	= 4
    SELECT @REQUEST_TYPE_PR		= 5
    SELECT @REQUEST_TYPE_TSR	= 6
    SELECT @REQUEST_TYPE_PAF	= 7
    SELECT @REQUEST_TYPE_EPA	= 11
    SELECT @REQUEST_TYPE_CLRFRM	= 16
	SELECT @REQUEST_TYPE_RR		= 18	--ver 2.0
	SELECT @REQUEST_TYPE_IR		= 19	--ver 2.1
	SELECT @REQUEST_TYPE_ECR	= 20	--ver 2.3
	SELECT @REQUEST_TYPE_CEA	= 22	--ver 2.4

    -- Define Cost Center Head Member Type
    DECLARE @MEMBER_TYPE_SUPERINTENDENT VARCHAR(10)
    DECLARE @MEMBER_TYPE_COST_CENTER_HEAD VARCHAR(10)
    DECLARE @MEMBER_TYPE_IMMEDIATE_SUPERVISOR VARCHAR(10)
    DECLARE @MEMBER_TYPE_PARAMETER VARCHAR(10)

    SELECT @MEMBER_TYPE_SUPERINTENDENT           = 'SINT'
    SELECT @MEMBER_TYPE_COST_CENTER_HEAD			= 'CCH'
    SELECT @MEMBER_TYPE_IMMEDIATE_SUPERVISOR		= 'IMSUPERV'
    SELECT @MEMBER_TYPE_PARAMETER                = 'PARAM'

    SELECT a.*,
                    ISNULL(b.DistAltDistMemID, 0) AS DistAltDistMemID,
                    ISNULL(b.DistAltEmpNo, 0) AS DistAltEmpNo, ISNULL(b.DistAltEmpName, '') AS DistAltEmpName,
                    ISNULL(b.DistAltEmpEmail, '') AS DistAltEmpEmail, ISNULL(b.DistAltSeq, 0) AS DistAltSeq
            FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK) LEFT JOIN
                    (SELECT a.DistMemID AS DistAltDistMemID,
                                CASE
                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT b.SuperintendentNo
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.BusinessUnit = b.CostCenter
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT b.ManagerNo
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.BusinessUnit = b.CostCenter
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.EmpNo = b.EmpNo
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT b.SuperintendentNo
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.PRCostCenter = b.CostCenter
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT b.ManagerNo
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.PRCostCenter = b.CostCenter
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PREmpNo = b.EmpNo
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT b.SuperintendentNo
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.TSREmpCostCenter = b.CostCenter
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT b.ManagerNo
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.TSREmpCostCenter = b.CostCenter
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.TSREmpNo = b.EmpNo
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT  c.SuperintendentNo
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.F55PAF AS b WITH (NOLOCK) ON a.PAFAutoID = b.PAG55AUTO INNER JOIN
                                                            secuser.CostCenter AS c WITH (NOLOCK) ON LTRIM(RTRIM(CASE WHEN a.PAFNewCostCenter = 0 THEN a.PAFEmpCostCenter ELSE b.PAMCU END)) = c.CostCenter
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT c.ManagerNo
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.F55PAF AS b WITH (NOLOCK) ON a.PAFAutoID = b.PAG55AUTO INNER JOIN
                                                            secuser.CostCenter AS c WITH (NOLOCK) ON LTRIM(RTRIM(CASE WHEN a.PAFNewCostCenter = 0 THEN a.PAFEmpCostCenter ELSE b.PAMCU END)) = c.CostCenter
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PAFEmpNo = b.EmpNo
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT b.SuperintendentNo
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.EPAEmpCostCenter = b.CostCenter
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT b.ManagerNo
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.EPAEmpCostCenter = b.CostCenter
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.EPAEmpNo = b.EmpNo
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT b.SuperintendentNo
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.ClrFormCostCenter = b.CostCenter
                                                    WHERE a.ClrFormNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT b.ManagerNo
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.ClrFormCostCenter = b.CostCenter
                                                    WHERE a.ClrFormNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT b.SupervisorNo
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.ClrFormEmpNo = b.EmpNo
                                                    WHERE a.ClrFormNo = @reqTypeNo)									
								
									-- ver 2.0 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT b.SuperintendentNo
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.RRCostCenter = b.CostCenter
											WHERE a.RRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT b.ManagerNo
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.RRCostCenter = b.CostCenter
											WHERE a.RRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT b.SupervisorNo
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.RRCreatedBy = b.EmpNo
											WHERE a.RRNo = @reqTypeNo)
									-- ver 2.0 End

									-- ver 2.1 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT b.SuperintendentNo
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.IRChargedCostCenter = b.CostCenter
											WHERE a.IRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT b.ManagerNo
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.IRChargedCostCenter = b.CostCenter
											WHERE a.IRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT b.SupervisorNo
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.IRCreatedByEmpNo = b.EmpNo
											WHERE a.IRNo = @reqTypeNo)
									-- ver 2.1 End

                                        WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN
                                            (SELECT CONVERT(INT, e.ParamValue)
                                                    FROM secuser.ProcessWF AS d WITH (NOLOCK) INNER JOIN
                                                            secuser.TransParameter AS e WITH (NOLOCK) ON d.ProcessID = e.ParamProcessID
                                                    WHERE d.ProcessReqType = @reqType AND d.ProcessReqTypeNo = @reqTypeNo AND
                                                            e.ParamName = a.DistMemEmpName)

                                        ELSE a.DistMemEmpNo
                                END AS DistAltEmpNo,
                                CASE
                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.BusinessUnit = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.BusinessUnit = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_LEAVE THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.EmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.RequisitionNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.PRCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.PRCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_PR THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PREmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.PRDocNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.TSREmpCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.TSREmpCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_TSR THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.TSREmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.TSRNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT d.EmpName
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.F55PAF AS b WITH (NOLOCK) ON a.PAFAutoID = b.PAG55AUTO INNER JOIN
                                                            secuser.CostCenter AS c WITH (NOLOCK) ON LTRIM(RTRIM(CASE WHEN a.PAFNewCostCenter = 0 THEN a.PAFEmpCostCenter ELSE b.PAMCU END)) = c.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS d WITH (NOLOCK) ON c.SuperintendentNo = d.EmpNo
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT d.EmpName
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.F55PAF AS b WITH (NOLOCK) ON a.PAFAutoID = b.PAG55AUTO INNER JOIN
                                                            secuser.CostCenter AS c WITH (NOLOCK) ON LTRIM(RTRIM(CASE WHEN a.PAFNewCostCenter = 0 THEN a.PAFEmpCostCenter ELSE b.PAMCU END)) = c.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS d WITH (NOLOCK) ON c.ManagerNo = d.EmpNo
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_PAF THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.PAFEmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.PAFNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.EPAEmpCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.EPAEmpCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_EPA THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.EPAEmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.EPANo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.ClrFormCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
                                                    WHERE a.ClrFormNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT c.EmpName
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.CostCenter AS b WITH (NOLOCK) ON a.ClrFormCostCenter = b.CostCenter INNER JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
                                                    WHERE a.ClrFormNo = @reqTypeNo)

                                        WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_CLRFRM THEN
                                            (SELECT ISNULL(c.EmpName, '')
                                                    FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
                                                            secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.ClrFormEmpNo = b.EmpNo LEFT JOIN
                                                            secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
                                                    WHERE a.ClrFormNo = @reqTypeNo)
										
									-- ver 2.0 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT c.EmpName
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.RRCostCenter = b.CostCenter INNER JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
											WHERE a.RRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT c.EmpName
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.RRCostCenter = b.CostCenter INNER JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
											WHERE a.RRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_RR THEN
										(SELECT ISNULL(c.EmpName, '')
											FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.RRCreatedBy = b.EmpNo LEFT JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
											WHERE a.RRNo = @reqTypeNo)
									-- ver 2.0 End

									-- ver 2.1 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT c.EmpName
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.IRChargedCostCenter = b.CostCenter INNER JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
											WHERE a.IRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT c.EmpName
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.CostCenter AS b WITH (NOLOCK) ON a.IRChargedCostCenter = b.CostCenter INNER JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
											WHERE a.IRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_IR THEN
										(SELECT ISNULL(c.EmpName, '')
											FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
												secuser.EmployeeMaster AS b WITH (NOLOCK) ON a.IRCreatedByEmpNo = b.EmpNo LEFT JOIN
												secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
											WHERE a.IRNo = @reqTypeNo)
									-- ver 2.1 End

									-- ver 2.3 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_ECR THEN
										(SELECT c.EmpName
											FROM secuser.EmployeeContractRenewalWF AS a INNER JOIN
												secuser.CostCenter AS b ON b.CostCenter = a.ECRCostCenter INNER JOIN
												secuser.EmployeeMaster AS c ON b.SuperintendentNo = c.EmpNo
											WHERE a.ECRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_ECR THEN
										(SELECT c.EmpName
											FROM secuser.EmployeeContractRenewalWF AS a INNER JOIN
												secuser.CostCenter AS b ON b.CostCenter = a.ECRCostCenter INNER JOIN
												secuser.EmployeeMaster AS c ON b.ManagerNo = c.EmpNo
											WHERE a.ECRNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_ECR THEN
										(SELECT ISNULL(c.EmpName, '')
											FROM secuser.EmployeeContractRenewalWF AS a INNER JOIN
												secuser.EmployeeMaster AS b ON b.EmpNo = a.ECREmpNo LEFT JOIN
												secuser.EmployeeMaster AS c ON b.SupervisorNo = c.EmpNo
											WHERE a.ECRNo = @reqTypeNo)
									-- ver 2.3 End

									-- ver 2.4 Start
									WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT AND @reqType = @REQUEST_TYPE_CEA THEN
										(SELECT c.EmpName
										FROM secuser.CEAWF a WITH (NOLOCK) 
											INNER JOIN secuser.CostCenter b WITH (NOLOCK) ON RTRIM(b.CostCenter) = RTRIM(a.CEACostCenter) 
											INNER JOIN secuser.EmployeeMaster c WITH (NOLOCK) ON b.SuperintendentNo = c.EmpNo
										WHERE a.CEARequisitionNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD AND @reqType = @REQUEST_TYPE_CEA THEN
										(SELECT c.EmpName
										FROM secuser.CEAWF AS a WITH (NOLOCK) 
											INNER JOIN secuser.CostCenter AS b WITH (NOLOCK) ON RTRIM(b.CostCenter) = RTRIM(a.CEACostCenter) 
											INNER JOIN secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.ManagerNo = c.EmpNo
										WHERE a.CEARequisitionNo = @reqTypeNo)

									WHEN b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR AND @reqType = @REQUEST_TYPE_CEA THEN
										(SELECT ISNULL(c.EmpName, '') AS EmpName
										FROM secuser.CEAWF AS a WITH (NOLOCK) 
											INNER JOIN secuser.EmployeeMaster AS b WITH (NOLOCK) ON b.EmpNo = a.CEAEmpNo 
											LEFT JOIN secuser.EmployeeMaster AS c WITH (NOLOCK) ON b.SupervisorNo = c.EmpNo
										WHERE a.CEARequisitionNo = @reqTypeNo)
									-- ver 2.4 End

                                    WHEN b.UDCCode = @MEMBER_TYPE_PARAMETER THEN
                                        (SELECT f.EmpName
                                                FROM secuser.ProcessWF AS d WITH (NOLOCK) INNER JOIN
                                                        secuser.TransParameter AS e WITH (NOLOCK) ON d.ProcessID = e.ParamProcessID INNER JOIN
                                                        secuser.EmployeeMaster AS f WITH (NOLOCK) ON CONVERT(INT, e.ParamValue) = f.EmpNo
                                                WHERE d.ProcessReqType = @reqType AND d.ProcessReqTypeNo = @reqTypeNo AND
                                                        e.ParamName = a.DistMemEmpName)

                                    ELSE a.DistMemEmpName
                                END AS DistAltEmpName,
                                CASE
                                        WHEN b.UDCCode = @MEMBER_TYPE_SUPERINTENDENT OR
                                            b.UDCCode = @MEMBER_TYPE_COST_CENTER_HEAD OR
                                            b.UDCCode = @MEMBER_TYPE_IMMEDIATE_SUPERVISOR OR
                                            b.UDCCode = @MEMBER_TYPE_PARAMETER THEN ''
                                        ELSE a.DistMemEmpEmail
                                END AS DistAltEmpEmail,
                                a.DistMemSeq AS DistAltSeq
                        FROM secuser.DistributionMember AS a WITH (NOLOCK) INNER JOIN
                                secuser.UserDefinedCode AS b WITH (NOLOCK) ON a.DistMemType = b.UDCID
                    UNION
                    SELECT a.DistAltDistMemID,
                                a.DistAltEmpNo, a.DistAltEmpName, a.DistAltEmpEmail,
                                a.DistAltSeq
                        FROM secuser.DistributionMemberAlternate AS a WITH (NOLOCK)) AS b ON a.CurrentDistMemRefID = b.DistAltDistMemID AND
                        a.CurrentDistMemEmpNo <> b.DistAltEmpNo
            WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
                    a.CurrentDistMemCurrent = 1
            ORDER BY a.CurrentDistMemID, b.DistAltSeq
END 

