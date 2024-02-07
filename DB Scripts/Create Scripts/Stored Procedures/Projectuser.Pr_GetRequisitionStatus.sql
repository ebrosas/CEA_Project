/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetRequisitionStatus 
*	Description: This procedure is used to fetch the requisition status
*
*	Date:			Author:		Rev.#:		Comments:
*	18/04/2023		Ervin		1.0			Created
*	
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetRequisitionStatus 
(
    @requisitionID  INT
)
AS
BEGIN

	SET NOCOUNT ON 

	DECLARE @useNewWF BIT = 0

	SELECT @useNewWF = a.UseNewWF
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE a.RequisitionID = @requisitionID

	IF @useNewWF = 1
	BEGIN

		SELECT	tbl.RequisitionID, tbl.ApprovalGroup, tbl.ApproverEmpNo, tbl.ApproverEmpName, ISNULL(tbl.ApproverPosition, '') AS ApproverPosition,
				'' AS LeaveStatus, tbl.CurrentStatus, tbl.StatusCode,
				tbl.ApprovedDate, ISNULL(tbl.ApproverRemarks, '') AS ApproverComment, tbl.CostCenter, tbl.CostCenterName,
				tbl.SubmittedDate, tbl.CreateBy, tbl.SubstituteEmpNo, tbl.SubstituteEmpName,
				tbl.GroupRountingSequence, tbl.RoutingSequence, tbl.StatusHandlingCode, tbl.IsAnonymousUser
		FROM
		(
			SELECT	a.RequisitionID,
					RTRIM(d.ActDesc) AS ApprovalGroup,
					CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN ISNULL(e2.EmpNo, e.EmpNo) 
						WHEN RTRIM(d.ActCode) = 'APP_SUPERT' THEN ISNULL(f2.EmpNo, f.EmpNo) 
						WHEN RTRIM(d.ActCode) = 'APP_CCMNGR' THEN ISNULL(g2.EmpNo, g.EmpNo) 
						WHEN RTRIM(d.ActCode) = 'APP_ITMCAT' THEN ISNULL(h2.EmpNo, h.EmpNo) 
						WHEN RTRIM(d.ActCode) = 'APP_GMO' THEN ISNULL(i2.EmpNo, i.EmpNo)
						WHEN RTRIM(d.ActCode) = 'APP_CFO' THEN ISNULL(j2.EmpNo, j.EmpNo)
						WHEN RTRIM(d.ActCode) = 'APP_CEOBUD' THEN k.EmpNo
						WHEN RTRIM(d.ActCode) = 'APP_CEONBD' THEN k2.EmpNo
						WHEN RTRIM(d.ActCode) = 'APP_CHRBUD' THEN l.EmpNo
						WHEN RTRIM(d.ActCode) = 'APP_CHRNBD' THEN l2.EmpNo 
						ELSE NULL
					END AS ApproverEmpNo,
					CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN CAST(ISNULL(e2.EmpNo, e.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(e2.EmpName, e.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_SUPERT' THEN CAST(ISNULL(f2.EmpNo, f.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(f2.EmpName, f.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_CCMNGR' THEN CAST(ISNULL(g2.EmpNo, g.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(g2.EmpName, g.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_ITMCAT' THEN CAST(ISNULL(h2.EmpNo, h.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(h2.EmpName, h.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_GMO' THEN CAST(ISNULL(i2.EmpNo, i.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(i2.EmpName, i.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_CFO' THEN CAST(ISNULL(j2.EmpNo, j.EmpNo) AS VARCHAR(8)) + ' - ' + ISNULL(j2.EmpName, j.EmpName)
						WHEN RTRIM(d.ActCode) = 'APP_CEOBUD' THEN CAST(k.EmpNo AS VARCHAR(8)) + ' - ' + k.EmpName
						WHEN RTRIM(d.ActCode) = 'APP_CEONBD' THEN CAST(k2.EmpNo AS VARCHAR(8)) + ' - ' + k2.EmpName
						WHEN RTRIM(d.ActCode) = 'APP_CHRBUD' THEN CAST(l.EmpNo AS VARCHAR(8)) + ' - ' + l.EmpName
						WHEN RTRIM(d.ActCode) = 'APP_CHRNBD' THEN CAST(l2.EmpNo AS VARCHAR(8)) + ' - ' + l2.EmpName
						ELSE ''
					END AS ApproverEmpName,
					CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN ISNULL(e2.Position, e.Position)
						WHEN RTRIM(d.ActCode) = 'APP_SUPERT' THEN ISNULL(f2.Position, f.Position)
						WHEN RTRIM(d.ActCode) = 'APP_CCMNGR' THEN ISNULL(g2.Position, g.Position)
						WHEN RTRIM(d.ActCode) = 'APP_ITMCAT' THEN ISNULL(h2.Position, h.Position)
						WHEN RTRIM(d.ActCode) = 'APP_GMO' THEN ISNULL(i2.Position, i.Position)
						WHEN RTRIM(d.ActCode) = 'APP_CFO' THEN j.Position
						WHEN RTRIM(d.ActCode) = 'APP_CEOBUD' THEN k.Position
						WHEN RTRIM(d.ActCode) = 'APP_CEONBD' THEN k2.Position
						WHEN RTRIM(d.ActCode) = 'APP_CHRBUD' THEN l.Position
						WHEN RTRIM(d.ActCode) = 'APP_CHRNBD' THEN l2.Position
						ELSE ''
					END AS ApproverPosition,
					CASE WHEN d.ActStatusID = 106 THEN 'Pending' 
						WHEN d.ActStatusID = 107 THEN 'In-progress' 
						WHEN d.ActStatusID = 108 THEN 'Bypassed' 
						WHEN d.ActStatusID = 109 THEN 'Completed' 
						ELSE 'Unknown'
					END AS CurrentStatus,
					'' AS StatusCode,
					m.ApprovedDate,		
					m.ApproverRemarks,
					b.CEACostCenter AS CostCenter,
					n.CostCenterName,
					a.CreateDate AS SubmittedDate,
					a.CreateBy,
					NULL AS SubstituteEmpNo,
					NULL AS SubstituteEmpName,
					d.ActSeq AS GroupRountingSequence,
					0 AS RoutingSequence,
					RTRIM(o.UDCSpecialHandlingCode) AS StatusHandlingCode,
					1 AS IsAnonymousUser --a2.IsAnonymousUser

			FROM dbo.Requisition a WITH (NOLOCK)
				INNER JOIN dbo.Project a1 WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(a1.ProjectNo)
				--CROSS APPLY
				--(
				--	SELECT y.IsAnonymousUser 
				--	FROM dbo.RequisitionStatus x WITH (NOLOCK)
				--		INNER JOIN dbo.RequisitionStatusDetail y WITH (NOLOCK) ON x.RequisitionStatusID = y.RequisitionStatusID
				--	WHERE x.RequisitionID = a.RequisitionID
				--) a2
				INNER JOIN projectuser.sy_CEAWF b WITH (NOLOCK) ON CAST(a.RequisitionNo AS INT) = b.CEARequisitionNo 
				INNER JOIN Projectuser.sy_ProcessWF c WITH (NOLOCK) ON CAST(c.ProcessReqTypeNo AS INT) = b.CEARequisitionNo AND c.ProcessReqType = 22 
				INNER JOIN Projectuser.sy_TransActivity d WITH (NOLOCK) ON c.ProcessID = d.ActProcessID	AND d.ActType = 1 AND d.ActStatusID <> 108	
				OUTER APPLY	
				(
					SELECT x.EmpNo AS EmpNo, RTRIM(x.EmpName) AS EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position
					FROM Projectuser.Vw_MasterEmployeeJDE x
					WHERE x.EmpNo = Projectuser.fnGetWFParamValue(b.CEARequisitionNo, 'RequestOrigEmpNo')
				) e
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_ORIG')
				) e2
				OUTER APPLY
				(
					--Get the Superintendent
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CCSUPERDNT', RTRIM(b.CEACostCenter), 0) x			
				) f
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_SUPERT')
				) f2
				OUTER APPLY
				(
					--Get the Cost Center Manager
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position
					FROM Projectuser.fnGetWFActionMember('CCMANAGER', RTRIM(b.CEACostCenter), 0) x			
				) g
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_CCMNGR')
				) g2
				OUTER APPLY
				(
					--Get the Item Category approver
					SELECT y.EmpNo, y.EmpName, Projectuser.fnGetEmployeePosition(y.EmpNo) AS Position 
					FROM dbo.ApplicationUserRequisitionCategory x WITH (NOLOCK)
						CROSS APPLY Projectuser.fnGetWFActionMember(RTRIM(x.DistGroupCode), '', 0) y			
					WHERE RTRIM(x.RequisitionCategoryCode) = RTRIM(b.CEAItemCatCode)
						AND b.CEARequireItemApp = 1
				) h
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_ITMCAT')
				) h2
				OUTER APPLY
				(
					--Get the GMO
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position  
					FROM Projectuser.fnGetWFActionMember('OPGENMNGR', '', 0) x		
					WHERE b.CEAIsUnderGMO = 1	
				) i
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_GMO')
				) i2
				OUTER APPLY
				(
					--Get the CFO
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CFO', '', 0) x			
				) j
				OUTER APPLY	
				(
					SELECT * FROM Projectuser.fnGetWFActorAssignee(b.CEARequisitionNo, 'APP_CFO')
				) j2
				OUTER APPLY
				(
					--Get the CEO
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CEO', '', 0) x		
					WHERE RTRIM(a1.ProjectType) = 'Budgeted' 
						AND b.CEATotalAmount > 20000
				) k
				OUTER APPLY
				(
					--Get the CEO
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CEO', '', 0) x		
					WHERE RTRIM(a1.ProjectType) = 'NonBudgeted' 
						AND b.CEATotalAmount > 5000
				) k2
				OUTER APPLY
				(
					--Get the Chairman
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CHAIRMNSEC', '', 0) x	
					WHERE RTRIM(a1.ProjectType) = 'Budgeted' 
						AND b.CEATotalAmount > 100000
				) l
				OUTER APPLY
				(
					--Get the Chairman
					SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
					FROM Projectuser.fnGetWFActionMember('CHAIRMNSEC', '', 0) x	
					WHERE RTRIM(a1.ProjectType) = 'NonBudgeted' 
						AND b.CEATotalAmount > 50000
				) l2
				OUTER APPLY
				(
					SELECT	x.AppModifiedBy AS ApprovedByEmpNo,
							RTRIM(y.EmpName) AS ApprovedByEmpName,
							RTRIM(x.AppRemarks) AS ApproverRemarks,
							x.AppModifiedDate AS ApprovedDate	
					FROM Projectuser.sy_Approval x WITH (NOLOCK)
						INNER JOIN Projectuser.Vw_MasterEmployeeJDE y WITH (NOLOCK) ON x.AppModifiedBy = y.EmpNo
					WHERE x.AppActID = d.ActID
				) m
				LEFT JOIN Projectuser.Master_CostCenter n WITH (NOLOCK) ON RTRIM(b.CEACostCenter) = RTRIM(n.CostCenter)
				LEFT JOIN Projectuser.UserDefinedCode o WITH (NOLOCK) ON b.CEAStatusID = o.UDCID
			WHERE a.RequisitionID = @requisitionID
		) tbl
		WHERE ISNULL(tbl.ApproverEmpName, '') <> ''
		ORDER BY tbl.GroupRountingSequence	
    END
	
	ELSE 
	BEGIN
    
		SELECT  DISTINCT 
				c.RequisitionID,
				--a.RequisitionStatusID,
				RTRIM(e.ApprovalGroupType) AS ApprovalGroup,
				g.EmpNo AS ApproverEmpNo,
				CAST(g.EmpNo AS VARCHAR(10)) + ' - ' + RTRIM(g.EmpName) AS ApproverEmpName, 
				ISNULL(RTRIM(Projectuser.GetEmployeeDesignation(g.EmpNo)),'Designation Unknown') AS ApproverPosition,
				ISNULL
				(
					(
						SELECT CASE COUNT(*)
									WHEN 0 THEN 'Available'
									WHEN NULL THEN 'Available'
									ELSE 'On Leave - from ' + CONVERT(VARCHAR, yy.FromDate, 103) + ' to ' + CONVERT(VARCHAR, yy.ToDate, 103)
								END	
							FROM (
									SELECT TOP 1
										EmpNo,
										FromDate,
										ToDate
									FROM Projectuser.Tran_Leave_JDE WITH (NOLOCK)
									WHERE EmpNo = g.EmpNo AND
										(CONVERT(VARCHAR, GETDATE(), 110) BETWEEN FromDate AND ToDate OR FromDate BETWEEN GETDATE() AND CONVERT(VARCHAR, GETDATE() + 3, 110))
								ORDER BY FromDate DESC
								) yy
							GROUP BY EmpNo, FromDate, ToDate
					), 
					'Available'
				) AS LeaveStatus,
				i.CurrentStatus,
				i.StatusCode,
				a.StatusDate AS ApprovedDate,						
				a.ApproverComment,
				d.CostCenter,
				j.CostCenterName,			
				a.SubmittedDate,
				c.CreateBy,
				h.SubstituteEmpNo,
				h.SubstituteEmpName,
				a.GroupRountingSequence,
				a.RoutingSequence,
				i.StatusHandlingCode,
				a.IsAnonymousUser	
		 FROM 
			(
				SELECT	a.PermanentStatus,
						a.RoutingSequence,
						a.SubmittedDate,
						a.ApprovalStatusID,
						a.StatusDate,
						a.ApprovalGroupID,
						a.ApproverComment,
						a.ApplicationUserID,
						a.RequisitionStatusID,
						a.GroupRountingSequence,
						a.IsAnonymousUser
				FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
				WHERE a.RequisitionStatusID = 
					(
						SELECT RequisitionStatusID
						FROM dbo.RequisitionStatus WITH (NOLOCK)
						WHERE RequisitionID = @RequisitionID 
					)
					AND a.ApprovalStatusID <> 10

				UNION 	

				SELECT TOP 1 
					a.PermanentStatus,
					a.RoutingSequence,
					a.SubmittedDate,
					a.ApprovalStatusID,
					a.StatusDate,
					a.ApprovalGroupID,
					a.ApproverComment,
					a.ApplicationUserID,
					a.RequisitionStatusID,
					CASE WHEN a.GroupRountingSequence < 0 
						THEN (SELECT MAX(GroupRountingSequence) + 1 FROM dbo.RequisitionStatusDetail WITH (NOLOCK) WHERE RequisitionStatusID = a.RequisitionStatusID ) 
						ELSE a.GroupRountingSequence 
					END AS GroupRountingSequence,		--Note: Display the Cancelled state always at the last row
					a.IsAnonymousUser
				FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
				WHERE a.RequisitionStatusID = 
					(
						SELECT RequisitionStatusID
						FROM dbo.RequisitionStatus WITH (NOLOCK)
						WHERE RequisitionID = @RequisitionID	
					)
					AND a.ApprovalStatusID = 10
				ORDER BY a.StatusDate DESC
			) a
			INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionStatusID = b.RequisitionStatusID
			INNER JOIN dbo.Requisition c WITH (NOLOCK) ON c.RequisitionID = b.RequisitionID
			LEFT JOIN dbo.ApprovalGroup d WITH (NOLOCK) ON d.ApprovalGroupID = a.ApprovalGroupID
			LEFT JOIN dbo.ApprovalGroupType e WITH (NOLOCK) ON e.ApprovalGroupTypeID = d.ApprovalGroupTypeID
			INNER JOIN dbo.Project f WITH (NOLOCK) ON RTRIM(f.ProjectNo) = RTRIM(c.ProjectNo)
        
			--INNER JOIN dbo.ApplicationUser g WITH (NOLOCK) ON a.ApplicationUserID = g.ApplicationUserID
			CROSS APPLY
			(
				SELECT x.EmployeeNo AS EmpNo, x.FullName AS EmpName, x.ApplicationUserID 
				FROM dbo.ApplicationUser x WITH (NOLOCK)
				WHERE x.ApplicationUserID = a.ApplicationUserID

				UNION
            
				SELECT x.EmpNo, x.EmpName, x.EmpNo AS ApplicationUserID 
				FROM Projectuser.Vw_MasterEmployeeJDE x
				WHERE x.EmpNo = a.ApplicationUserID
					AND a.IsAnonymousUser = 1
			) g
			--CROSS APPLY Projectuser.fnGetApproverList(RTRIM(c.RequisitionNo)) g

			OUTER APPLY
			(
				SELECT x.SubstituteUserID, y.EmployeeNo AS SubstituteEmpNo, RTRIM(y.FullName) AS SubstituteEmpName  
				FROM dbo.ApplicationUserSubstitute x WITH (NOLOCK) 
					INNER JOIN dbo.ApplicationUser y WITH (NOLOCK) ON y.ApplicationUserID = x.ApplicationUserID
				WHERE x.ApplicationUserID = g.ApplicationUserID
			) h
			OUTER APPLY
			(
				SELECT	--RTRIM(y.UDCSpecialHandlingCode) AS CurrentStatus,
						RTRIM(x.ApprovalStatus) AS CurrentStatus,
						RTRIM(x.WFStatusCode) AS StatusCode, 
						RTRIM(y.UDCDesc1) AS StatusDesc, 
						RTRIM(y.UDCSpecialHandlingCode) AS StatusHandlingCode 
				FROM dbo.ApprovalStatus x WITH (NOLOCK) 
					LEFT JOIN Projectuser.UserDefinedCode y WITH (NOLOCK) ON RTRIM(x.WFStatusCode) = RTRIM(y.UDCCode) AND y.UDCUDCGID = 9
				WHERE x.ApprovalStatusID = a.ApprovalStatusID
			) i
			OUTER APPLY
			(
				SELECT CostCenterName 
				FROM Projectuser.Master_CostCenter x WITH (NOLOCK) 
				WHERE RTRIM(x.CostCenter) = RTRIM(f.CostCenter) 
			) j
		WHERE b.RequisitionID = @RequisitionID
		ORDER BY a.GroupRountingSequence, a.RoutingSequence, a.IsAnonymousUser
	END 

END 

/*	Debug:

PARAMETER:
	@requisitionID  INT

	EXEC Projectuser.Pr_GetRequisitionStatus 4197		--Using DB workflow

*/