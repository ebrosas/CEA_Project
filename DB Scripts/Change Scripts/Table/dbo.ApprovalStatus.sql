/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.ApprovalStatus
*	Description: Modified the schema of "dbo.ApprovalStatus" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	09/04/2023		Ervin		1.0			Added new field called "StatusHandlingCode"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'ApprovalStatus' AND COLUMN_NAME = 'StatusHandlingCode')
	BEGIN

		ALTER TABLE dbo.ApprovalStatus 
		ADD StatusHandlingCode VARCHAR(10) NULL 
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'ApprovalStatus' AND COLUMN_NAME = 'WFStatusCode')
	BEGIN

		ALTER TABLE dbo.ApprovalStatus 
		ADD WFStatusCode VARCHAR(50) NULL 
	END

	

	

	
	
	

