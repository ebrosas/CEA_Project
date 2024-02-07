/******************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_Project_CRUD
*	Description: This stored procedure is used to perform CRUD operations in "ContractorRegistry" table
*
*	Date			Author		Revision No.	Comments:
*	02/04/2023		Ervin		1.0				Created
*	
*******************************************************************************************************************************************************************************************************/

CREATE PROCEDURE Projectuser.Pr_Project_CRUD
(	
	@actionType			TINYINT,	--(Notes: 0 = Check records, 1 = Insert, 2 = Update, 3 = Delete)	
	@contractorNo		INT = NULL,
	@registrationDate	DATETIME = NULL,	
	@idNumber			VARCHAR(20) = NULL,
	@idType				TINYINT = NULL,
	@firstName			VARCHAR(30) = NULL,
	@lastName			VARCHAR(30) = NULL,
	@companyName		VARCHAR(50) = NULL,
	@companyID			INT NULL = NULL,
	@companyCRNo		VARCHAR(20) = NULL,
	@purchaseOrderNo	FLOAT = NULL,
	@jobTitle			VARCHAR(10) = NULL,
	@mobileNo			VARCHAR(20) = NULL,
	@visitedCostCenter	VARCHAR(12) = NULL,
	@supervisorEmpNo	INT = NULL,
	@supervisorEmpName	VARCHAR(100) = NULL,
	@purposeOfVisit		VARCHAR(300) = NULL,
	@contractStartDate	DATETIME = NULL,
	@contractEndDate	DATETIME = NULL,
	@bloodGroup			VARCHAR(10) = NULL,
	@remarks			VARCHAR(500) = NULL,
	@userActionDate		DATETIME = NULL,
	@userEmpNo			INT = NULL,
	@userID				VARCHAR(50) = NULL,
	@workDurationHours	INT = NULL,
	@workDurationMins	INT = NULL,
	@companyContactNo	VARCHAR(30) = NULL,
	@registryID			INT OUTPUT	 
)
AS	
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK	INT,
			@CONST_RETURN_ERROR	INT

	--Define variables
	DECLARE @rowsAffected		INT,
			@hasError			BIT,
			@retError			INT,
			@retErrorDesc		VARCHAR(200)

	--Initialize constants
	SELECT	@CONST_RETURN_OK	= 0,
			@CONST_RETURN_ERROR	= -1

	--Initialize variables
	SELECT	@rowsAffected		= 0,
			@hasError			= 0,
			@retError			= @CONST_RETURN_OK,
			@retErrorDesc		= ''

	IF @actionType = 0		--Check existing records
	BEGIN

		IF ISNULL(@contractorNo, 0) = 0
			SET @contractorNo = NULL

		--Check existing records
		SELECT * FROM Projectuser.ContractorRegistry a WITH (NOLOCK)
		WHERE (a.ContractorNo = @contractorNo OR @contractorNo IS NULL)
			AND 
			(
				(a.ContractStartDate = @contractStartDate AND a.ContractStartDate = @contractEndDate AND @contractStartDate IS NOT NULL AND @contractEndDate IS NOT NULL)
				OR (@contractStartDate IS NULL AND @contractEndDate IS NULL)
			)
		ORDER BY a.ContractorNo
    END

	ELSE IF @actionType = 1		--Insert record
	BEGIN

		INSERT INTO Projectuser.ContractorRegistry
		(
			ContractorNo,
			RegistrationDate,
			IDNumber,
			IDType,
			FirstName,
			LastName,
			CompanyName,
			CompanyID,
			CompanyCRNo,
			PurchaseOrderNo,
			JobTitle,
			MobileNo,
			VisitedCostCenter,
			SupervisorEmpNo,
			SupervisorEmpName,
			PurposeOfVisit,
			ContractStartDate,
			ContractEndDate,
			BloodGroup,
			Remarks,
			WorkDurationHours,
			WorkDurationMins,
			CompanyContactNo,
			CreatedDate,
			CreatedByEmpNo,
			CreatedByUser
		)
		VALUES
		(
			@contractorNo,
			@registrationDate,	
			UPPER(RTRIM(@idNumber)),
			@idType,
			UPPER(RTRIM(@firstName)),	--Rev. #1.1
			UPPER(RTRIM(@lastName)),
			@companyName,
			@companyID,
			@companyCRNo,
			@purchaseOrderNo,
			@jobTitle,
			@mobileNo,
			@visitedCostCenter,
			@supervisorEmpNo,
			@supervisorEmpName,
			@purposeOfVisit,
			@contractStartDate,
			@contractEndDate,
			@bloodGroup,
			@remarks,
			@workDurationHours,
			@workDurationMins,
			@companyContactNo,
			@userActionDate,
			@userEmpNo,
			@userID
		)
		
		--Get the new ID
		SET @registryID = @@identity				
					
		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@registryID AS NewIdentityID,
				@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
	END 

	ELSE IF @actionType = 2		--Update existing record
	BEGIN

		UPDATE Projectuser.ContractorRegistry
		SET IDNumber = UPPER(RTRIM(@idNumber)),
			IDType = @idType,
			FirstName = UPPER(RTRIM(@firstName)),	--Rev. #1.1
			LastName = UPPER(RTRIM(@lastName)),
			CompanyName = @companyName,
			CompanyID = @companyID,
			CompanyCRNo = @companyCRNo,
			PurchaseOrderNo = @purchaseOrderNo,
			JobTitle = @jobTitle,
			MobileNo =@mobileNo,
			VisitedCostCenter = @visitedCostCenter,
			SupervisorEmpNo = @supervisorEmpNo,
			SupervisorEmpName = @supervisorEmpName,
			PurposeOfVisit = @purposeOfVisit,
			ContractStartDate = @contractStartDate,
			ContractEndDate = @contractEndDate,
			BloodGroup = @bloodGroup,
			Remarks = @remarks,
			WorkDurationHours = @workDurationHours,
			WorkDurationMins = @workDurationMins,
			CompanyContactNo = @companyContactNo,
			LastUpdatedDate = @userActionDate,
			LastUpdatedByEmpNo = @userEmpNo,
			LastUpdatedByUser = @userID
		WHERE RegistryID = @registryID

		SELECT @rowsAffected = @@rowcount 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
	END 

	ELSE IF @actionType = 3		--Delete record
	BEGIN

		--Check existing records
		DELETE FROM Projectuser.ContractorRegistry 
		WHERE RegistryID = @registryID

		--Get the number of affected records 
		SELECT @rowsAffected = @@rowcount 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
    END		
