DECLARE	@actionType		TINYINT = 0,		--(Notes: 0 = Check records, 1 = Insert new record)
		@isCommitTrans	BIT = 0

	IF @actionType = 0
	BEGIN

		--Get all records
		SELECT * FROM secuser.RequestType a WITH (NOLOCK)
		ORDER BY a.ReqTypeID
    END

	ELSE IF @actionType = 1
	BEGIN

		BEGIN TRAN T1

		INSERT INTO secuser.RequestType
		(
			[ReqTypeParentID]
			,[ReqTypeCode]
			,[ReqTypeName]
			,[ReqTypeRemarks]
			,[ReqTypeProcessID]
			,[ReqTypeKeyTableName]
			,[ReqTypePublic]
			,[ReqTypeCat01]
			,[ReqTypeCat02]
			,[ReqTypeCat03]
			,[ReqTypeCat04]
			,[ReqTypeCat05]
			,[ReqTypeCat06]
			,[ReqTypeCat07]
			,[ReqTypeCat08]
			,[ReqTypeCat09]
			,[ReqTypeCat10]
			,[ReqTypeCreatedBy]
			,[ReqTypeCreatedName]
			,[ReqTypeCreatedDate]
			,ReqTypeModifiedBy
			,ReqTypeModifiedName,
			ReqTypeModifiedDate
		)
		SELECT	0 AS ReqTypeParentID, 
				'CEAREQ' AS ReqTypeCode,
				'CEA/MRE Requisition' AS ReqTypeName, 
				'CEA Workflow' AS ReqTypeRemarks, 
			
				--354 AS ReqTypeProcessID,
				(SELECT a.ProcessID FROM SecUser.GenPurposeProcessWF a WITH (NOLOCK) WHERE RTRIM(a.ProcessCode) = 'CEAWF') AS ReqTypeProcessID,

				'' AS ReqTypeKeyTableName, 
				1 AS ReqTypePublic, 
				0 AS ReqTypeCat01, 
				0 AS ReqTypeCat02,
				0 AS ReqTypeCat03,
				0 AS ReqTypeCat04,
				0 AS ReqTypeCat05,
				0 AS ReqTypeCat06,
				0 AS ReqTypeCat07,
				0 AS ReqTypeCat08,
				0 AS ReqTypeCat09,
				0 AS ReqTypeCat10,
				10003632 AS ReqTypeCreatedBy, 
				'ervin' AS ReqTypeCreatedName, 
				GETDATE() AS ReqTypeCreatedDate,
				10003632 AS ReqTypeModifiedBy, 
				'ervin' AS ReqTypeModifiedName, 
				GETDATE() AS ReqTypeModifiedDate

		--Get all records
		SELECT * FROM secuser.RequestType a WITH (NOLOCK)
		ORDER BY a.ReqTypeID

		IF @isCommitTrans = 1
			COMMIT TRAN T1
		ELSE
			ROLLBACK TRAN T1
	END 




