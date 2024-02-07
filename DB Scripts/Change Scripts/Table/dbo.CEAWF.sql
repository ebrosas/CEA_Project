/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.CEAWF
*	Description: Modified the schema of "secuser.CEAWF" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	24/10/2023		Ervin		1.0			Added new field called "CEARejectionRemarks"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'CEAWF' AND COLUMN_NAME = 'CEARejectionRemarks')
	BEGIN

		ALTER TABLE secuser.CEAWF 
		ADD CEARejectionRemarks VARCHAR(300) NULL 
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'CEAWF' AND COLUMN_NAME = 'CEARequireCEOApv')
	BEGIN

		ALTER TABLE secuser.CEAWF 
		ADD CEARequireCEOApv BIT NULL 
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'CEAWF' AND COLUMN_NAME = 'CEARequireChairmanApv')
	BEGIN

		ALTER TABLE secuser.CEAWF 
		ADD CEARequireChairmanApv BIT NULL 
	END

	
	
	

	
	
	

