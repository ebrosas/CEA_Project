/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetRequestWFStatus 
*	Description: This procedure is used to fetch the workflow approval status
*
*	Date:			Author:		Rev.#:		Comments:
*	21/09/2023		Ervin		1.0			Created
*	
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetRequestWFStatus 
(
    @ceaNo  VARCHAR(50)
)
AS
BEGIN

	SET NOCOUNT ON 		

	SELECT tbl.ApprovalRole, tbl.Approver, ISNULL(tbl.ApproverPosition, '') AS ApproverPosition,
		tbl.CurrentStatus, tbl.ApprovedDate, tbl.ApproverRemarks, tbl.ActivityID, tbl.ActivityCode,
		tbl.ActivitySequence, tbl.ProjectNo, tbl.ProjectType
	FROM
    (
		SELECT	RTRIM(d.ActDesc) AS ApprovalRole,
				CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN CAST(e.EmpNo AS VARCHAR(8)) + ' - ' + e.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_SUPERT' THEN CAST(f.EmpNo AS VARCHAR(8)) + ' - ' + f.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CCMNGR' THEN CAST(g.EmpNo AS VARCHAR(8)) + ' - ' + g.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_ITMCAT' THEN CAST(h.EmpNo AS VARCHAR(8)) + ' - ' + h.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_GMO' THEN CAST(i.EmpNo AS VARCHAR(8)) + ' - ' + i.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CFO' THEN CAST(j.EmpNo AS VARCHAR(8)) + ' - ' + j.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CEOBUD' THEN CAST(k.EmpNo AS VARCHAR(8)) + ' - ' + k.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CEONBD' THEN CAST(k2.EmpNo AS VARCHAR(8)) + ' - ' + k2.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CHRBUD' THEN CAST(l.EmpNo AS VARCHAR(8)) + ' - ' + l.EmpName
					WHEN RTRIM(d.ActCode) = 'APP_CHRNBD' THEN CAST(l2.EmpNo AS VARCHAR(8)) + ' - ' + l2.EmpName
					ELSE ''
				END AS Approver,
				CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN e.Position
					WHEN RTRIM(d.ActCode) = 'APP_SUPERT' THEN f.Position
					WHEN RTRIM(d.ActCode) = 'APP_CCMNGR' THEN g.Position
					WHEN RTRIM(d.ActCode) = 'APP_ITMCAT' THEN h.Position
					WHEN RTRIM(d.ActCode) = 'APP_GMO' THEN i.Position
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
				m.ApprovedDate,		
				m.ApproverRemarks,
				d.ActID AS ActivityID,	
				d.ActCode AS ActivityCode,
				d.ActSeq AS ActivitySequence,
				a1.ProjectNo,
				a1.ProjectType			
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN dbo.Project a1 WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(a1.ProjectNo)
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
				--Get the Superintendent
				SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
				FROM Projectuser.fnGetWFActionMember('CCSUPERDNT', RTRIM(b.CEACostCenter), 0) x			
			) f
			OUTER APPLY
			(
				--Get the Cost Center Manager
				SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position
				FROM Projectuser.fnGetWFActionMember('CCMANAGER', RTRIM(b.CEACostCenter), 0) x			
			) g
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
				--Get the GMO
				SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position  
				FROM Projectuser.fnGetWFActionMember('OPGENMNGR', '', 0) x		
				WHERE b.CEAIsUnderGMO = 1	
			) i
			OUTER APPLY
			(
				--Get the CFO
				SELECT x.EmpNo, x.EmpName, Projectuser.fnGetEmployeePosition(x.EmpNo) AS Position 
				FROM Projectuser.fnGetWFActionMember('CFO', '', 0) x			
			) j
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
		WHERE RTRIM(a.RequisitionNo) = @ceaNo
	) tbl
	WHERE ISNULL(tbl.Approver, '') <> ''
	ORDER BY ActivitySequence	

	/*	Test Data:

		SELECT	'Originator' AS ApprovalRole, 
				'10003589 - NAGENDRA SEETHARAM' AS Approver, 
				'HEAD OF NETWORK INFRASTRUCTURE' AS ApproverPosition,
				'In-progress' AS CurrentStatus, 
				GETDATE() AS ApprovedDate, 
				'' AS ApproverRemarks, 
				3945966 AS ActivityID, 
				'APP_ORIG' AS ActivityCode,
				3 AS ActivitySequence, 
				'2210073' AS ProjectNo, 
				'Budgeted' AS ProjectType

		UNION
    
		SELECT	'Superintendent' AS ApprovalRole, 
				'10003656 - TAFSIR AHMAD SIDDIQ AHMAD' AS Approver, 
				'SOFTWARE DEVELOPER ' AS ApproverPosition,
				'Pending' AS CurrentStatus, 
				NULL AS ApprovedDate, 
				'' AS ApproverRemarks, 
				3945968 AS ActivityID, 
				'APP_SUPERT' AS ActivityCode,
				5 AS ActivitySequence, 
				'2210073' AS ProjectNo, 
				'Budgeted' AS ProjectType
	
	*/
END 



/*	Debug:

	EXEC Projectuser.Pr_GetRequestWFStatus '20230137'

*/