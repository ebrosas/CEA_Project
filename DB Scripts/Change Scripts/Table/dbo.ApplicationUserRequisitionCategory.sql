/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.ApplicationUserRequisitionCategory
*	Description: Modified the schema of "dbo.ApplicationUserRequisitionCategory" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	14/10/2023		Ervin		1.0			Added new field called "DistGroupCode"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'ApplicationUserRequisitionCategory' AND COLUMN_NAME = 'DistGroupCode')
	BEGIN

		ALTER TABLE dbo.ApplicationUserRequisitionCategory 
		ADD DistGroupCode VARCHAR(10) NULL 
	END

	
	

	
	
	

