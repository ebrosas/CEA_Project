DECLARE	@UDCGCode VARCHAR(10),
		@UDCUDCGID INT,
        @UDCCode VARCHAR(10),
        @UDCDesc1 VARCHAR(500),
        @UDCDesc2 VARCHAR(500),
        @UDCSpecialHandlingCode VARCHAR(50),
        @UDCDate DATETIME,
        @UDCAmount DECIMAL(18,0),
        @UDCField VARCHAR(10),
		@isCommitTran BIT


	--/*	Populate Expenditure Types 

		SET @UDCGCode = 'EXPDTRTYPE'
		SELECT	@UDCUDCGID = UDCGID FROM genuser.UserDefinedCodeGroup WHERE (RTRIM(UDCGCode)) = @UDCGCode

		SELECT	@UDCCode = 'CEA',
				@UDCDesc1 = 'Capital Expenditure Approval',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 1,
				@UDCField = NULL,
				@isCommitTran = 1

		SELECT	@UDCCode = 'MRE',
				@UDCDesc1 = 'Major Revenue Expenditure',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 2,
				@UDCField = NULL,
				@isCommitTran = 1

		SELECT	@UDCCode = 'INC',
				@UDCDesc1 = 'Item Non-Capitalized',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 3,
				@UDCField = NULL,
				@isCommitTran = 1

		SELECT	@UDCCode = 'SPR',
				@UDCDesc1 = 'Spares',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 4,
				@UDCField = NULL,
				@isCommitTran = 1
	--*/

	/*	Populate Pending Approval Types 

		SET @UDCGCode = 'APVTYPES'
		SELECT	@UDCUDCGID = UDCGID FROM genuser.UserDefinedCodeGroup WHERE (RTRIM(UDCGCode)) = @UDCGCode

		SELECT	@UDCCode = 'ASGNTOME',
				@UDCDesc1 = 'Show requisitions assigned to me',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 1,
				@UDCField = 'Active',
				@isCommitTran = 1

		SELECT	@UDCCode = 'ASGNTOALL',
				@UDCDesc1 = 'Show requisitions assigned to all',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 2,
				@UDCField = 'Inactive',
				@isCommitTran = 1

		SELECT	@UDCCode = 'ASGNTOOTHR',
				@UDCDesc1 = 'Show requisitions assigned to others',
				@UDCDesc2 = NULL,
				@UDCSpecialHandlingCode = NULL,
				@UDCDate = NULL,
				@UDCAmount = 3,
				@UDCField = 'Active',
				@isCommitTran = 1
	*/

	IF NOT EXISTS 
	(
		SELECT UDCID FROM genuser.UserDefinedCode 
		WHERE UDCUDCGID = @UDCUDCGID 
			AND UPPER(RTRIM(UDCCode)) = @UDCCode
	)
	BEGIN

		BEGIN TRAN T1

		
		INSERT INTO genuser.UserDefinedCode
		(
			[UDCUDCGID]
			,[UDCCode]
			,[UDCDesc1]
			,[UDCDesc2]
			,[UDCSpecialHandlingCode]
			,[UDCDate]
			,[UDCAmount]
			,[UDCField]
		)
		SELECT	@UDCUDCGID, 
				@UDCCode, 
				@UDCDesc1,
				@UDCDesc2,
				@UDCSpecialHandlingCode, 
				@UDCDate, 
				@UDCAmount, 
				@UDCField

		SELECT * FROM genuser.UserDefinedCode WHERE UDCUDCGID = @UDCUDCGID ORDER BY UDCID

		IF @isCommitTran = 1
			COMMIT TRAN T1
		ELSE
			ROLLBACK TRAN T1
	END

	ELSE
	BEGIN
		
		SELECT * FROM genuser.UserDefinedCode 
		WHERE UDCUDCGID = @UDCUDCGID 
			AND UPPER(RTRIM(UDCCode)) = @UDCCode
	END


/*	Debugging:

	--Approvat Types
	SELECT * FROM genuser.UserDefinedCode 
	WHERE UDCUDCGID = (SELECT UDCGID FROM genuser.UserDefinedCodeGroup WHERE RTRIM(UDCGCode) = 'APVTYPES')
	ORDER BY UDCAmount
	

	BEGIN TRAN T1	

	UPDATE genuser.UserDefinedCode 
	SET UDCDesc1 = 'Mark Absent, but not absent'
	WHERE UDCID = 3470

	DELETE FROM genuser.UserDefinedCode 
	WHERE UDCUDCGID = (SELECT UDCGID FROM genuser.UserDefinedCodeGroup WHERE RTRIM(UDCGCode) = 'APVTYPES')

	DELETE FROM genuser.UserDefinedCode where UDCUDCGID = 54
	DELETE FROM genuser.UserDefinedCode where UDCID = 3426

	ROLLBACK TRAN T1
	COMMIT TRAN T1

*/
