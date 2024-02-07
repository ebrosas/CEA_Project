/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.ApprovalGroupType
*	Description: Modified the schema of "dbo.ApprovalGroupType" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	09/10/2023		Ervin		1.0			Added new field called "DistGroupCode"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'ApprovalGroupType' AND COLUMN_NAME = 'DistGroupCode')
	BEGIN

		ALTER TABLE dbo.ApprovalGroupType 
		ADD DistGroupCode VARCHAR(10) NULL 
	END

	
	

	
	
	

