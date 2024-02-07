
	
	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'Executive Manager – Finance'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CFO'
		WHERE RTRIM(ApprovalGroupType) = 'Executive Manager – Finance'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'GM-Ops'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'OPGENMNGR'
		WHERE RTRIM(ApprovalGroupType) = 'GM-Ops'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'Chief Executive Officer'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CEO'
		WHERE RTRIM(ApprovalGroupType) = 'Chief Executive Officer'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'Chairman'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CHAIRMNSEC'
		WHERE RTRIM(ApprovalGroupType) = 'Chairman'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'Superintendent'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CCSUPERDNT'
		WHERE RTRIM(ApprovalGroupType) = 'Superintendent'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'Manager'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CCMANAGER'
		WHERE RTRIM(ApprovalGroupType) = 'Manager'

		COMMIT TRAN T1
	*/

	SELECT a.DistGroupCode, * FROM dbo.ApprovalGroupType a WITH (NOLOCK)
	WHERE RTRIM(a.ApprovalGroupType) = 'General Manager'
	/*
		BEGIN TRAN T1

		UPDATE dbo.ApprovalGroupType 
		SET DistGroupCode = 'CEO'
		WHERE RTRIM(ApprovalGroupType) = 'General Manager'

		COMMIT TRAN T1
	*/

	