/***************************************************************************************************************************************************************
*	Revision History
*	Name: dbo.RequisitionStatusDetail
*	Description: Modified the schema of "dbo.RequisitionStatusDetail" table
*
*	Date:	  		Author:		Rev.#		Comments:
*	09/10/2023		Ervin		1.0			Added new field called "DistGroupCode"
**********************************************************************************************************************************************************/

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'RequisitionStatusDetail' AND COLUMN_NAME = 'AssignedEmpNo')
	BEGIN

		ALTER TABLE dbo.RequisitionStatusDetail 
		ADD AssignedEmpNo INT NULL 
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'RequisitionStatusDetail' AND COLUMN_NAME = 'AssignedEmpName')
	BEGIN

		ALTER TABLE dbo.RequisitionStatusDetail 
		ADD AssignedEmpName VARCHAR(100) NULL 
	END

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'RequisitionStatusDetail' AND COLUMN_NAME = 'AssignedEmpEmail')
	BEGIN

		ALTER TABLE dbo.RequisitionStatusDetail 
		ADD AssignedEmpEmail VARCHAR(50) NULL 
	END

	--(Notes: This field serves as a flag that determines whether the employee is registered as an application user. Values are: 0 = Registered User; 1 = Non-Registered User)
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'RequisitionStatusDetail' AND COLUMN_NAME = 'IsAnonymousUser')
	BEGIN

		ALTER TABLE dbo.RequisitionStatusDetail 
		ADD IsAnonymousUser BIT NULL 
	END

	
	

	
	
	

