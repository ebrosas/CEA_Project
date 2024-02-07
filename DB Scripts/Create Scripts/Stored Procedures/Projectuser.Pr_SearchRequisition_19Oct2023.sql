/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_SearchRequisition 
*	Description: This SP will return a list of Requisitions
*
*	Date:			Author:		Rev.#:		Comments:
*	26/03/2023		Ervin		1.0			Created
*	12/10/2023		Antony		1.1			Added "EquipmentNo" field
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SearchRequisition
( 	
	@projectNo			VARCHAR(12) = '',	
	@requisitionNo		VARCHAR(12) = '',		
	@expenditureType	VARCHAR(10) = '',	
	@fiscalYear			SMALLINT = 0,
	@statusCode			VARCHAR(50) = '',
	@costCenter			VARCHAR(12) = '',	
	@empNo				INT = 0,
	@approvalType		VARCHAR(10) = '',	
	@keyWords			VARCHAR(50) = '',
	@startDate			DATETIME = NULL,
	@endDate			DATETIME = NULL,
	@createdByType		TINYINT = 0			--(Notes: 0 = All, 1 = Me, 2 = Others)		 
)
AS 
BEGIN 

	DECLARE @approvalStatusID	INT = 0,
			@applicationUserID	INT = 0,
			@userCostCenter		VARCHAR(12) = ''

	--Validate parameters
	IF ISNULL(@projectNo, '') = ''
		SET @projectNo = NULL

	IF ISNULL(@requisitionNo, '') = ''
		SET @requisitionNo = NULL

	IF ISNULL(@expenditureType, '') = ''
		SET @expenditureType = NULL

	IF ISNULL(@statusCode, '') = ''
		SET @statusCode = NULL

	IF ISNULL(@costCenter, '') = ''
		SET @costCenter = NULL

	IF ISNULL(@createdByType, 0) = 0
		SET @createdByType = NULL

	--Get the current user cost center
	SELECT @userCostCenter = RTRIM(a.BusinessUnit)
	FROM Projectuser.Vw_MasterEmployeeJDE a
	WHERE a.EmpNo = @empNo

	IF ISNULL(@empNo, 0) > 0
	BEGIN
		
		SELECT @applicationUserID = CAST(a.ApplicationUserID AS INT)
		FROM dbo.ApplicationUser a WITH (NOLOCK) 
		WHERE a.EmployeeNo = @empNo
    END 
	ELSE 
		SET @empNo = NULL

	IF ISNULL(@approvalType, '') = ''
		SET @approvalType = NULL 

	IF ISNULL(@keyWords, '') = ''
		SET @keyWords = NULL

	IF ISNULL(@fiscalYear, 0) = 0
		SET @fiscalYear = NULL

	IF @approvalType IS NOT NULL		
	BEGIN

		--Get all pending requisitions currently assigned to the logged in user or with another approver
		SELECT	
				a.RequisitionID, 
				a.ProjectNo, 
				CAST(b.FiscalYear AS INT) AS FiscalYear,
				a.RequisitionNo, 
				a.RequestDate AS RequisitionDate, 
				RTRIM(b.ExpenditureType) + ' - ' + RTRIM(a.[Description]) AS 'Description', 
				a.DateofComission, 
				a.RequestedAmt AS Amount,
				RTRIM(d.CostCenterName) AS Plant,
				a.EquipmentNo,
				b.CostCenter,
				b.CompanyCode,
	 			b.ObjectCode,
				b.SubjectCode,
				b.AccountCode,
				Projectuser.RequisitionUsedAmt(a.RequisitionNo) AS UsedAmount,
				a.CreatedByEmpNo,
				a.CreateBy AS CreatedByEmpName,
				a.CreateDate,
				c.StatusHandlingCode,
				c.StatusDesc AS WorkflowStatus,
				c.StatusCode,				
				c.ApprovalStatus,
				c.CEAStatusCode,
				c.CEAStatusDesc,
				c.AssignedToEmpNo,
				c.AssignedToEmpName,
				ISNULL(a.UseNewWF, 0) AS UseNewWF	
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
			CROSS APPLY
            (
				--Get CEAs created using the old database workflow
				SELECT	CAST(u.EmployeeNo AS INT) AS AssignedToEmpNo, 
						RTRIM(u.FullName) AS AssignedToEmpName,
						RTRIM(v.WFStatusCode) AS StatusCode, 
						RTRIM(w.UDCDesc1) AS StatusDesc, 
						RTRIM(w.UDCSpecialHandlingCode) AS StatusHandlingCode, 
						RTRIM(w.UDCSpecialHandlingCode) AS ApprovalStatus,
						CASE WHEN RTRIM(v.ApprovalStatus) = 'Draft' THEN 1 ELSE 0 END AS IsDraft,
						RTRIM(v.StatusCode) AS CEAStatusCode,
						RTRIM(v.ApprovalStatus) AS CEAStatusDesc
				FROM dbo.RequisitionStatus s WITH (NOLOCK)
					INNER JOIN 
					(
						SELECT m.RequisitionStatusID, m.ApplicationUserID, m.ApprovalStatusID
						FROM dbo.RequisitionStatusDetail m WITH (NOLOCK)
							INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID AND RTRIM(n.StatusCode) IN ('SubmittedForApproval', 'AwaitingChairmanApproval')
					) t ON s.RequisitionStatusID = t.RequisitionStatusID AND t.ApprovalStatusID = 5
					INNER JOIN dbo.ApplicationUser u WITH (NOLOCK) ON t.ApplicationUserID = u.ApplicationUserID
					LEFT JOIN dbo.ApprovalStatus v WITH (NOLOCK) ON s.ApprovalStatusID = v.ApprovalStatusID
					LEFT JOIN Projectuser.UserDefinedCode w WITH (NOLOCK) ON RTRIM(v.WFStatusCode) = RTRIM(w.UDCCode) AND w.UDCUDCGID = 9
				WHERE s.RequisitionID = a.RequisitionID					
					AND ISNULL(a.UseNewWF, 0) = 0
					AND RTRIM(v.StatusHandlingCode) IN ('Open', 'Approved')
					AND (ISNULL(u.EmployeeNo, 0) > 0 AND u.EmployeeNo = @empNo)

				UNION
                
				--Get open CEAs created using the new workflow
				SELECT
					CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN x.CEAOriginatorNo ELSE y.CurrentDistMemEmpNo END AS AssignedToEmpNo,
					CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN RTRIM(x.CEAOriginatorName) ELSE RTRIM(y.CurrentDistMemEmpName) END AS AssignedToEmpName,
					RTRIM(z.UDCCode) AS StatusCode,
					RTRIM(z.UDCDesc1) AS StatusDesc,
					RTRIM(z.UDCSpecialHandlingCode) AS StatusHandlingCode,
					RTRIM(z.UDCSpecialHandlingCode) AS ApprovalStatus,
					ISNULL(x.CEAIsDraft, 0) AS IsDraft,
					v.CEAStatusCode,
					v.CEAStatusDesc      
				FROM Projectuser.sy_CEAWF x WITH (NOLOCK) 
					INNER JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.CEARequisitionNo = y.CurrentDistMemReqTypeNo AND y.CurrentDistMemCurrent = 1 AND y.CurrentDistMemReqType = 22
					INNER JOIN Projectuser.UserDefinedCode z WITH (NOLOCK) ON x.CEAStatusID = z.UDCID AND z.UDCUDCGID = 9
					OUTER APPLY
                    (
						SELECT RTRIM(n.StatusCode) AS  CEAStatusCode, RTRIM(n.ApprovalStatus) AS CEAStatusDesc
						FROM dbo.RequisitionStatus m WITH (NOLOCK)
							INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID
						WHERE m.RequisitionID = a.RequisitionID
					) v
				WHERE RTRIM(x.CEARequisitionNo) = a.RequisitionNo
					AND a.UseNewWF = 1
					AND z.UDCSpecialHandlingCode IN ('Open', 'Approved')
					AND (y.CurrentDistMemEmpNo IS NOT NULL AND y.CurrentDistMemEmpNo = @empNo)									
			) c
			LEFT JOIN Projectuser.Master_CostCenter d WITH (NOLOCK) ON RTRIM(d.CostCenter) = RTRIM(a.PlantLocationID) AND RTRIM(d.CostCenterType) = 'AL'
		WHERE (RTRIM(a.RequisitionNo) = LTRIM(RTRIM(@requisitionNo)) OR @requisitionNo IS NULL)
			AND (RTRIM(a.ProjectNo) = @projectNo OR @projectNo IS NULL)
			AND (RTRIM(b.ExpenditureType) = @expenditureType OR @expenditureType IS NULL)
			AND (RTRIM(b.CostCenter) = @costCenter OR @costCenter IS NULL)
			AND (b.FiscalYear = @fiscalYear OR @fiscalYear IS NULL) 
			AND 
			(
				UPPER(RTRIM(a.[Description])) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
				OR UPPER(RTRIM(a.RequisitionDescription)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
				OR UPPER(RTRIM(a.Reason)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
				OR @keyWords IS NULL 
			)
			AND 
			(
				(a.RequestDate BETWEEN @startDate AND @endDate AND @startDate IS NOT NULL AND @endDate IS NOT NULL)
				OR (@startDate IS NULL AND @endDate IS NULL)
			)		
			--AND c.AssignedToEmpNo = @empNo
			--AND c.StatusHandlingCode = 'Open'
		ORDER BY a.RequisitionNo DESC  
    END 

	ELSE 
	BEGIN
    
		IF @requisitionNo IS NOT NULL OR @projectNo IS NOT NULL 
		BEGIN
		
			--Filter search results based on Project No. or CEA No.
			SELECT	--DISTINCT 
					a.RequisitionID, 
					a.ProjectNo, 
					CAST(b.FiscalYear AS INT) AS FiscalYear,
					a.RequisitionNo, 
					a.RequestDate AS RequisitionDate, 
					RTRIM(b.ExpenditureType) + ' - ' + RTRIM(a.[Description]) AS 'Description', 
					a.DateofComission, 
					a.RequestedAmt AS Amount,
					RTRIM(d.CostCenterName) AS Plant,
					a.EquipmentNo,
					b.CostCenter,
					b.CompanyCode,
	 				b.ObjectCode,
					b.SubjectCode,
					b.AccountCode,
					Projectuser.RequisitionUsedAmt(a.RequisitionNo) AS UsedAmount,
					a.CreatedByEmpNo,
					a.CreateBy AS CreatedByEmpName,
					a.CreateDate,
					c.StatusHandlingCode,
					c.StatusDesc AS WorkflowStatus,
					c.StatusCode,
					c.ApprovalStatus,
					c.CEAStatusCode,
					c.CEAStatusDesc,
					c.AssignedToEmpNo,
					c.AssignedToEmpName,
					ISNULL(a.UseNewWF, 0) AS UseNewWF	
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
				CROSS APPLY
				(
					--Get open CEAs created using the old database workflow
					SELECT TOP 1
						CAST(u.EmployeeNo AS INT) AS AssignedToEmpNo, 
						RTRIM(u.FullName) AS AssignedToEmpName,
						RTRIM(v.WFStatusCode) AS StatusCode, 
						RTRIM(w.UDCDesc1) AS StatusDesc, 
						RTRIM(w.UDCSpecialHandlingCode) AS StatusHandlingCode, 
						RTRIM(w.UDCSpecialHandlingCode) AS ApprovalStatus,
						CASE WHEN RTRIM(v.ApprovalStatus) = 'Draft' THEN 1 ELSE 0 END AS IsDraft,
						RTRIM(v.StatusCode) AS CEAStatusCode,
						RTRIM(v.ApprovalStatus) AS CEAStatusDesc
					FROM dbo.RequisitionStatus s WITH (NOLOCK)
						LEFT JOIN 
						(
							SELECT m.RequisitionStatusID, m.ApplicationUserID, m.ApprovalStatusID
							FROM dbo.RequisitionStatusDetail m WITH (NOLOCK)
								INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID AND RTRIM(n.StatusCode) IN ('SubmittedForApproval', 'AwaitingChairmanApproval')
						) t ON s.RequisitionStatusID = t.RequisitionStatusID AND t.ApprovalStatusID = 5
						LEFT JOIN dbo.ApplicationUser u WITH (NOLOCK) ON t.ApplicationUserID = u.ApplicationUserID
						LEFT JOIN dbo.ApprovalStatus v WITH (NOLOCK) ON s.ApprovalStatusID = v.ApprovalStatusID
						LEFT JOIN Projectuser.UserDefinedCode w WITH (NOLOCK) ON RTRIM(v.WFStatusCode) = RTRIM(w.UDCCode) AND w.UDCUDCGID = 9
					WHERE s.RequisitionID = a.RequisitionID
						AND ISNULL(a.UseNewWF, 0) = 0

					UNION

					--Get open CEAs created using the new workflow
					SELECT
						CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN x.CEAOriginatorNo ELSE y.CurrentDistMemEmpNo END AS AssignedToEmpNo,
						CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN RTRIM(x.CEAOriginatorName) ELSE RTRIM(y.CurrentDistMemEmpName) END AS AssignedToEmpName,
						RTRIM(z.UDCCode) AS StatusCode,
						RTRIM(z.UDCDesc1) AS StatusDesc,
						RTRIM(z.UDCSpecialHandlingCode) AS StatusHandlingCode,
						RTRIM(z.UDCSpecialHandlingCode) AS ApprovalStatus,
						ISNULL(x.CEAIsDraft, 0) AS IsDraft,
						v.CEAStatusCode,
						v.CEAStatusDesc   
					FROM Projectuser.sy_CEAWF x WITH (NOLOCK) 
						LEFT JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.CEARequisitionNo = y.CurrentDistMemReqTypeNo AND y.CurrentDistMemCurrent = 1 AND y.CurrentDistMemReqType = 22
						LEFT JOIN Projectuser.UserDefinedCode z WITH (NOLOCK) ON x.CEAStatusID = z.UDCID AND z.UDCUDCGID = 9
						OUTER APPLY
                        (
							SELECT RTRIM(n.StatusCode) AS CEAStatusCode, RTRIM(n.ApprovalStatus) AS CEAStatusDesc
							FROM dbo.RequisitionStatus m WITH (NOLOCK)
								INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID
							WHERE m.RequisitionID = a.RequisitionID
						) v
					WHERE RTRIM(x.CEARequisitionNo) = a.RequisitionNo
						AND a.UseNewWF = 1
				) c
				LEFT JOIN Projectuser.Master_CostCenter d WITH (NOLOCK) ON RTRIM(d.CostCenter) = RTRIM(a.PlantLocationID) AND RTRIM(d.CostCenterType) = 'AL'
			WHERE (RTRIM(a.RequisitionNo) = LTRIM(RTRIM(@requisitionNo)) OR @requisitionNo IS NULL)
				AND (RTRIM(a.ProjectNo) = @projectNo OR @projectNo IS NULL)
			ORDER BY a.RequisitionNo DESC  
        END 

		ELSE
        BEGIN
        
			--Filter search results based on predefined criteria
			SELECT	a.RequisitionID, 
					a.ProjectNo, 
					CAST(b.FiscalYear AS INT) AS FiscalYear,
					a.RequisitionNo, 
					a.RequestDate AS RequisitionDate, 
					RTRIM(b.ExpenditureType) + ' - ' + RTRIM(a.[Description]) AS 'Description', 
					a.DateofComission, 
					a.RequestedAmt AS Amount,
					RTRIM(d.CostCenterName) AS Plant,
					a.EquipmentNo,
					b.CostCenter,
					b.CompanyCode,
	 				b.ObjectCode,
					b.SubjectCode,
					b.AccountCode,
					Projectuser.RequisitionUsedAmt(a.RequisitionNo) AS UsedAmount,
					a.CreatedByEmpNo,
					a.CreateBy AS CreatedByEmpName,
					a.CreateDate,
					c.StatusHandlingCode,
					c.StatusDesc AS WorkflowStatus,
					c.StatusCode,
					c.ApprovalStatus,
					c.CEAStatusCode,
					c.CEAStatusDesc,
					c.AssignedToEmpNo,
					c.AssignedToEmpName,
					ISNULL(a.UseNewWF, 0) AS UseNewWF,
					c.IsDraft		
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
				CROSS APPLY
				(
					--Get open CEAs created using the old database workflow
					SELECT TOP 1
						CAST(u.EmployeeNo AS INT) AS AssignedToEmpNo, 
						RTRIM(u.FullName) AS AssignedToEmpName,
						RTRIM(v.WFStatusCode) AS StatusCode, 
						RTRIM(w.UDCDesc1) AS StatusDesc, 
						RTRIM(w.UDCSpecialHandlingCode) AS StatusHandlingCode, 
						RTRIM(w.UDCSpecialHandlingCode) AS ApprovalStatus,
						CASE WHEN RTRIM(v.ApprovalStatus) = 'Draft' THEN 1 ELSE 0 END AS IsDraft,
						RTRIM(v.StatusCode) AS CEAStatusCode,
						RTRIM(v.ApprovalStatus) AS CEAStatusDesc
					FROM dbo.RequisitionStatus s WITH (NOLOCK)
						LEFT JOIN 
						(
							SELECT m.RequisitionStatusID, m.ApplicationUserID, m.ApprovalStatusID
							FROM dbo.RequisitionStatusDetail m WITH (NOLOCK)
								INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID AND RTRIM(n.StatusCode) IN ('SubmittedForApproval', 'AwaitingChairmanApproval')
						) t ON s.RequisitionStatusID = t.RequisitionStatusID AND t.ApprovalStatusID = 5
						LEFT JOIN dbo.ApplicationUser u WITH (NOLOCK) ON t.ApplicationUserID = u.ApplicationUserID
						LEFT JOIN dbo.ApprovalStatus v WITH (NOLOCK) ON s.ApprovalStatusID = v.ApprovalStatusID
						LEFT JOIN Projectuser.UserDefinedCode w WITH (NOLOCK) ON RTRIM(v.WFStatusCode) = RTRIM(w.UDCCode) AND w.UDCUDCGID = 9
					WHERE s.RequisitionID = a.RequisitionID
						AND ISNULL(a.UseNewWF, 0) = 0

					UNION

					--Get open CEAs created using the new workflow
					SELECT
						CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN x.CEAOriginatorNo ELSE y.CurrentDistMemEmpNo END AS AssignedToEmpNo,
						CASE WHEN RTRIM(y.CurrentDistMemEmpName) = 'RequestOrigEmpNo' THEN RTRIM(x.CEAOriginatorName) ELSE RTRIM(y.CurrentDistMemEmpName) END AS AssignedToEmpName,
						RTRIM(z.UDCCode) AS StatusCode,
						RTRIM(z.UDCDesc1) AS StatusDesc,
						RTRIM(z.UDCSpecialHandlingCode) AS StatusHandlingCode,
						RTRIM(z.UDCSpecialHandlingCode) AS ApprovalStatus,
						ISNULL(x.CEAIsDraft, 0) AS IsDraft,
						v.CEAStatusCode,
						v.CEAStatusDesc      
					FROM Projectuser.sy_CEAWF x WITH (NOLOCK) 
						LEFT JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.CEARequisitionNo = y.CurrentDistMemReqTypeNo AND y.CurrentDistMemCurrent = 1 AND y.CurrentDistMemReqType = 22
						LEFT JOIN Projectuser.UserDefinedCode z WITH (NOLOCK) ON x.CEAStatusID = z.UDCID AND z.UDCUDCGID = 9
						OUTER APPLY
                        (
							SELECT RTRIM(n.StatusCode) AS  CEAStatusCode, RTRIM(n.ApprovalStatus) AS CEAStatusDesc
							FROM dbo.RequisitionStatus m WITH (NOLOCK)
								INNER JOIN dbo.ApprovalStatus n WITH (NOLOCK) ON m.ApprovalStatusID = n.ApprovalStatusID
							WHERE m.RequisitionID = a.RequisitionID
						) v
					WHERE RTRIM(x.CEARequisitionNo) = a.RequisitionNo
						AND a.UseNewWF = 1
				) c
				LEFT JOIN Projectuser.Master_CostCenter d WITH (NOLOCK) ON RTRIM(d.CostCenter) = RTRIM(a.PlantLocationID) AND RTRIM(d.CostCenterType) = 'AL'
			WHERE (RTRIM(a.RequisitionNo) = LTRIM(RTRIM(@requisitionNo)) OR @requisitionNo IS NULL)
				AND (RTRIM(a.ProjectNo) = @projectNo OR @projectNo IS NULL)
				AND (RTRIM(b.ExpenditureType) = @expenditureType OR @expenditureType IS NULL)
				AND 
				(
					(c.StatusHandlingCode IN ('Open') AND @statusCode = 'All Open Statuses')
					OR (c.IsDraft = 1 AND @statusCode = 'Draft')
					OR (c.StatusHandlingCode = @statusCode AND @statusCode NOT IN ('All Open Statuses', 'Draft'))
					OR @statusCode IS NULL
				)				
				AND (RTRIM(b.CostCenter) = @costCenter OR @costCenter IS NULL)
				AND (b.FiscalYear = @fiscalYear OR @fiscalYear IS NULL) 
				AND 
				(
					UPPER(RTRIM(a.[Description])) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
					OR UPPER(RTRIM(a.RequisitionDescription)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
					OR UPPER(RTRIM(a.Reason)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
					OR @keyWords IS NULL 
				)
				AND 
				(
					(a.RequestDate BETWEEN @startDate AND @endDate AND @startDate IS NOT NULL AND @endDate IS NOT NULL)
					OR (@startDate IS NULL AND @endDate IS NULL)
				)	
				AND 
				(	
					(a.CreatedByEmpNo = @empNo AND @createdByType = 1)
					OR (RTRIM(b.CostCenter) = @userCostCenter AND a.CreatedByEmpNo <> @empNo AND @createdByType = 2)
					OR @createdByType IS NULL
				)	
			ORDER BY a.RequisitionNo DESC  
		END 
	END 

END 	


/*	Debug:

	EXEC Projectuser.Pr_SearchRequisition '2220214'					--Filter by Project No.
	EXEC Projectuser.Pr_SearchRequisition '', '20230114'			--Filter by Requisition No.
	EXEC Projectuser.Pr_SearchRequisition '2220338', '20230049'		--Filter by Project No. and Requisition No.

	EXEC Projectuser.Pr_SearchRequisition null, null, null, 2022, 'All Open Statuses', '7600', 0, null, null, null, null			--All Open Statuses	with fiscal year
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, 'Cancelled', '7600', 0, null, null, null, null						--All Open Statuses	

	EXEC Projectuser.Pr_SearchRequisition null, null, null, 2022, '', null, 10003870, 'ASGNTOME', null, null, null					--Assigned to Me
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, '', null, 10003632, 'ASGNTOME', null, null, null						--Assigned to Me

	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, '', '7600', 10003632, '', null, null, null, 0									--Created by all
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, 'All Open Statuses', '', 10003632, null, null, null, null,  1					--Created by me
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 2022, '', '7600', 10003632, null, null, null, null,  1								--Created by me
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, '', null, 10003632, '', null, null, null, 2										--Created by others
	
	EXEC Projectuser.Pr_SearchRequisition null, null, null, 0, '', null, 10001668, '', null, null, null					--Assigned to Others

PARAMETERS:
	@projectNo			VARCHAR(12) = '',	
	@requisitionNo		VARCHAR(12) = '',		
	@expenditureType	VARCHAR(10) = '',	
	@fiscalYear			SMALLINT = 0,
	@statusCode			VARCHAR(50) = '',
	@costCenter			VARCHAR(12) = '',	
	@empNo				INT = 0,
	@approvalType		VARCHAR(10) = '',	
	@keyWords			VARCHAR(50) = '',
	@startDate			DATETIME = NULL,
	@endDate			DATETIME = NULL,
	@createdByType		TINYINT = 0			--(Notes: 0 = All, 1 = Me, 2 = Others)		 

	--Approval Types
	ASGNTOME	Show requisitions assigned to me
	ASGNTOALL	Show requisitions assigned to all
	ASGNTOOTHR	Show requisitions assigned to others
	

*/
