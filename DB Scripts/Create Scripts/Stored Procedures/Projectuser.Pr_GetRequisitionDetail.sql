/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetRequisitionDetail
*	Description: This stored procedure is used to fetch the complete details of the CEA requisition
*
*	Date			Author		Rev. #		Comments:
*	15/05/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetRequisitionDetail
(
	@requisitionNo	VARCHAR(50) = ''
)
AS 
BEGIN
	
	SET NOCOUNT ON 

	DECLARE @CONST_REQUEST_TYPE_CEA INT = 22

	SELECT	a.RequisitionID, 	
			a.RequisitionNo, 		
			a.ProjectNo, 
			b.CostCenter,
			f.CostCenterName,
			b.ExpenditureType AS ExpenditureTypeCode,
			RTRIM(g.UDCDesc1) AS ExpenditureType,			
			a.RequestDate, 
			a.[Description], 
			a.DateofComission, 
			a.PlantLocationID, 
			a.EstimatedLifeSpan, 
			(Projectuser.ProjectBalanceAmt(a.ProjectNo) + RequestedAmt) - AdditionalBudgetAmt AS ProjectBalanceAmt,
			a.AdditionalBudgetAmt, 
			a.RequestedAmt, 
			a.CategoryCode1, 
			a.CategoryCode2, 
			a.CategoryCode3, 
			a.CategoryCode4, 
			a.CategoryCode5, 
			a.CreatedByEmpNo,
			RTRIM(j.EmpName) AS CreatedByEmpName,
			a.CreateDate, 
			a.LastUpdateBy, 
			a.LastUpdateDate,
			a.Reason,
			Projectuser.AccountNo(a.ProjectNo) AS AccountNo,
			(Projectuser.ProjectUsedAmt(a.ProjectNo) - a.RequestedAmt) AS UsedAmount,
			b.ProjectAmount,
			1 AS CurrentApprovalGroupID,
			h.CurrentApproval,
			k.StatusDesc AS RequisitionStatus, 
			k.StatusHandlingCode, 
			a.RequisitionDescription,
			a.ReasonForAdditionalAmt,
			b.FiscalYear,
			a.EquipmentNo,
			d.EquipmentDesc,
			a.EquipmentParentNo,
			e.EquipmentParentDesc,
			a.OriginatorEmpNo,
			RTRIM(c.EmpName) AS OriginatorEmpName,
			'' AS BudgetStatus,
			k.AssignedEmpNo,
			k.AssignedEmpName,
			k.ApprovalStatus,
			l.WorkflowID,
			l.WFActionType,
			l.WFRoutineSequence,
			m.CurrentWFActivity,
			ISNULL(a.UseNewWF, 0) AS UseNewWF,
			n.CEAStatusCode,
			n.CEAStatusDesc
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
		--LEFT JOIN dbo.ApplicationUser c WITH (NOLOCK) ON a.OriginatorEmpNo = c.EmployeeNo
		LEFT JOIN Projectuser.Master_Employee c WITH (NOLOCK) ON a.OriginatorEmpNo = c.EmpNo
		OUTER APPLY
		(
			SELECT TOP 1 RTRIM([Description]) AS EquipmentDesc 
			FROM Projectuser.Master_EquipmentNumber x WITH (NOLOCK)
			WHERE  (RTRIM(x.EquipmentNo) = RTRIM(a.EquipmentNo) AND ISNULL(a.EquipmentNo, '') <> '')
		) d
		OUTER APPLY
		(
			SELECT TOP 1 RTRIM([Description]) AS EquipmentParentDesc 
			FROM Projectuser.Master_EquipmentNumber x WITH (NOLOCK)
			WHERE  (RTRIM(x.EquipmentNo) = RTRIM(a.EquipmentParentNo) AND ISNULL(a.EquipmentParentNo, '') <> '')
		) e
		LEFT JOIN Projectuser.Master_CostCenter f WITH (NOLOCK) ON RTRIM(b.CostCenter) = RTRIM(f.CostCenter) AND RTRIM(f.CostCenterType) NOT IN ('LA','AL')
		OUTER APPLY
		(
			SELECT TOP 1 * FROM Projectuser.UserDefinedCode x WITH (NOLOCK)
			WHERE x.UDCUDCGID = (SELECT UDCGID FROM Projectuser.UserDefinedCodeGroup WITH (NOLOCK) WHERE RTRIM(UDCGCode) = 'EXPDTRTYPE')
		) g
		OUTER APPLY
        (
			SELECT  DISTINCT TOP 1 RTRIM(z.ApprovalGroup) AS CurrentApproval
			FROM dbo.RequisitionStatus x WITH (NOLOCK)
				INNER JOIN dbo.RequisitionStatusDetail y WITH (NOLOCK) ON x.RequisitionStatusID = y.RequisitionStatusID
				INNER JOIN dbo.ApprovalGroup z WITH (NOLOCK) ON z.ApprovalGroupID = y.ApprovalGroupID AND y.GroupRountingSequence = x.CurrentSequence
			WHERE x.RequisitionID = a.RequisitionID
		) h
		LEFT JOIN Projectuser.Vw_MasterEmployeeJDE j WITH (NOLOCK) ON a.CreatedByEmpNo = j.EmpNo
		CROSS APPLY
		(
			SELECT x.EmpNo AS AssignedEmpNo, x.EmpName AS AssignedEmpName, x.StatusCode, x.StatusDesc, x.StatusHandlingCode, x.ApprovalStatus    
			FROM Projectuser.fnGetCEAAssignedPerson(RTRIM(a.RequisitionNo)) x
			WHERE ISNULL(a.UseNewWF, 0) = 0

			UNION 

			SELECT x.EmpNo AS AssignedEmpNo, x.EmpName AS AssignedEmpName, x.StatusCode, x.StatusDesc, x.StatusHandlingCode, x.ApprovalStatus    
			FROM Projectuser.fnGetWFAssignedPerson(RTRIM(a.RequisitionNo)) x
			WHERE a.UseNewWF = 1
		) k
		OUTER APPLY
		(
			SELECT RTRIM(x.CEAWFInstanceID) AS WorkflowID, y.CurrentDistMemActionType AS WFActionType, y.CurrentDistMemRoutineSeq AS WFRoutineSequence
			FROM Projectuser.sy_CEAWF x WITH (NOLOCK) 
				INNER JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.CEARequisitionNo = y.CurrentDistMemReqTypeNo AND y.CurrentDistMemCurrent = 1
				INNER JOIN Projectuser.sy_TransDistributionMember z WITH (NOLOCK) ON y.CurrentDistMemRefID = z.DistMemID
			WHERE RTRIM(x.CEARequisitionNo) = RTRIM(a.RequisitionNo)
				AND y.CurrentDistMemReqType = @CONST_REQUEST_TYPE_CEA
		) l
		OUTER APPLY	
		(
			SELECT TOP 1 RTRIM(y.ActDesc) AS CurrentWFActivity
			FROM Projectuser.sy_ProcessWF x WITH (NOLOCK) 
				INNER JOIN Projectuser.sy_TransActivity y WITH (NOLOCK) ON x.ProcessID = y.ActProcessID
			WHERE x.ProcessReqType = @CONST_REQUEST_TYPE_CEA 
				AND x.ProcessReqTypeNo = CAST(a.RequisitionNo AS INT)
				AND y.ActCurrent = 1
				AND y.ActType = 1
			ORDER BY y.ActSeq
		) m
		OUTER APPLY
        (
			SELECT RTRIM(y.StatusCode) AS  CEAStatusCode, RTRIM(y.ApprovalStatus) AS CEAStatusDesc
			FROM dbo.RequisitionStatus x WITH (NOLOCK)
				INNER JOIN dbo.ApprovalStatus y WITH (NOLOCK) ON x.ApprovalStatusID = y.ApprovalStatusID
			WHERE x.RequisitionID = a.RequisitionID
		) n
	WHERE (RTRIM(a.RequisitionNo) = @requisitionNo OR @requisitionNo IS NULL)

END 

/*	Debug:

	EXEC Projectuser.Pr_GetRequisitionDetail '20230045'		--Draft
	EXEC Projectuser.Pr_GetRequisitionDetail '20210027'		--Asigned to others
	EXEC Projectuser.Pr_GetRequisitionDetail '20230066'		--Asigned to me	
	EXEC Projectuser.Pr_GetRequisitionDetail '20230093'			

*/