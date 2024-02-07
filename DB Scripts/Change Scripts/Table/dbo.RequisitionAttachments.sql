/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.RequisitionAttachments
*	Description: Modified the schema of "dbo.RequisitionAttachments" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	22/06/2023		Ervin		1.0			Added new field called "CreatedByEmpNo"
*	20/07/2023		Ervin		1.1			Added the following fields: Base64File, Base64FileExt
*
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'dbo.RequisitionAttachments' AND COLUMN_NAME = 'CreatedByEmpNo')
	BEGIN

		ALTER TABLE dbo.RequisitionAttachments
		ADD CreatedByEmpNo INT NULL
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'dbo.RequisitionAttachments' AND COLUMN_NAME = 'Base64File')
	BEGIN

		ALTER TABLE dbo.RequisitionAttachments
		ADD Base64File VARCHAR(MAX) NULL
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'dbo.RequisitionAttachments' AND COLUMN_NAME = 'Base64FileExt')
	BEGIN

		ALTER TABLE dbo.RequisitionAttachments
		ADD Base64FileExt VARCHAR(5) NULL
	END

	

	
	
	