END  


/*	Debug:
	
	SELECT * FROM Projectuser.ContractorRegistry a

	TRUNCATE TABLE Projectuser.ContractorRegistry

PARAMETERS:
	@actionType			TINYINT,	--(Notes: 0 = Check records, 1 = Insert, 2 = Update, 3 = Delete, 4 = Check for duplicate records)	
	@contractorNo		INT = NULL,
	@registrationDate	DATETIME = NULL,	
	@idNumber			VARCHAR(20) = NULL,
	@idType				TINYINT = NULL,
	@firstName			VARCHAR(30) = NULL,
	@lastName			VARCHAR(30) = NULL,
	@companyName		VARCHAR(50) = NULL,
	@companyID			INT NULL = NULL,
	@companyCRNo		VARCHAR(20) = NULL,
	@purchaseOrderNo	FLOAT = NULL,
	@jobTitle			VARCHAR(50) = NULL,
	@mobileNo			VARCHAR(20) = NULL,
	@visitedCostCenter	VARCHAR(12) = NULL,
	@supervisorEmpNo	INT = NULL,
	@supervisorEmpName	VARCHAR(100) = NULL,
	@purposeOfVisit		VARCHAR(300) = NULL,
	@contractStartDate	DATETIME = NULL,
	@contractEndDate	DATETIME = NULL,
	@bloodGroup			VARCHAR(10) = NULL,
	@remarks			VARCHAR(500) = NULL,
	@userActionDate		DATETIME = NULL,
	@userEmpNo			INT = NULL,
	@userID				VARCHAR(50) = NULL,
	@registryID			INT OUTPUT	 

	EXEC Projectuser.Pr_Project_CRUD 0
	EXEC Projectuser.Pr_Project_CRUD 1, 0, 60001, '09/07/2021', '781202647', 0, 'Ervin', 'Brosas', 'ABS-CBN', 1223, '110234', NULL, 'Software Engineer', '32229611', '7600', 10003512, 'Testing only', '09/01/2021', '09/30/2021', 'Sample data', '09/07/2021', 10003632, 'ervin' 

*/