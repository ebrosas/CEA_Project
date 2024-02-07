	SELECT d.ActionEmpNo, d.ActionEmpName, d.Position, c.ActionDistListID, b.*
	FROM Projectuser.sy_ProcessWF a WITH (NOLOCK)
		INNER JOIN Projectuser.sy_TransActivity b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID
		INNER JOIN Projectuser.sy_ActivityAction c WITH (NOLOCK) ON b.ActID = c.ActionActID
		OUTER APPLY
		(
			SELECT  y.CurrentDistMemEmpNo AS ActionEmpNo, y.CurrentDistMemEmpName AS ActionEmpName, RTRIM(z.Position) AS Position 
			FROM Projectuser.sy_Trans_DistributionMember x WITH (NOLOCK)
				INNER JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.DistMemID = y.CurrentDistMemRefID
				INNER JOIN Projectuser.Vw_MasterEmployeeJDE z WITH (NOLOCK) ON y.CurrentDistMemEmpNo = z.EmpNo
			WHERE x.DistMemPrimary = 1
				AND y.CurrentDistMemReqType = a.ProcessReqType
				AND y.CurrentDistMemReqTypeNo = a.ProcessReqTypeNo
				AND x.DistMemDistListID = c.ActionDistListID
		) d
	WHERE a.ProcessReqType = 22 
		AND a.ProcessReqTypeNo = 20230135
		--AND RTRIM(b.ActCode) = 'APP_ITMCAT'
	ORDER BY b.ActSeq

	SELECT y.CurrentDistMemEmpNo AS ActionEmpNo, y.CurrentDistMemEmpName AS ActionEmpName, RTRIM(z.Position) AS Position, y.CurrentDistMemID,
		x.DistMemDistListID, y.*
	FROM Projectuser.sy_Trans_DistributionMember x WITH (NOLOCK)
		LEFT JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.DistMemID = y.CurrentDistMemRefID
		LEFT JOIN Projectuser.Vw_MasterEmployeeJDE z WITH (NOLOCK) ON y.CurrentDistMemEmpNo = z.EmpNo
	WHERE x.DistMemPrimary = 1
		AND y.CurrentDistMemReqType = 22
		AND y.CurrentDistMemReqTypeNo = 20230135
		--AND x.DistMemDistListID = c.ActionDistListID