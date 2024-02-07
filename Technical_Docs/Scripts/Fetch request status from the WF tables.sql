
	SELECT * FROM
    (
		SELECT	RTRIM(d.ActDesc) AS ApprovalRole,
				CASE WHEN RTRIM(d.ActCode) = 'APP_ORIG' THEN CAST(e.OrigEmpNo AS VARCHAR(8)) + ' - ' + e.OriEmpName
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
				b.CEARequisitionNo,
				a1.ProjectNo,
				a1.ProjectType			
			--,d.*
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN dbo.Project a1 WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(a1.ProjectNo)
			INNER JOIN projectuser.sy_CEAWF b WITH (NOLOCK) ON CAST(a.RequisitionNo AS INT) = b.CEARequisitionNo 
			INNER JOIN Projectuser.sy_ProcessWF c WITH (NOLOCK) ON CAST(c.ProcessReqTypeNo AS INT) = b.CEARequisitionNo AND c.ProcessReqType = 22 
			INNER JOIN Projectuser.sy_TransActivity d WITH (NOLOCK) ON c.ProcessID = d.ActProcessID	AND d.ActType = 1 AND d.ActStatusID <> 108	
			OUTER APPLY	
			(
				SELECT x.EmpNo AS OrigEmpNo, RTRIM(x.EmpName) AS OriEmpName 
				FROM Projectuser.Vw_MasterEmployeeJDE x
				WHERE x.EmpNo = Projectuser.fnGetWFParamValue(b.CEARequisitionNo, 'RequestOrigEmpNo')
			) e
			OUTER APPLY
			(
				--Get the Superintendent
				SELECT * FROM Projectuser.fnGetWFActionMember('CCSUPERDNT', RTRIM(b.CEACostCenter), 0)			
			) f
			OUTER APPLY
			(
				--Get the Cost Center Manager
				SELECT * FROM Projectuser.fnGetWFActionMember('CCMANAGER', RTRIM(b.CEACostCenter), 0)			
			) g
			OUTER APPLY
			(
				--Get the Item Category approver
				SELECT y.EmpNo, y.EmpName, y.EmpEmail 
				FROM dbo.ApplicationUserRequisitionCategory x WITH (NOLOCK)
					CROSS APPLY Projectuser.fnGetWFActionMember(RTRIM(x.DistGroupCode), '', 0) y			
				WHERE RTRIM(x.RequisitionCategoryCode) = RTRIM(b.CEAItemCatCode)
					AND b.CEARequireItemApp = 1
			) h
			OUTER APPLY
			(
				--Get the GMO
				SELECT * FROM Projectuser.fnGetWFActionMember('OPGENMNGR', '', 0)		
				WHERE b.CEAIsUnderGMO = 1	
			) i
			OUTER APPLY
			(
				--Get the CFO
				SELECT * FROM Projectuser.fnGetWFActionMember('CFO', '', 0)			
			) j
			OUTER APPLY
			(
				--Get the CEO
				SELECT * FROM Projectuser.fnGetWFActionMember('CEO', '', 0)		
				WHERE RTRIM(a1.ProjectType) = 'Budgeted' 
					AND b.CEATotalAmount > 20000
			) k
			OUTER APPLY
			(
				--Get the CEO
				SELECT * FROM Projectuser.fnGetWFActionMember('CEO', '', 0)		
				WHERE RTRIM(a1.ProjectType) = 'NonBudgeted' 
					AND b.CEATotalAmount > 5000
			) k2
			OUTER APPLY
			(
				--Get the Chairman
				SELECT * FROM Projectuser.fnGetWFActionMember('CHAIRMNSEC', '', 0)	
				WHERE RTRIM(a1.ProjectType) = 'Budgeted' 
					AND b.CEATotalAmount > 100000
			) l
			OUTER APPLY
			(
				--Get the Chairman
				SELECT * FROM Projectuser.fnGetWFActionMember('CHAIRMNSEC', '', 0)	
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
		WHERE RTRIM(a.RequisitionNo) = '20230077'
	) tbl
	WHERE ISNULL(tbl.Approver, '') <> ''
	ORDER BY ActivitySequence	

	--SELECT b.*
	--FROM Projectuser.sy_ProcessWF a WITH (NOLOCK) 
	--	INNER JOIN Projectuser.sy_TransParameter b WITH (NOLOCK) ON a.ProcessID = b.ParamProcessID
	--WHERE a.ProcessReqType = 22 
	--	AND a.ProcessReqTypeNo = 20230071
	--	AND RTRIM(b.ParamName) = 'RequestOrigEmpNo'
	--ORDER BY b.ParamSeq 