DECLARE	@UDCGCode varchar(10),
        @UDCGDesc1 varchar(50),
        @UDCGDesc2 varchar(50),
		@isCommitTran bit

	/************************************** Add Expenditure Types ************************/
	--SELECT	@UDCGCode = 'EXPDTRTYPE',
	--		@UDCGDesc1 = 'Expenditure Types',
	--		@UDCGDesc2 = 'Expenditure Types used in the new CEA App',
	--		@isCommitTran = 1
	/*************************************************************************************/

	/************************************** Add Pedding Approval Types ************************/
	SELECT	@UDCGCode = 'APVTYPES',
			@UDCGDesc1 = 'Pending Approval Types',
			@UDCGDesc2 = 'Approval Types used in the new CEA App',
			@isCommitTran = 1
	/*************************************************************************************/


	IF NOT EXISTS 
	(
		SELECT UDCGID FROM genuser.UserDefinedCodeGroup 
		WHERE RTRIM(UDCGCode) = @UDCGCode
	)
	BEGIN

		BEGIN TRAN T1

		INSERT INTO genuser.UserDefinedCodeGroup
        (
			UDCGCode,
			UDCGDesc1,
			UDCGDesc2
		)
		SELECT	@UDCGCode, 
				@UDCGDesc1,
				@UDCGDesc2

		SELECT * FROM genuser.UserDefinedCodeGroup WHERE (RTRIM(UDCGCode)) = @UDCGCode

		IF @isCommitTran = 1
			COMMIT TRAN T1
		ELSE
			ROLLBACK TRAN T1
	END


/*	Debugging:

	SELECT * FROM genuser.UserDefinedCodeGroup ORDER BY UDCGID
	SELECT * FROM genuser.UserDefinedCodeGroup WHERE RTRIM(UDCGCode) = 'APVTYPES'

	BEGIN TRAN T1	

	DELETE FROM genuser.UserDefinedCodeGroup where UDCGID = 10

	ROLLBACK TRAN T1
	COMMIT TRAN T1

*/



