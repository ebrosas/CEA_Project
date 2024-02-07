/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_Requisition_CUD
*	Description: This stored procedure performs create, update, and delete operations against "Requisition" table
*
*	Date			Author		Rev. #		Comments:
*	13/07/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_Requisition_CUD 
(
	@actionType						TINYINT = 1,			--(Notes: 0 = Check record, 1 = Insert, 2 = Update, 3 = Delete)
	@requisitionID					NUMERIC = 0,
    @projectNo						VARCHAR(12) = '',
    @requisitionDate				DATETIME = NULL,
    @originatorEmpNo				INT = 0,
    @plantLocation					VARCHAR(12) = '',
    @categoryCode					VARCHAR(10) = '',
    @lifeSpan						SMALLINT = 0,
    @itemRequired					VARCHAR(1000) = '',
    @reason							VARCHAR(1000) = '',
    @commissionDate					DATETIME = NULL,
    @estimatedCost					NUMERIC(18,3) = 0,
    @additionalAmt					NUMERIC(18,3) = 0,    
    @requisitionDesc				VARCHAR(40) = '',
    @reasonAdditionalAmt			VARCHAR(100) = '',
    @equipmentChildNo				VARCHAR(12) = '',
    @equipmentParentNo				VARCHAR(12) = '',
    @preparedBy						VARCHAR(50) = '',
    @preparedByEmpNo				INT = 0,
    @multipleItems					BIT = 0,
    @newRequisitionID				INT OUTPUT,
	@requisitionNo					VARCHAR(50) OUTPUT
)
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK	INT = 0,
			@CONST_RETURN_ERROR	INT = -1

    DECLARE @expenditureType		VARCHAR(50) = '',
            @projectType			VARCHAR(20) = '',
			@costCenter				VARCHAR(12) = '',
            @INCMaxValue			NUMERIC(18,3) = 0,
			@projectAmt				NUMERIC(18,3) = 0,
            @additionalBudgetAmt	NUMERIC(18,3) = 0,
            @requestedAmt			NUMERIC(18,3) = 0,
			@projectBalanceAmt		NUMERIC(18,3) = 0,
			@requisitionNoTmp		INT = 0,
            @fiscalYear				SMALLINT = 0,
			@rowsAffected			INT = 0

    SELECT	@expenditureType = RTRIM(a.ExpenditureType),
            @projectType = RTRIM(a.ProjectType),
			@costCenter = RTRIM(a.CostCenter),
			@projectAmt = a.ProjectAmount,
			@fiscalYear = a.FiscalYear
	FROM dbo.Project a WITH (NOLOCK)
    WHERE RTRIM(a.ProjectNo) = @projectNo

    SELECT @INCMaxValue = ISNULL(a.INCMaxValue, 0) FROM dbo.AppConfiguration a WITH (NOLOCK)

	--Perform data validation
    IF @projectType = 'NonBudgeted'
    BEGIN

        IF @expenditureType = 'CEA' AND @estimatedCost < @INCMaxValue
        BEGIN
            
			SELECT @newRequisitionID = -2
            RETURN 0
        END

        ELSE IF @expenditureType = 'INC' AND @multipleItems = 0 AND @estimatedCost > @INCMaxValue
        BEGIN

            SELECT @newRequisitionID = -4
            RETURN 0
        END
    END
	
    IF NOT EXISTS (SELECT ApprovalGroupID FROM dbo.ApprovalGroup a WITH (NOLOCK) WHERE RTRIM(a.CostCenter) = @costCenter)
    BEGIN

        SET @newRequisitionID = -1
        RETURN 0
    END
    
    SELECT	@additionalBudgetAmt = SUM(ISNULL(a.AdditionalBudgetAmt, 0)),
            @requestedAmt = SUM(ISNULL(a.RequestedAmt, 0))
	FROM dbo.Requisition a WITH (NOLOCK)
		CROSS APPLY
        (
			SELECT  DISTINCT TOP 1 RTRIM(y.ApprovalStatus) AS RequisitionStatus, y.StatusHandlingCode 
			FROM dbo.RequisitionStatus x WITH (NOLOCK)
				INNER JOIN dbo.ApprovalStatus y WITH (NOLOCK) ON x.ApprovalStatusID = y.ApprovalStatusID
			WHERE x.RequisitionID = a.RequisitionID
		) b
    WHERE RTRIM(a.ProjectNo) = @projectNo
		AND RTRIM(b.StatusHandlingCode) NOT IN ('Cancelled', 'Rejected')

    IF @actionType = 1
    BEGIN
                
		--Calculate the balance amount
		SET @projectBalanceAmt = ISNULL(@projectAmt, 0) + ISNULL(@additionalBudgetAmt, 0) + ISNULL(@additionalAmt, 0) - (ISNULL(@requestedAmt, 0) + ISNULL(@estimatedCost, 0))

        --Generate new requisition no.
		EXEC Projectuser.Pr_SetupNewRequisitionNo @requisitionNoTmp OUTPUT

        SET @requisitionNo = CONVERT(VARCHAR, @requisitionNoTmp)

		--Insert record to CEA requisition table
        INSERT INTO dbo.Requisition 
		(
			ProjectNo,
			RequisitionNo,
			RequestDate,
			[Description],
			DateofComission,
			PlantLocationID,
			EstimatedLifeSpan,
			ProjectBalanceAmt,
			RequestedAmt,
			CreateBy,
			CreateDate,
			LastUpdateBy, 
			LastUpdateDate, 
			CategoryCode1,
			AdditionalBudgetAmt,
			Reason,
			RequisitionDescription,
			ReasonForAdditionalAmt,
			FiscalYear,
			OneWorldABNo,
			EquipmentNo,
			EquipmentParentNo,
			OriginatorEmpNo,
			CreatedByEmpNo,
			CategoryCode2
        )
        VALUES 
		(
            @projectNo,
            @requisitionNo,
            @requisitionDate,
            @itemRequired, 
            @commissionDate,
            @plantLocation, 
            @lifeSpan,
            @projectBalanceAmt,
            @estimatedCost, 
            @preparedBy,
            GETDATE(),
            @preparedBy,
            GETDATE(),
            @categoryCode, 
            @additionalAmt,
            @reason,
            @requisitionDesc,
            @reasonAdditionalAmt, 
            @fiscalYear,
            @requisitionNo,
            @equipmentChildNo,
            @equipmentParentNo,
            @originatorEmpNo, 
            @preparedByEmpNo,
            @multipleItems
        )

		--Get the new identity seed value
        SELECT @newRequisitionID = @@IDENTITY

        DECLARE @draftID INT
        SELECT @draftID = a.ApprovalStatusID
        FROM dbo.ApprovalStatus a WITH (NOLOCK)
        WHERE RTRIM(a.StatusCode) = 'Draft'

		IF @newRequisitionID > 0
		BEGIN
        
			--Insert routine history record
			INSERT INTO dbo.RequisitionStatus 
			(
				RequisitionID,
				ApprovalStatusID,
				[Description],
				CreatedBy,
				LastUpdatedBy,
				CurrentApprovalGroupID
			)
			VALUES
			(
				@newRequisitionID,
				@draftID,
				'Created',
				@preparedBy,
				@preparedBy,
				-1
			)
		END 
    END

    ELSE IF @actionType = 2
    BEGIN

		--Get the requested amount
        SELECT @RequestedAmt = RequestedAmt
        FROM dbo.Requisition a WITH (NOLOCK)
        WHERE RequisitionID = @requisitionID

        SET @projectBalanceAmt = ISNULL(@projectAmt, 0) + ISNULL(@additionalBudgetAmt, 0) + ISNULL(@additionalAmt, 0) + @estimatedCost - ((ISNULL(@requestedAmt, 0) + @RequestedAmt) )

		--Update CEA requisition detail
        UPDATE dbo.Requisition
        SET RequestDate				= @requisitionDate,
            [Description]			= @itemRequired,
            DateofComission        = @commissionDate,
            PlantLocationID        = @plantLocation,
            EstimatedLifeSpan      = @lifeSpan,
            ProjectBalanceAmt      = @projectBalanceAmt,
            RequestedAmt           = @estimatedCost,
            LastUpdateBy           = @preparedBy,
            AdditionalBudgetAmt    = @additionalAmt,
            Reason                 = @reason,
            RequisitionDescription = @requisitionDesc,
            ReasonForAdditionalAmt = @reasonAdditionalAmt,
            EquipmentNo            = @equipmentChildNo, 
            EquipmentParentNo      = @equipmentParentNo,
            OriginatorEmpNo        = @originatorEmpNo,
            LastUpdateDate         = GETDATE(),
            CreatedByEmpNo         = @preparedByEmpNo,
            CategoryCode1          = @categoryCode,
            CategoryCode2          = @multipleItems
        WHERE RequisitionID = @requisitionID

        DECLARE @requisitonStatusID NUMERIC

        SELECT @requisitonStatusID = a.RequisitionStatusID
        FROM dbo.RequisitionStatus a WITH (NOLOCK)
        WHERE a.RequisitionID = @requisitionID

        SELECT @newRequisitionID = @requisitionID
    END

	ELSE IF @actionType = 3
	BEGIN

		DECLARE @ceaNo VARCHAR(50) = ''

		SELECT @ceaNo = RTRIM(a.RequisitionNo) 
		FROM dbo.Requisition a WITH (NOLOCK)
		WHERE a.RequisitionID = @requisitionID

		--Delete requisition details
		DELETE FROM	dbo.Requisition
		WHERE RequisitionID = @requisitionID

		SELECT @rowsAffected = @@ROWCOUNT

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN						

			--Delete Schedule of Expenses
			--DELETE FROM dbo.Expense
			--WHERE RTRIM(CAST(RequisitionID AS VARCHAR(50))) = @ceaNo 

			--Delete attachments
			DELETE FROM dbo.RequisitionAttachments 
			WHERE RequisitionID = @requisitionID

			--Delete request status
			DELETE FROM dbo.RequisitionStatus 
			WHERE RequisitionID = @requisitionID
		END
    END 
END 

/*	Debug:

	EXEC Projectuser.Pr_Requisition_CUD 3 

*/