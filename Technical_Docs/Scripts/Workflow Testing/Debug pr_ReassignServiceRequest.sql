DECLARE	@reqType INT = 22,
		@reqTypeNo INT = 20230139,
		@currentDistMemEmpNo INT = 10003589,
		@currentDistMemRoutineSeq INT = 1,
		@currentDistMemOnHold BIT = 0,
		@newDistMemEmpNo INT = 10003520,
		@newDistMemEmpName varchar(50) = 'ERVIN OLINAS BROSAS',
		@newDistMemEmpEmail varchar(150) = 'ervin.brosas@garmco.com',
		@newDistMemActionType INT = 64,
		@reassignRemark varchar(300) = '10003520|reassignment Superintendent',
		@actID int,
		@retError int 

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SELECT @RETURN_OK		= 0
	SELECT @RETURN_ERROR	= -1

	-- Initialize return error
	SELECT @retError = @RETURN_OK

	-- Define Activity Process Status
	DECLARE @ACTIVITY_PROCESSS_CREATED int
	DECLARE @ACTIVITY_PROCESSS_IN_PROGRESS int
	DECLARE @ACTIVITY_PROCESSS_SKIPPED int

	SELECT @ACTIVITY_PROCESSS_CREATED = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'CR'

	SELECT @ACTIVITY_PROCESSS_IN_PROGRESS = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'IN'

	SELECT @ACTIVITY_PROCESSS_SKIPPED = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'S'

	-- Define Action Type
	DECLARE @ACTION_TYPE_APPROVER int
	DECLARE @ACTION_TYPE_SERVICE_PROVIDER int
	DECLARE @SERV_TYPE_VALIDATOR int

	SELECT @ACTION_TYPE_APPROVER = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'APP'

	SELECT @ACTION_TYPE_SERVICE_PROVIDER = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'SERVPROV'

	SELECT @SERV_TYPE_VALIDATOR = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'VAL'

	-- Define necessary variables
	DECLARE @currentDistMemID int
	DECLARE @currentDistMemRefID int
	DECLARE @currentDistMemActionType int
	DECLARE @currentDistMemApproval tinyint
	DECLARE @currentDistMemEmpName varchar(50)
	DECLARE @currentUserEmpNo int
	DECLARE @currentUserEmpName varchar(100)
	DECLARE @reassignmentRemark varchar(300)
	DECLARE @actCode VARCHAR(10)

	DECLARE @distMemID int
	DECLARE @distMemDistListID int
	DECLARE @distMemType int
	DECLARE @distMemPrimary bit

	DECLARE @histDesc varchar(300)
	DECLARE @histDate datetime

	SELECT @histDate = GETDATE()

	--Extract the reassigned by user's employee ID from the remarks text
	SELECT @currentUserEmpNo = CAST(RTRIM(SUBSTRING(@reassignRemark, 1, CHARINDEX('|', @reassignRemark) - 1)) AS INT)
	SELECT @currentUserEmpName = EmpName FROM secuser.EmployeeMaster WHERE EmpNo = @currentUserEmpNo

	--Extract the reassignment remarks
	SELECT @reassignmentRemark = LTRIM(SUBSTRING(@reassignRemark, CHARINDEX('|', @reassignRemark) + 1, LEN(@reassignRemark)))

	-- Define Current Distribution Status
	DECLARE @statusID INT

	IF @newDistMemActionType = @ACTION_TYPE_APPROVER
	BEGIN

		SELECT @statusID = a.UDCID
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '05'

		SELECT @histDesc = a.UDCDesc1
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '122'

	END

	ELSE IF @newDistMemActionType = @ACTION_TYPE_SERVICE_PROVIDER
	BEGIN

		SELECT @statusID = a.UDCID
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '10'

		SELECT @histDesc = a.UDCDesc1
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '15'

	END

	ELSE IF @newDistMemActionType = @SERV_TYPE_VALIDATOR
	BEGIN

		SELECT @statusID = a.UDCID
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '16'

		SELECT @histDesc = a.UDCDesc1
			FROM SecUser.UserDefinedCode AS a
			WHERE a.UDCUDCGID = 9 AND a.UDCCode = '132'

	END

	-- Retrieve individual employee type
	SELECT @distMemType = a.UDCID
		FROM SecUser.UserDefinedCode AS a
		WHERE a.UDCCode = 'INVEMP'

	-- Retrieve the current activity
	SELECT @actID = a.ActID, @actCode = a.ActCode
		FROM SecUser.TransActivity AS a INNER JOIN
			SecUser.ProcessWF AS b ON a.ActProcessID = b.ProcessID
		WHERE b.ProcessReqType = @reqType AND b.ProcessReqTypeNo = @reqTypeNo AND a.ActCurrent = 1

	-- Retrieve the Distribution Information
	SELECT @currentDistMemID = a.CurrentDistMemID, @currentDistMemRefID = a.CurrentDistMemRefID,
			@distMemDistListID = b.DistMemDistListID,--b.DistMemAnotherDistListID,
			@currentDistMemEmpName = a.CurrentDistMemEmpName, @distMemPrimary = b.DistMemPrimary
		FROM SecUser.CurrentDistributionMember AS a INNER JOIN
			SecUser.DistributionMember AS b ON a.CurrentDistMemRefID = b.DistMemID
		WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
			a.CurrentDistMemEmpNo = @currentDistMemEmpNo AND a.CurrentDistMemCurrent = 1

	-- Checks if will go back to the originator
	IF @currentDistMemOnHold = 1
	BEGIN

		-- Update the sequence no. of the distribution member
		UPDATE SecUser.DistributionMember SET DistMemRoutineSeq = DistMemRoutineSeq + 1
			WHERE DistMemDistListID = @distMemDistListID AND
				DistMemRoutineSeq >= @currentDistMemRoutineSeq

		-- Checks for error
		IF @@ERROR <> @RETURN_OK
			SELECT @retError = @RETURN_ERROR

	END

	-- Checks for error
	IF @retError = @RETURN_OK
	BEGIN

		-- Create a Distribution Member
		INSERT INTO SecUser.DistributionMember(DistMemDistListID, DistMemType, DistMemAnotherDistListID,
				DistMemEmpNo, DistMemEmpName, DistMemEmpEmail, DistMemPrimary, DistMemApproval,
				DistMemThreshold, DistMemEscalate, DistMemIgnoreOL, DistMemRoutineSeq,
				DistMemSeq, DistMemCurrent, DistMemStatusID)
			SELECT a.DistMemDistListID, a.DistMemType, a.DistMemAnotherDistListID,
					@newDistMemEmpNo, @newDistMemEmpName, @newDistMemEmpEmail, a.DistMemPrimary, a.DistMemApproval,
					0, 0, 0, @currentDistMemRoutineSeq,
					1, 1, a.DistMemStatusID
				FROM SecUser.DistributionMember AS a
				WHERE a.DistMemID = @currentDistMemRefID

		-- Checks for error
		IF @@ERROR = @RETURN_OK
		BEGIN

			-- Retrieve the new id
			SELECT @distMemID = @@IDENTITY

			-- Update the Distribution Member Status
			UPDATE SecUser.DistributionMember SET DistMemStatusID = (CASE
																		WHEN @currentDistMemOnHold = 0 THEN @ACTIVITY_PROCESSS_SKIPPED
																		ELSE @ACTIVITY_PROCESSS_CREATED END),
					DistMemType = @distMemType, DistMemPrimary = (CASE
																	WHEN @currentDistMemOnHold = 0 THEN 0
																	ELSE @distMemPrimary END)
				WHERE DistMemID = @currentDistMemRefID

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Create a Current Distribution Member
				INSERT INTO SecUser.CurrentDistributionMember(CurrentDistMemRefID, CurrentDistMemCurrent,
						CurrentDistMemReqType, CurrentDistMemReqTypeNo,
						CurrentDistMemEmpNo, CurrentDistMemEmpName, CurrentDistMemEmpEmail,
						CurrentDistMemActionType, CurrentDistMemApproval, CurrentDistMemRoutineSeq,
						CurrentDistMemStatusID,
						CurrentDistMemNextID, CurrentDistMemAdded,
						CurrentDistMemModifiedBy, CurrentDistMemModifiedDate)
					SELECT @distMemID, 1,
							a.CurrentDistMemReqType, a.CurrentDistMemReqTypeNo,
							@newDistMemEmpNo, @newDistMemEmpName, @newDistMemEmpEmail,
							@newDistMemActionType, a.CurrentDistMemApproval, a.CurrentDistMemRoutineSeq,
							@statusID, 0, 1,
							@currentDistMemEmpNo, GETDATE()
						FROM SecUser.CurrentDistributionMember AS a
						WHERE a.CurrentDistMemID = @currentDistMemID

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					-- Remove previous current distribution member
					DELETE SecUser.CurrentDistributionMember
						WHERE CurrentDistMemID = @currentDistMemID

					-- Checks for error
					IF @@ERROR = @RETURN_OK
					BEGIN
						-- Reassign the assigned engineer as well for ESR if open with engineer
						IF(@reqType = 6 AND @actCode = 'ASSIGNESRL')
						BEGIN
							EXEC secuser.pr_AssignESREngr @reqTypeNo,@newDistMemEmpNo, @newDistMemEmpName,@newDistMemEmpEmail,
									0,'','',1, @currentUserEmpNo,@currentUserEmpName,'',@retError OUTPUT
						END

						-- Update the history
						IF @@ERROR = @RETURN_OK
							BEGIN
								-- Update the history
								SELECT @histDesc = @histDesc + ' (' + @newDistMemEmpName + ') - ' + @reassignmentRemark
								EXEC SecUser.pr_InsertRequestHistory @reqType, @reqTypeNo, @histDesc,
									@currentUserEmpNo, @currentUserEmpName, @histDate, @retError OUTPUT
							END

					END
					ELSE
						SELECT @retError = @RETURN_ERROR

				END

				ELSE
					SELECT @retError = @RETURN_ERROR

			END

			ELSE
				SELECT @retError = @RETURN_ERROR

		END

		ELSE
			SELECT @retError = @RETURN_ERROR
	END 

