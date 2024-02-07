/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.Requisition
*	Description: Modified the schema of "dbo.Requisition" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	05/09/2023		Ervin		1.0			Added new field called "UseNewWF"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'Requisition' AND COLUMN_NAME = 'UseNewWF')
	BEGIN

		ALTER TABLE dbo.Requisition 
		ADD UseNewWF BIT NULL 
	END

	

	

	
	
	

