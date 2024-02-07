/*******************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetWFActionMember
*	Description: Retrieves the workflow action member 
*
*	Date:			Author:		Rev. #:		Comments:
*	10/09/2023		Ervin		1.0			Created
*******************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetWFActionMember
(
	@distListCode	VARCHAR(10),
	@costCenter		VARCHAR(12),
	@empNo			INT 
)
RETURNS @rtnTable 
TABLE 
(
	EmpNo			INT,
	EmpName			VARCHAR(50),
	EmpEmail		VARCHAR(50)
)
AS
BEGIN

	DECLARE @myTable TABLE 
	(
		EmpNo int,
		EmpName varchar(50),
		EmpEmail varchar(50)
	)

	--Declare field variables
	DECLARE	@empName varchar(50),
			@empEmail varchar(50)

	--Initialize field variables
	SELECT	@empName	= '',
			@empEmail	= ''

	DECLARE	@actionMemberEmpNo		int,
			@DistListID				int,
			@serviceProviderEmpNo	int,
			@SubstituteEmpNo		int,
			@DistMemID				int,			
			@WFSubstituteEmpNo		int,
			@WFSubstituteEmpName	varchar(50),
			@WFSubstituteEmpEmail	varchar(50), 
			@CONST_WFCEA			varchar(10),
			@recordCount			INT 
		
	SELECT	@actionMemberEmpNo		= 0, 
			@DistListID				= 0,
			@serviceProviderEmpNo	= 0,
			@SubstituteEmpNo		= 0,
			@DistMemID				= 0,
			@WFSubstituteEmpNo		= 0,
			@WFSubstituteEmpName	= '',
			@WFSubstituteEmpEmail	= '',
			@CONST_WFCEA			= 'WFCEA',
			@recordCount			= 0
	
	IF RTRIM(@distListCode) = 'CCSUPERDNT'		--Superintendent
	BEGIN

		IF ISNULL(@costCenter, '') = '' AND @empNo > 0
		BEGIN

			SELECT @costCenter = RTRIM(b.BusinessUnit)
			FROM Projectuser.sy_F060116 a WITH (NOLOCK)
				INNER JOIN Projectuser.Vw_MasterEmployeeJDE b ON a.YAAN8 = b.EmpNo 
			WHERE a.YAAN8 = @empNo	
		END

		IF ISNULL(@costCenter, '') <> ''
		BEGIN

			--Get the Superintendent
			SELECT @serviceProviderEmpNo = a.Superintendent 
			FROM Projectuser.Vw_MasterCostCenter a 
			WHERE a.CostCenter = @costCenter

			IF @serviceProviderEmpNo > 0
			BEGIN

				--Search for active substitute defined in the "Workflow Substitute Settings" form in ISMS
				IF EXISTS 
				(
					SELECT SubstituteSettingID FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
				)
				BEGIN

					SELECT	@WFSubstituteEmpNo = SubstituteEmpNo, 
							@WFSubstituteEmpName = SubstituteEmpName,
							@WFSubstituteEmpEmail = SubstituteEmpEmail
					FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
				END

				IF @WFSubstituteEmpNo > 0		
					SET @actionMemberEmpNo = @WFSubstituteEmpNo

				ELSE
				BEGIN

					--Check if Superintendent is on-leave
					IF EXISTS 
					(
						SELECT a.MasterLeaveID 
						FROM Projectuser.sy_Master_CurrentLeaves a WITH (NOLOCK)
						WHERE a.EmpNo = @serviceProviderEmpNo
							AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN a.FromDate AND a.ToDate
					)
					BEGIN

						--The Superintendent is on-leave, so get the substitute from the Leave Requisition	System (Rev. #1.2)
						SELECT @SubstituteEmpNo = a.SubEmpNo
						FROM Projectuser.sy_LeaveRequisition a WITH (NOLOCK) 
						WHERE RTRIM(RequestStatusSpecialHandlingCode) = 'Closed' 
							AND EmpNo = @serviceProviderEmpNo
							AND RTRIM(LeaveType) = 'AL' 
							AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN LeaveStartDate and LeaveEndDate

						IF (@SubstituteEmpNo > 0)	
						BEGIN
									
							SELECT @actionMemberEmpNo = @SubstituteEmpNo
							FROM Projectuser.Vw_MasterEmployeeJDE a
								INNER JOIN Projectuser.Vw_MasterCostCenter b ON RTRIM(a.BusinessUnit) = RTRIM(b.CostCenter)
							WHERE EmpNo = @SubstituteEmpNo
						END
						ELSE 
						BEGIN

							--Get the Superintendent
							SELECT @actionMemberEmpNo = @serviceProviderEmpNo
						END
					END

					ELSE 
					BEGIN
				
						--Get the Superintendent
						SELECT @actionMemberEmpNo = @serviceProviderEmpNo
					END
				END
			END						
		END
	END

	ELSE IF RTRIM(@distListCode) = 'CCMANAGER'	--Cost Center Manager
	BEGIN

		IF ISNULL(@costCenter, '') = '' AND @empNo > 0
		BEGIN

			SELECT @costCenter = RTRIM(b.BusinessUnit)
			FROM Projectuser.sy_F060116 a WITH (NOLOCK)
				INNER JOIN Projectuser.Vw_MasterEmployeeJDE b ON a.YAAN8 = b.EmpNo 
			WHERE YAAN8 = @empNo	
		END

		IF ISNULL(@costCenter, '') <> '' 
		BEGIN

			--Get the Cost Center Manager			
			SELECT @serviceProviderEmpNo = a.CostCenterManager 
			FROM Projectuser.Vw_MasterCostCenter a 
			WHERE a.CostCenter = @costCenter

			IF @serviceProviderEmpNo > 0
			BEGIN

				--Search for active substitute defined in the "Workflow Substitute Settings" form in ISMS
				IF EXISTS (SELECT SubstituteSettingID FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter))
				BEGIN

					SELECT	@WFSubstituteEmpNo = SubstituteEmpNo, 
							@WFSubstituteEmpName = SubstituteEmpName,
							@WFSubstituteEmpEmail = SubstituteEmpEmail
					FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
				END
			END

			IF @WFSubstituteEmpNo > 0		
				SET @actionMemberEmpNo = @WFSubstituteEmpNo

			ELSE
			BEGIN

				--Check if Cost Center Manager is on-leave
				IF EXISTS 
				(	
					SELECT a.MasterLeaveID 
					FROM Projectuser.sy_Master_CurrentLeaves a
					WHERE a.EmpNo = @serviceProviderEmpNo
						AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN a.FromDate AND a.ToDate
				)
				BEGIN

					--The Cost Center Manager is on-leave, so get the substitute from the Leave Requisition	System (Rev. #1.2)
					SELECT @SubstituteEmpNo = SubEmpNo
					FROM Projectuser.sy_LeaveRequisition a WITH (NOLOCK) 
					WHERE RTRIM(RequestStatusSpecialHandlingCode) = 'Closed' 
						AND EmpNo = @serviceProviderEmpNo
						AND RTRIM(LeaveType) = 'AL' 
						AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN LeaveStartDate and LeaveEndDate

					IF (@SubstituteEmpNo > 0)	
					BEGIN
									
						SELECT @actionMemberEmpNo = a.EmpNo
						FROM Projectuser.Vw_MasterEmployeeJDE a
							INNER JOIN Projectuser.Vw_MasterCostCenter b ON rtrim(a.BusinessUnit) = RTRIM(b.CostCenter)
						WHERE EmpNo = @SubstituteEmpNo
					END

					ELSE 
					BEGIN

						--Get the Cost Center Manager
						SELECT @actionMemberEmpNo = @serviceProviderEmpNo
					END
				END

				ELSE 
				BEGIN
				
					--Get the Cost Center Manager
					SELECT @actionMemberEmpNo = @serviceProviderEmpNo
				END
			END
		END
	END

	ELSE IF RTRIM(@distListCode) = 'SUPERVISOR'		--Direct Supervisor
	BEGIN

		IF @empNo > 0
		BEGIN

			--Get the employee's Direct Supervisor 
			SELECT @serviceProviderEmpNo = a.SupervisorNo 
			FROM Projectuser.Vw_MasterEmployeeJDE a 
			WHERE a.EmpNo = @empNo

			IF @serviceProviderEmpNo > 0
			BEGIN

				--Search for active substitute defined in the "Workflow Substitute Settings" form in ISMS
				IF EXISTS (SELECT SubstituteSettingID FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter))
				BEGIN

					SELECT	@WFSubstituteEmpNo = SubstituteEmpNo, 
							@WFSubstituteEmpName = SubstituteEmpName,
							@WFSubstituteEmpEmail = SubstituteEmpEmail
					FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
				END
			END

			IF @WFSubstituteEmpNo > 0		
				SET @actionMemberEmpNo = @WFSubstituteEmpNo

			ELSE
			BEGIN

				--Check if Supervisor is on-leave
				IF EXISTS 
				(	
					SELECT a.MasterLeaveID 
					FROM Projectuser.sy_Master_CurrentLeaves a
					WHERE a.EmpNo = @serviceProviderEmpNo
						AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN a.FromDate AND a.ToDate
				)
				BEGIN

					--The Supervisor is on-leave, so get the substitute from the Leave Requisition	System 
					SELECT @SubstituteEmpNo = SubEmpNo
					FROM Projectuser.sy_LeaveRequisition a WITH (NOLOCK) 
					WHERE RTRIM(RequestStatusSpecialHandlingCode) = 'Closed' 
						AND EmpNo = @serviceProviderEmpNo
						AND RTRIM(LeaveType) = 'AL' 
						AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN LeaveStartDate and LeaveEndDate

					IF (@SubstituteEmpNo > 0)	
					BEGIN
									
						SELECT @actionMemberEmpNo = a.EmpNo
						FROM Projectuser.Vw_MasterEmployeeJDE a
							INNER JOIN Projectuser.Vw_MasterCostCenter b ON rtrim(a.BusinessUnit) = rtrim(b.CostCenter)
						WHERE EmpNo = @SubstituteEmpNo
					END

					ELSE 
					BEGIN

						--Get the Cost Center Manager
						SELECT @actionMemberEmpNo = @serviceProviderEmpNo
					END
				END

				ELSE 
				BEGIN
				
					--Get the Cost Center Manager
					SELECT @actionMemberEmpNo = @serviceProviderEmpNo
				END
			END
		END
	END

	ELSE 
	BEGIN

		SELECT TOP 1 @DistListID = DistListID 
		FROM Projectuser.sy_DistributionList a WITH (NOLOCK)
		WHERE UPPER(RTRIM(DistListCode)) = UPPER(RTRIM(@distListCode))

		IF @DistListID > 0 
		BEGIN

			IF UPPER(RTRIM(@costCenter)) <> 'ALL'
			BEGIN
            
				--Get the Service Provider employee info
				SELECT TOP 1 @serviceProviderEmpNo = ISNULL(DistMemEmpNo,0), 
							@DistMemID = DistMemID
				FROM Projectuser.sy_DistributionMember a WITH (NOLOCK)
				WHERE DistMemDistListID = @DistListID

				IF @serviceProviderEmpNo > 0
				BEGIN

					--Search for active substitute defined through the "Workflow Substitute Settings" form in ISMS
					IF EXISTS (SELECT SubstituteSettingID FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter))
					BEGIN

						SELECT	@WFSubstituteEmpNo = SubstituteEmpNo, 
								@WFSubstituteEmpName = SubstituteEmpName,
								@WFSubstituteEmpEmail = SubstituteEmpEmail
						FROM Projectuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
					END
				END

				IF @WFSubstituteEmpNo > 0		
					SET @actionMemberEmpNo = @WFSubstituteEmpNo

				ELSE
				BEGIN

					--Check if the Service Provider is on-leave
					IF EXISTS 
					(
						SELECT a.MasterLeaveID 
						FROM Projectuser.sy_Master_CurrentLeaves a
						WHERE a.EmpNo = @serviceProviderEmpNo
							AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN a.FromDate AND a.ToDate
					)
					BEGIN

						--The Cost Center Manager is on-leave, so get the substitute from the Leave Requisition	System (Rev. #1.2)
						SELECT @SubstituteEmpNo = SubEmpNo
						FROM Projectuser.sy_LeaveRequisition a WITH (NOLOCK) 
						WHERE RTRIM(RequestStatusSpecialHandlingCode) = 'Closed' 
							AND EmpNo = @serviceProviderEmpNo
							AND RTRIM(LeaveType) = 'AL' 
							AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN LeaveStartDate and LeaveEndDate

						IF (@SubstituteEmpNo > 0)
							SET @actionMemberEmpNo = @SubstituteEmpNo
						ELSE
							SET @actionMemberEmpNo = @serviceProviderEmpNo
					END
					ELSE 
						SET @actionMemberEmpNo = @serviceProviderEmpNo
				END
			END 

			ELSE
            BEGIN

				SELECT @recordCount = COUNT(a.DistMemEmpNo)
				FROM Projectuser.sy_DistributionMember a WITH (NOLOCK)
					INNER JOIN Projectuser.Vw_MasterEmployeeJDE b ON a.DistMemEmpNo = b.EmpNo 					
				WHERE a.DistMemDistListID = @DistListID 

				IF @recordCount = 1
				BEGIN
					
					--Get the Service Provider Emp. No.
					SELECT TOP 1 
						@serviceProviderEmpNo = DistMemEmpNo, 
						@DistMemID = DistMemID
					FROM Projectuser.sy_DistributionMember a WITH (NOLOCK)
						INNER JOIN Projectuser.Vw_MasterEmployeeJDE b WITH (NOLOCK) ON a.DistMemEmpNo = b.EmpNo 						
					WHERE a.DistMemDistListID = @DistListID 

					--Check if there is active substitute defined in the "genuser.WFSubstituteSetting" table 
					IF @serviceProviderEmpNo > 0
					BEGIN

						--Search for active substitute defined through the "Workflow Substitute Settings" form in ISMS
						IF EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter))
						BEGIN
							SELECT	@WFSubstituteEmpNo = SubstituteEmpNo, 
									@WFSubstituteEmpName = SubstituteEmpName,
									@WFSubstituteEmpEmail = SubstituteEmpEmail
							FROM Gen_Purpose.genuser.fnGetActiveSubstitute(@serviceProviderEmpNo, @CONST_WFCEA, @costCenter)
						END												
					END
			
					IF @WFSubstituteEmpNo > 0
					BEGIN
                    
						SET @actionMemberEmpNo = @WFSubstituteEmpNo
					END
                    
					ELSE
					BEGIN
						--Check if the Service Provider is on-leave
						IF EXISTS 
						(
							SELECT a.MasterLeaveID 
							FROM Projectuser.sy_Master_CurrentLeaves a WITH (NOLOCK)
							WHERE a.EmpNo = @serviceProviderEmpNo
								AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN a.FromDate AND a.ToDate
						)
						BEGIN

							--The Service Provider is on-leave, so get the substitute from the Leave Requisition System (Rev. #1.2)
							SELECT @SubstituteEmpNo = SubEmpNo
							FROM Projectuser.sy_LeaveRequisition a WITH (NOLOCK) 
							WHERE RTRIM(RequestStatusSpecialHandlingCode) = 'Closed' 
								AND EmpNo = @serviceProviderEmpNo
								AND RTRIM(LeaveType) = 'AL' 
								AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 12)) BETWEEN LeaveStartDate and LeaveEndDate

							IF (@SubstituteEmpNo > 0)
								SET @actionMemberEmpNo = @SubstituteEmpNo
							ELSE
								SET @actionMemberEmpNo = @serviceProviderEmpNo
						END
						ELSE 
							SET @actionMemberEmpNo = @serviceProviderEmpNo
					END
                END 

				ELSE
                BEGIN

					--Populate data to the table
					INSERT INTO @myTable  
					SELECT DISTINCT
						CASE WHEN EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							THEN (SELECT SubstituteEmpNo FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							ELSE isnull(DistMemEmpNo, 0)
							END AS EmpNo, 

						CASE WHEN EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							THEN (SELECT RTRIM(SubstituteEmpName) FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							ELSE ISNULL(b.EmpName, '')
							END AS EmpName, 

						CASE WHEN EXISTS (SELECT SubstituteSettingID FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							THEN (SELECT RTRIM(SubstituteEmpEmail) FROM Gen_Purpose.genuser.fnGetActiveSubstitute(a.DistMemEmpNo, @CONST_WFCEA, RTRIM(b.BusinessUnit)))
							ELSE ISNULL(a.DistMemEmpEmail, '')
							END AS EmpEmail
					FROM Projectuser.sy_DistributionMember a WITH (NOLOCK)
						INNER JOIN Projectuser.Vw_MasterEmployeeJDE b ON a.DistMemEmpNo = b.EmpNo 
						LEFT JOIN Projectuser.Vw_MasterCostCenter c ON rtrim(ltrim(b.BusinessUnit)) = rtrim(ltrim(c.CostCenter))
					WHERE DistMemDistListID = @DistListID 

					GOTO SKIP_HERE_MULTIPLE_ASSIGNEE
                END 
            END 
		END
	END
			
	IF @actionMemberEmpNo > 0
	BEGIN

		--Get the employee info
		SELECT	@empName = RTRIM(EmpName),
				@empEmail = LTRIM(RTRIM(b.EAEMAL))
		FROM Projectuser.Vw_MasterEmployeeJDE a
			LEFT JOIN Projectuser.sy_F01151 b WITH (NOLOCK) ON a.EmpNo = b.EAAN8 AND b.EAIDLN = 0 AND b.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(b.EAETP))) = 'E' 
		WHERE EmpNo = @actionMemberEmpNo
	END

	--Populate data to the table
	INSERT INTO @myTable  
	SELECT	@actionMemberEmpNo, @empName, @empEmail
	
SKIP_HERE_MULTIPLE_ASSIGNEE:

	INSERT INTO @rtnTable 
	SELECT * FROM @mytable 

	RETURN 
END

/*	Debugging:
	
PARAMETERS:
	@distListCode	VARCHAR(10),
	@costCenter		VARCHAR(12),
	@empNo			INT 

	SELECT * FROM Projectuser.fnGetWFActionMember('CEAUPLOADR', 'ALL', 0)			--CEA Uploaders
	SELECT * FROM Projectuser.fnGetWFActionMember('SUPERVISOR', '', 10003632)		--Get the immediate supervisor
	SELECT * FROM Projectuser.fnGetWFActionMember('CCSUPERDNT', '7600', 0)			--Get the Superintendent
	SELECT * FROM Projectuser.fnGetWFActionMember('CCMANAGER', '7600', 0)			--Get the department manager
	SELECT * FROM Projectuser.fnGetWFActionMember('HRMANAGER', '', 0)				--Get the HR Manager
	SELECT * FROM Projectuser.fnGetWFActionMember('OPGENMNGR', '', 0)				--Get the GM Operations	
	SELECT * FROM Projectuser.fnGetWFActionMember('VISITADMIN', 'ALL', 0)			--Returns multiple action member

*/

