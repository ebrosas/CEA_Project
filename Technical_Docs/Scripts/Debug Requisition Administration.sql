
	SELECT a.* 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
	WHERE RTRIM(a.RequisitionNo) = '20230113'