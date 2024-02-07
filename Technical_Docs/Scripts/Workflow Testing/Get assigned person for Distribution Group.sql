DECLARE	@ceaNo				INT = 20230137,
		@distListCode		VARCHAR(10) = 'APP_SUPERT'

	SELECT d.ActionEmpNo, d.ActionEmpName, d.Position, b.*
	FROM SecUser.ProcessWF a WITH (NOLOCK)
		INNER JOIN SecUser.TransActivity b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID
		INNER JOIN secuser.ActivityAction c WITH (NOLOCK) ON b.ActID = c.ActionActID
		OUTER APPLY
		(
			SELECT TOP 1 y.CurrentDistMemEmpNo AS ActionEmpNo, y.CurrentDistMemEmpName AS ActionEmpName, RTRIM(z.EmpPositionDesc) AS Position 
			FROM secuser.DistributionMember x WITH (NOLOCK)
				INNER JOIN secuser.CurrentDistributionMember y WITH (NOLOCK) ON x.DistMemID = y.CurrentDistMemRefID
				INNER JOIN secuser.EmployeeMaster z WITH (NOLOCK) ON y.CurrentDistMemEmpNo = z.EmpNo
			WHERE x.DistMemPrimary = 1
				AND y.CurrentDistMemReqType = a.ProcessReqType
				AND y.CurrentDistMemReqTypeNo = a.ProcessReqTypeNo
				AND x.DistMemDistListID = c.ActionDistListID
		) d
	WHERE a.ProcessReqType = 22 
		AND a.ProcessReqTypeNo = @ceaNo
		AND RTRIM(b.ActCode) = @distListCode