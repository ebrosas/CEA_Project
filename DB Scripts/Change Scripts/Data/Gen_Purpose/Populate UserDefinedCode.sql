DECLARE	@actionType				TINYINT = 0,	--(Notes: 0 = Check records, 1 = Insert new record)
		@isCommitTrans			BIT = 0,
		@UDCUDCGID				INT,
		@UDCCode				VARCHAR(10) = '600',
		@UDCDesc1				VARCHAR(50),
		@UDCDesc2				VARCHAR(50)  = NULL,
		@UDCSpecialHandlingCode VARCHAR(50) = NULL

	SELECT @UDCUDCGID = a.UDCGID
	FROM genuser.UserDefinedCodeGroup a
	WHERE RTRIM(a.UDCGCode) = 'STATUS'

	IF @actionType = 0
	BEGIN
    
		SELECT * FROM [genuser].[UserDefinedCode] a WITH (NOLOCK)
		WHERE RTRIM(a.UDCCode) = @UDCCode

		--Get all UDCs
		SELECT * FROM [genuser].[UserDefinedCode] a WITH (NOLOCK)
		WHERE a.UDCUDCGID = @UDCUDCGID
		ORDER BY CAST(a.UDCCode AS INT)
	END 

	ELSE IF @actionType = 1
	BEGIN    		

		--Add "Uploaded to OneWorld"
		--SELECT	@UDCCode = '600',
		--		@UDCDesc1 = 'Uploaded to OneWorld',
		--		@UDCSpecialHandlingCode = 'Open'

		--Add "Awaiting Chairman Approval"
		--SELECT	@UDCCode = '601',
		--		@UDCDesc1 = 'Awaiting Chairman Approval',
		--		@UDCSpecialHandlingCode = 'Open'

		--Add "Chairman Approved"
		--SELECT	@UDCCode = '602',
		--		@UDCDesc1 = 'Chairman Approved',
		--		@UDCSpecialHandlingCode = 'Approved'

		--Add "Reactivated"
		--SELECT	@UDCCode = '603',
		--		@UDCDesc1 = 'Reactivated',
		--		@UDCSpecialHandlingCode = 'Open'

		--Add "Completed"
		--SELECT	@UDCCode = '604',
		--		@UDCDesc1 = 'Completed',
		--		@UDCSpecialHandlingCode = 'Closed'

		--Add "Draft"
		--SELECT	@UDCCode = '605',
		--		@UDCDesc1 = 'Draft',
		--		@UDCSpecialHandlingCode = 'Draft'

		--Add "All Open Statuses"
		--SELECT	@UDCCode = '606',
		--		@UDCDesc1 = 'All Open Statuses',
		--		@UDCSpecialHandlingCode = 'All Open Statuses'

		BEGIN TRAN T1

		INSERT INTO [genuser].[UserDefinedCode]
		(
			[UDCUDCGID],
			[UDCCode],
			[UDCDesc1],
			[UDCDesc2],
			[UDCSpecialHandlingCode]
		)
		SELECT	@UDCUDCGID,
				@UDCCode,
				@UDCDesc1,
				@UDCDesc2,
				@UDCSpecialHandlingCode

		--Check before commit
		SELECT * FROM [genuser].[UserDefinedCode] a WITH (NOLOCK)
		WHERE RTRIM(a.UDCCode) = @UDCCode

		IF @isCommitTrans = 1
			COMMIT TRAN T1
		ELSE
			ROLLBACK TRAN T1
	END 

    ELSE IF @actionType = 2
	BEGIN

		--SELECT	@UDCCode = '600',
		--		@UDCDesc1 = 'Uploaded to OneWorld',
		--		@UDCSpecialHandlingCode = 'Open'

		SELECT	@UDCCode = '606',
				@UDCDesc1 = 'Draft and Submitted',
				@UDCSpecialHandlingCode = 'All Open Statuses'

		BEGIN TRAN T1

		UPDATE [genuser].[UserDefinedCode]
		SET UDCDesc1 = @UDCDesc1,
			UDCSpecialHandlingCode = @UDCSpecialHandlingCode
		WHERE RTRIM(UDCCode) = @UDCCode

		--Check before commit
		SELECT * FROM [genuser].[UserDefinedCode] a WITH (NOLOCK)
		WHERE RTRIM(a.UDCCode) = @UDCCode

		IF @isCommitTrans = 1
			COMMIT TRAN T1
		ELSE
			ROLLBACK TRAN T1
    END 