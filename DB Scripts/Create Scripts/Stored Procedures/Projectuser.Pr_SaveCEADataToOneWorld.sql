/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_SaveCEADataToOneWorld
*	Description: This stored procedure is used to save CEA information into the JDE system
*
*	Date			Author		Rev. #		Comments:
*	05/08/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SaveCEADataToOneWorld 
(
	@requisitionID		INT,				-- CEA/MRE Requisition ID
	@commisionDate		DATETIME,			-- Date of Commission
	@description		VARCHAR(40),		-- Requisition Description
	@projectNo			VARCHAR(12),		-- Cost Center
	@userID				VARCHAR(10),		-- User ID
	@workStationID		VARCHAR(10),		-- Computer Name
	@rowsAffected		INT OUTPUT,
	@hasError			BIT OUTPUT,
	@retError			INT OUTPUT,
	@retErrorDesc		VARCHAR(200) OUTPUT
)
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK	INT = 0,
			@CONST_RETURN_ERROR	INT = -1

	--Define transaction variables
	DECLARE @return_value		INT = 0,
			@retErrorMessage	VARCHAR(1000) = ''

	Declare @searchType 			VARCHAR(10) = 'JA',
			@blankSpace				VARCHAR(5) = '',
			@addressType			CHAR = 'N',
			@zeroValue				NUMERIC = 0,
			@counter				INT = 0,
			@costCenter 			VARCHAR(12) = '',
			@requisitionTmp			VARCHAR(8) = '',
			@requisitionNo			NUMERIC(8) = 0,
			@requisitionDate		DATETIME = NULL

	--Get the cost center
	SELECT @costCenter = RTRIM(a.Costcenter) 
	FROM dbo.Project a WITH (NOLOCK) 
	WHERE RTRIM(a.ProjectNo) = @projectNo
	
	IF ISNULL(@costCenter, '') <> ''
		SET @costCenter = Projectuser.lpad(@costCenter,12,' ')

	--Find the Requisition No.
	SELECT @requisitionTmp = RTRIM(a.RequisitionNo) 
	FROM dbo.Requisition a WITH (NOLOCK) 
	WHERE a.RequisitionID = @requisitionID

	IF ISNULL(@requisitionTmp, '') <> ''
		SET @requisitionNo = CONVERT(numeric, @requisitionTmp)

	--Check if record already exist
	SELECT @counter = COUNT(ABAN8) 
	FROM Projectuser.sy_F0101 a WITH (NOLOCK) 
	WHERE ABAN8 = @requisitionNo

	--If record exist, then perform update operation. Otherwise, insert new record
	IF @counter > 0
	BEGIN
    
		UPDATE Projectuser.sy_F0101 
		SET	ABALPH = @description,										--NameAlpha
			ABDC   = @description,										--DescriptionCompressed
			ABEFTB = Projectuser.ConvertToJulian(@commisionDate),		--DateBeginningEffective
			ABUSER = @userID,											--UserId
			ABJOBN = @workStationID,									--WorkStationId
			ABUPMT = CONVERT(NUMERIC, Projectuser.fmtTime(GETDATE()))	--TimeLastUpdated
		WHERE ABAN8 = @requisitionNo

		--Get the number of affected rows
		SELECT @rowsAffected = @@ROWCOUNT 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END
	END 
	
	ELSE
	BEGIN
    
		--Insert new record
		INSERT INTO Projectuser.sy_F0101 
		(
			ABAN8, 		--AddressNumber, 		--1
			ABALKY, 	--AlternateAddressKey,		--2
			ABTAX, 		--TaxId,			--3
			ABALPH, 	--NameAlpha,			--4
			ABDC, 		--DescriptionCompressed,	--5
			ABMCU, 		--CostCenter,			--6
			ABSIC, 		--StandardIndustryCode,		--7
			ABLNGP, 	--LanguagePreference,		--8	
			ABCM, 		--CreditMessage,		--9
			ABTAXC, 	--PersonCorporationCode,	--10
			ABAT1, 		--AddressType1,			--11
			ABAT2, 		--AddressType2,			--12
			ABAT3, 		--AddressType3,			--13
			ABAT4, 		--AddressType4,			--14
			ABAT5, 		--AddressType5,			--15
			ABATP, 		--AddressTypePayables,		--16
			ABATR, 		--AddressTypeReceivables,	--17
			ABATPR, 	--AddTypeCode4Purch,		--18
			ABAB3, 		--MiscCode3,			--19
			ABATE, 		--AddressTypeEmployee ,		--20
			ABSBLI, 	--SubledgreInactiveCode,	--21
			ABEFTB, 	--DateBeginningEffective,	--22
			ABAN81, 	--AddressNumber1st,		--23
			ABAN82, 	--AddressNumber2nd,		--24
			ABAN83, 	--AddressNumber3rd,		--25
			ABAN84, 	--AddressNumber4th,		--26
			ABAN86, 	--AddressNumber5th,		--27
			ABAN85, 	--AddressNumber6th,		--28
			ABAC01, 	--ReportCodeAddBook001,		--29
			ABAC02, 	--ReportCodeAddBook002,		--30
			ABAC03, 	--ReportCodeAddBook003,		--31
			ABAC04, 	--ReportCodeAddBook004,		--32
			ABAC05, 	--ReportCodeAddBook005,		--33
			ABAC06, 	--ReportCodeAddBook006,		--34
			ABAC07, 	--ReportCodeAddBook007,		--35
			ABAC08, 	--ReportCodeAddBook008,		--36
			ABAC09, 	--ReportCodeAddBook009,		--37
			ABAC10, 	--ReportCodeAddBook010,		--38
			ABAC11, 	--ReportCodeAddBook011,		--39
			ABAC12, 	--ReportCodeAddBook012,		--40
			ABAC13, 	--ReportCodeAddBook013,		--41
			ABAC14, 	--ReportCodeAddBook014,		--42
			ABAC15, 	--ReportCodeAddBook015,		--43
			ABAC16, 	--ReportCodeAddBook016,		--44
			ABAC17, 	--ReportCodeAddBook017,		--45
			ABAC18, 	--ReportCodeAddBook018,		--46
			ABAC19, 	--ReportCodeAddBook019,		--47
			ABAC20, 	--ReportCodeAddBook020,		--48
			ABAC21, 	--CategoryCodeAddressBook2,	--49
			ABAC22, 	--CategoryCodeAddressBk22,	--50
			ABAC23, 	--CategoryCodeAddressBk23,	--51
			ABAC24, 	--CategoryCodeAddressBk24,	--52			ABAC25, 	--CategoryCodeAddressBk25,	--53
			ABAC26, 	--CategoryCodeAddressBk26,	--54
			ABAC27, 	--CategoryCodeAddressBk27,	--55
			ABAC28, 	--CategoryCodeAddressBk28,	--56
			ABAC29, 	--CategoryCodeAddressBk29,	--57
			ABAC30, 	--CategoryCodeAddressBk30,	--58
			ABGLBA, 	--GlBankAccount,		--59
			ABPTI, 		--TimeScheduledIn,		--60
			ABPDI, 		--DateScheduledIn,		--61
			ABMSGA, 	--ActionMessageControl,		--62
			ABRMK, 		--NameRemark,			--63
			ABTXCT, 	--CertificateTaxExempt,		--64
			ABTX2, 		--TaxId2,			--65
			ABALP1, 	--Kanjialpha,			--66
			ABURCD, 	--UserReservedCode,		--67
			ABURDT, 	--UserReservedDate,		--68
			ABURAT, 	--UserReservedAmount,		--69
			ABURAB, 	--UserReservedNumber,		--70
			ABURRF, 	--UserReservedReference,	--71
			ABUSER, 	--UserId,			--72
			ABPID, 		--ProgramId,			--73
			ABUPMJ, 	--DateUpdated,			--73
			ABJOBN, 	--WorkStationId,		--75
			ABUPMT	 	--TimeLastUpdated		--76 
		)
		VALUES 
		(
			@requisitionNo, 			--1
			CONVERT(varchar, @requisitionNo),	--2
			@blankSpace,				--3
			@description,				--4
			@description,				--5
			@costCenter,				--6
			@blankSpace,				--7
			@blankSpace,				--8
			@blankSpace,				--9
			@blankSpace,				--10
			@searchType,				--11
			@addressType,				--12
			@addressType,				--13
			@addressType,				--14
			@addressType,				--15
			@addressType,				--16
			@addressType,				--17
			@addressType,				--18
			@blankSpace,				--19
			@addressType,				--20
			@blankSpace,				--21
			Projectuser.ConvertToJulian(@commisionDate),	--22
			@requisitionNo,				--23
			@requisitionNo,				--24
			@requisitionNo,				--25
			@requisitionNo,				--26
			@requisitionNo,				--27
			@zeroValue,				--28
			@blankSpace,				--29
			@blankSpace,				--30
			@blankSpace,				--31
			@blankSpace,				--32
			@blankSpace,				--33
			@blankSpace,				--34
			@blankSpace,				--35
			@blankSpace,				--36
			@blankSpace,				--37
			@blankSpace,				--38
			@blankSpace,				--39
			@blankSpace,				--40
			@blankSpace,				--41
			@blankSpace,				--42
			@blankSpace,				--43
			@blankSpace,				--44
			@blankSpace,				--45
			@blankSpace,				--46
			@blankSpace,				--47
			@blankSpace,				--48
			@blankSpace,				--49
			@blankSpace,				--50
			@blankSpace,				--51
			@blankSpace,				--52
			@blankSpace,				--53
			@blankSpace,				--54
			@blankSpace,				--55
			@blankSpace,				--56
			@blankSpace,				--57
			@blankSpace,				--58
			@blankSpace,				--59
			@zeroValue,				--60
			@zeroValue,				--61
			@blankSpace,				--62
			@blankSpace,				--63
			@blankSpace ,				--64
			@blankSpace,				--65
			@blankSpace,				--66
			@blankSpace,				--67
			@zeroValue,				--68
			@zeroValue,				--69
			@zeroValue,				--70
			@blankSpace,				--71
			@userID,				--72
			@requisitionNo,				--73
			Projectuser.ConvertToJulian(getdate()),		--74
			@workStationID,					--75
			CONVERT(NUMERIC, Projectuser.fmtTime(GETDATE()))	--76 
		)

		--Get the number of affected rows
		SELECT @rowsAffected = @@ROWCOUNT

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END
	END 
END 


/*	Debug:

	EXEC Projectuser.Pr_SaveCEADataToOneWorld 3 

PARAMETERS:
	@requisitionID		INT,				-- CEA/MRE Requisition ID
	@commisionDate		DATETIME,			-- Requisition Commissioned date
	@description		VARCHAR(40),		-- Short Description for the requisition
	@projectNo			VARCHAR(12),		-- Cost Center
	@userID				VARCHAR(10),		-- User ID
	@workStationID		VARCHAR(10)			-- Computer Name

*/