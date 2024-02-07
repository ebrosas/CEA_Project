/*************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: secuser.CEAWF
*	Description: This table will store the workflow information of the CEA request
*
*	Date			Author		Rev.#		Comments
*	20/08/2023		Ervin		1.0			Created
************************************************************************************************************************************************************************************/

IF OBJECT_ID ('secuser.CEAWF') IS NOT NULL
BEGIN	

	DROP TABLE secuser.CEAWF
END

	CREATE TABLE secuser.CEAWF
	(
		CEARequisitionNo INT NOT NULL,
		CEAProjectNo VARCHAR(12) NOT NULL,
		CEAWFInstanceID VARCHAR(50) NULL,
		CEAReqTypeID INT NOT NULL,
		CEAReqTypeName VARCHAR(50) NULL,
		CEAReqTypeCode VARCHAR(10) NOT NULL,		
		CEAEmpNo INT NOT NULL,
		CEAEmpName VARCHAR(50) NULL,
		CEAEmpEmail VARCHAR(50) NULL,
		CEACostCenter VARCHAR(12) NOT NULL,
		CEADescription VARCHAR(40) NULL,
		CEAOriginatorNo INT NOT NULL,
		CEAOriginatorName VARCHAR(50) NULL,
		CEATotalAmount DECIMAL(18,3) NOT NULL, 
		CEAIsBudgeted BIT NOT NULL,		
		CEARequireItemApp BIT NULL,
		CEAItemCatCode VARCHAR(10) NULL,
		CEAIsUnderGMO BIT NULL,
		CEARejectEmailGroup VARCHAR(300) NULL,
		CEAIsDraft BIT NULL,
		CEAStatusID INT NULL,
		CEAStatusCode VARCHAR(10) NULL,
		CEAStatusHandlingCode VARCHAR(50) NULL,
		CEARetError INT NULL,
		CEACreatedDate DATETIME DEFAULT GETDATE(),		
		CEACreatedBy INT NOT NULL,
		CEACreatedName VARCHAR(50) NULL,
		CEACreatedUserID VARCHAR(50) NULL,
		CEACreatedEmail VARCHAR(50) NULL,
		CEAModifiedDate DATETIME NULL,
		CEAModifiedBy INT NULL,
		CEAModifiedName VARCHAR(50) NULL,
		CEAModifiedID VARCHAR(50) NULL,
		CEAModifiedEmail VARCHAR(50) NULL,
		CEARejectionRemarks VARCHAR(300) NULL,	
		CEARequireCEOApv BIT NULL, 	
		CEARequireChairmanApv BIT NULL,
		 
		CONSTRAINT [PK_CEAWF] PRIMARY KEY CLUSTERED 
		(
			CEARequisitionNo,			
			CEAReqTypeID,
			CEAEmpNo,
			CEACostCenter			
		)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]


GO
