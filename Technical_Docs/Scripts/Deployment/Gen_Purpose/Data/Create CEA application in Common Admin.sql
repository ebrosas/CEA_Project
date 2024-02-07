DECLARE	@actionType				TINYINT = 0,			--(Notes: 0 = Check records, 1 = Create new application)
		@isCommitTrans			BIT = 0

	DECLARE	@UDCGCode				VARCHAR(10) = 'APP',
			@UDCUDCGID				INT,
			@UDCCode				VARCHAR(10),
			@UDCDesc1				VARCHAR(500),
			@UDCDesc2				VARCHAR(500) = NULL,
			@UDCSpecialHandlingCode VARCHAR(50) = NULL,
			@UDCDate				DATETIME = NULL,
			@UDCAmount				DECIMAL(18,0) = NULL,
			@UDCField				VARCHAR(10) = NULL

	SELECT	@UDCUDCGID = a.UDCGID,
			@UDCCode = 'CEAAPP',
			@UDCDesc1 = 'CEA/MRE Management System'	
	FROM genuser.UserDefinedCodeGroup a WITH (NOLOCK)
	WHERE RTRIM(a.UDCGCode) = 'APP'
			
	IF @actionType = 0
	BEGIN

		--Check records
		SELECT * FROM genuser.UserDefinedCode a 
		WHERE UDCUDCGID = 17
		ORDER BY a.UDCID
    END 

	ELSE IF @actionType = 1
	BEGIN
    
		BEGIN TRAN T1

		IF NOT EXISTS 
		(
			SELECT UDCID FROM genuser.UserDefinedCode 
			WHERE UDCUDCGID = @UDCUDCGID AND UPPER(RTRIM(UDCCode)) = @UDCCode
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

			IF @isCommitTrans = 1
				COMMIT TRAN T1
			ELSE
				ROLLBACK TRAN T1
		END
	END    
		

	

	


/*	Debug:

	--Check all applications
	SELECT * FROM genuser.UserDefinedCode a
	WHERE UDCUDCGID = 17
	ORDER BY a.UDCID

*/