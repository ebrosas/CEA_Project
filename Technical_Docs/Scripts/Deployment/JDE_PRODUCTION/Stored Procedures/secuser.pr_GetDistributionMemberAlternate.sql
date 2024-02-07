/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.05.04 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			21-Mar-2016 12:30PM
	Modified the code to handle the new Invoice Requisition

	2.2					Shoukhat			27-Feb-2020 05:00PM
	Modified the code to handle the new Employee Contract Renewal Requisition

	2.3					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_GetDistributionMemberAlternate
(
	@distAltDistMemID INT,
	@distMemEmpNo INT OUTPUT,
	@distMemEmpName VARCHAR(50) OUTPUT,
	@distMemEmpEmail VARCHAR(150) OUTPUT,
	@currentDate SMALLDATETIME,
	@reqType INT,
	@empCostCenter VARCHAR(12),
	@maxDuration INT
)
AS
BEGIN

	SET NOCOUNT ON 

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_TSR int
	DECLARE @REQUEST_TYPE_PAF int
	DECLARE @REQUEST_TYPE_EPA int
	DECLARE @REQUEST_TYPE_CLRFRM int
	DECLARE @REQUEST_TYPE_RR int		-- ver 2.0
	DECLARE @REQUEST_TYPE_IR int		-- ver 2.1
	DECLARE @REQUEST_TYPE_ECR int		-- ver 2.2
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 2.3

	SELECT @REQUEST_TYPE_LEAVE	= 4
	SELECT @REQUEST_TYPE_PR		= 5
	SELECT @REQUEST_TYPE_TSR	= 6
	SELECT @REQUEST_TYPE_PAF	= 7
	SELECT @REQUEST_TYPE_EPA	= 11
	SELECT @REQUEST_TYPE_CLRFRM	= 16
	SELECT @REQUEST_TYPE_RR		= 18	-- ver 2.0
	SELECT @REQUEST_TYPE_IR		= 19	-- ver 2.1
	SELECT @REQUEST_TYPE_ECR	= 20	-- ver 2.2
	SELECT @REQUEST_TYPE_CEA	= 22	-- ver 2.3


	-- Member Type
	DECLARE @MEMBER_TYPE_SUPERINTENDENT varchar(10)
	DECLARE @MEMBER_TYPE_COST_CENTER_HEAD varchar(10)
	DECLARE @MEMBER_TYPE_INDIVIDUAL_USER varchar(10)
	DECLARE @MEMBER_TYPE_USER varchar(10)
	DECLARE @MEMBER_TYPE_DISTRIBUTION_GROUP varchar(10)
	DECLARE @MEMBER_TYPE_IMMEDIATE_SUPERVISOR varchar(10)
	DECLARE @MEMBER_TYPE_PARAMETER varchar(10)

	SET @MEMBER_TYPE_SUPERINTENDENT			= 'SINT'
	SET @MEMBER_TYPE_COST_CENTER_HEAD		= 'CCH'
	SET @MEMBER_TYPE_INDIVIDUAL_USER		= 'INVEMP'
	SET @MEMBER_TYPE_USER					= 'USR'
	SET @MEMBER_TYPE_DISTRIBUTION_GROUP		= 'DISTGRP'
	SET @MEMBER_TYPE_IMMEDIATE_SUPERVISOR	= 'IMSUPERV'
	SET @MEMBER_TYPE_PARAMETER				= 'PARAM'

	-- Declare necessary variables
	DECLARE @distAltEmpNo int
	DECLARE @distAltEmpName varchar(50)
	DECLARE @distAltEmail varchar(50)

	DECLARE @currentDistAltEmpNo int
	DECLARE @currentDistAltEmpName varchar(50)
	DECLARE @currentDistAltEmail varchar(50)

	DECLARE @distMemAnotherDistListID int
	DECLARE @distMemAnotherDistListIDOrig int
	DECLARE @distMemRoutineSeq int
	DECLARE @distMemDistListID int
	DECLARE @distMemCurrentEmpNo int

	DECLARE @memberTypeCode varchar(10)

	DECLARE @duration int
	DECLARE @toDate smalldatetime

	SET @duration = 0
	-- End of necessary variables

	-- Retrieve the current distribution property
	SELECT @distMemDistListID = a.DistMemDistListID, @distMemAnotherDistListIDOrig = a.DistMemAnotherDistListIDOrig,
			@distMemCurrentEmpNo = a.DistMemEmpNo, @distMemRoutineSeq = a.DistMemRoutineSeq,
			@memberTypeCode = ISNULL(b.UDCCode, '')
		FROM SecUser.DistributionMember AS a WITH (NOLOCK) LEFT JOIN
			secuser.UserDefinedCode AS b WITH (NOLOCK) ON a.DistMemType = b.UDCID
		WHERE a.DistMemID = @distAltDistMemID

	-- Declare the Distribution Member Alternate Cursor
	DECLARE distAltCursor CURSOR FOR
	SELECT a.DistMemEmpNo, a.DistMemEmpName, a.DistMemEmpEmail, b.ToDate
		FROM (
			SELECT 0 AS Priority, b.DistAltEmpNo AS DistMemEmpNo, b.DistAltEmpName AS DistMemEmpName,
					b.DistAltEmpEmail AS DistMemEmpEmail, b.DistAltSeq AS DistMemSeq
				FROM secuser.GenPurposeDistributionMember AS a WITH (NOLOCK) INNER JOIN
					secuser.GenPurposeDistributionMemberAlternate AS b WITH (NOLOCK) ON a.DistMemID = b.DistAltDistMemID
				WHERE a.DistMemDistListID = @distMemAnotherDistListIDOrig
			UNION ALL
			SELECT 1 AS Priority, c.DistAltEmpNo AS DistMemEmpNo, c.DistAltEmpName AS DistMemEmpName,
						c.DistAltEmpEmail AS DistMemEmpEmail, c.DistAltSeq AS DistMemSeq
					FROM SecUser.DistributionMember AS a WITH (NOLOCK) INNER JOIN
						SecUser.DistributionMember AS b WITH (NOLOCK) ON a.DistMemAnotherDistListID = b.DistMemDistListID INNER JOIN
						SecUser.DistributionMemberAlternate AS c WITH (NOLOCK) ON b.DistMemID = c.DistAltDistMemID
					WHERE a.DistMemID = @distAltDistMemID
				UNION ALL
				SELECT 2 AS Priority, a.DistAltEmpNo AS DistMemEmpNo, a.DistAltEmpName AS DistMemEmpName,
						a.DistAltEmpEmail AS DistMemEmpEmail, a.DistAltSeq AS DistMemSeq
					FROM SecUser.DistributionMemberAlternate AS a WITH (NOLOCK)
					WHERE a.DistAltDistMemID = @distAltDistMemID
				UNION ALL
				SELECT 3 AS Priority, a.DistMemEmpNo, a.DistMemEmpName, a.DistMemEmpEmail, a.DistMemSeq
					FROM SecUser.DistributionMember AS a WITH (NOLOCK)
					WHERE a.DistMemDistListID = @distMemDistListID AND a.DistMemEmpNo <> @distMemCurrentEmpNo AND
						a.DistMemRoutineSeq = @distMemRoutineSeq AND a.DistMemApproval = 1
				UNION ALL

				SELECT 4 AS Priority, a.DistMemEmpNo, a.DistMemEmpName, a.DistMemEmpEmail, a.DistMemSeq
					FROM (SELECT ISNULL(CASE WHEN a.SubEmpNo > 0 THEN a.SubEmpNo ELSE b.CCAppEmpNo END, 0) AS DistMemEmpNo,
								ISNULL(CASE WHEN a.SubEmpNo > 0 THEN a.SubEmpName ELSE b.CCAppEmpName END , '') AS DistMemEmpName,
								ISNULL(CASE WHEN a.SubEmpNo > 0 THEN '' ELSE b.CCAppEmpEmail END, '') AS DistMemEmpEmail, 1 AS DistMemSeq
							FROM secuser.LeaveRequisition AS a WITH (NOLOCK) LEFT JOIN
								(SELECT TOP 1 a.CostCenter, b.CCAppEmpNo, b.CCAppEmpName, b.CCAppEmpEmail
									FROM secuser.CostCenter AS a WITH (NOLOCK) INNER JOIN
										secuser.CostCenterApprover AS b WITH (NOLOCK) ON a.CostCenter = b.CCAppCostCenter AND
											((@distMemEmpNo = a.SuperintendentNo AND b.CCAppMemberType = 1) OR (@distMemEmpNo = a.ManagerNo AND b.CCAppMemberType = 2)) INNER JOIN
										secuser.UserDefinedCode AS c ON b.CCAppAppID = c.UDCID AND
											((@reqType = @REQUEST_TYPE_LEAVE AND c.UDCCode = 'LEAVE') OR
											(@reqType = @REQUEST_TYPE_PR AND c.UDCCode = 'PR') OR
											(@reqType = @REQUEST_TYPE_TSR AND c.UDCCode = 'TSR') OR
											(@reqType = @REQUEST_TYPE_PAF AND c.UDCCode = 'PAF') OR
											(@reqType = @REQUEST_TYPE_EPA AND c.UDCCode = 'PAF') OR
											(@reqType = @REQUEST_TYPE_CLRFRM AND c.UDCCode = 'PAF') OR
											(@reqType = @REQUEST_TYPE_RR AND c.UDCCode = 'RR') OR -- ver 2.0
											(@reqType = @REQUEST_TYPE_RR AND c.UDCCode = 'SUPINVOICE') OR -- ver 2.1
											(@reqType = @REQUEST_TYPE_ECR AND c.UDCCode = 'ECR') OR -- ver 2.2
											(@reqType = @REQUEST_TYPE_CEA AND c.UDCCode = 'CEAAPP') OR -- ver 2.3
											 c.UDCCode = 'GAP')
									WHERE @distMemEmpNo IN (a.SuperintendentNo, a.ManagerNo) AND a.CostCenter = @empCostCenter
									ORDER BY b.CCAppMemberType, b.CCAppSeq, (CASE WHEN c.UDCField IS NULL THEN 1 ELSE 0 END)) AS b ON @empCostCenter = b.CostCenter
							WHERE a.RequestStatusSpecialHandlingCode = 'Closed' AND a.EmpNo = @distMemEmpNo AND a.LeaveType = 'AL' AND 
								@currentDate BETWEEN a.LeaveStartDate AND a.LeaveEndDate AND @memberTypeCode = 'IMSUPERV') AS a
					WHERE a.DistMemEmpNo > 0) AS a LEFT JOIN
			(SELECT CAST(a.LRAN8 AS int) AS EmpNo,
						dbo.ConvertFromJulian(a.LRY58VCOFD) AS FromDate,
						dbo.ConvertFromJulian(a.LRY58VCOTD) AS ToDate,
						CAST(a.LRY58VCVCD AS char(3))AS LeaveCode,
						CAST(a.LRY58VCVDR AS int) / 10000 AS Duration,
						'' AS Reason
					FROM SecUser.F58LV13 AS a WITH (NOLOCK)
					WHERE a.LRY58VCAFG <> 'C' AND dbo.ConvertToJulian(GETDATE()) >= a.LRY58VCOFD AND a.LRY58VCOTD >= dbo.ConvertToJulian(@currentDate)
				UNION
				SELECT DISTINCT a.EmpNo,
						a.EffectiveDate AS FromDate,
						a.EndingDate AS ToDate,
						a.AbsenceReasonCode AS LeaveCode,
						DATEDIFF(dd, a.EffectiveDate, a.EndingDate) +  1 AS Duration,
						b.DRDL01 AS Reason
					FROM tas2.tas.Tran_Absence AS a WITH (NOLOCK) INNER JOIN
						SecUser.F0005 AS b WITH (NOLOCK) ON a.AbsenceReasonCode = LTRIM(b.DRKY) AND
	--						SUBSTRING(b.DRDL02,1,2) IN ('XL  ','OS  ','ML  ','LF  ','BT  ','DO  ','FT  ') AND
							LTRIM(RTRIM(b.DRKY)) IN ('XL','OS','ML','LF','BT','DO','FT') AND
							b.DRSY = '55' AND b.DRRT = 'RA'
					WHERE dbo.ConvertToJulian(GETDATE()) >= dbo.ConvertToJulian(a.EffectiveDate) AND
						dbo.ConvertToJulian(a.EndingDate) >= dbo.ConvertToJulian(@currentDate)) AS b ON a.DistMemEmpNo = b.EmpNo
		ORDER BY a.Priority, a.DistMemSeq

	-- Open the cursor and fetch the data
	OPEN distAltCursor
	FETCH NEXT FROM distAltCursor
	INTO @distAltEmpNo, @distAltEmpName, @distAltEmail,
		@toDate

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Check if not on leave
		IF @toDate IS NULL
		BEGIN

			-- Set the current least duration
			SELECT @duration = 0

			-- Set the current distribution member alternate
			IF @currentDistAltEmpNo IS NULL
			BEGIN

				SET @currentDistAltEmpNo	= @distAltEmpNo
				SET @currentDistAltEmpName	= @distAltEmpName
				SET @currentDistAltEmail	= @distAltEmail

			END
		END

		-- Check if less than the current duration
		ELSE IF DATEDIFF(dd, @currentDate, @toDate) < @duration
		BEGIN

			-- Set the current least duration
			SET @duration = 0

			-- Set the current distribution member alternate
			SET @currentDistAltEmpNo	= @distAltEmpNo
			SET @currentDistAltEmpName	= @distAltEmpName
			SET @currentDistAltEmail	= @distAltEmail

		END

		-- Fetch next record
		FETCH NEXT FROM distAltCursor
		INTO @distAltEmpNo, @distAltEmpName, @distAltEmail,
			@toDate

	END		

	-- Close and deallocate
	CLOSE distAltCursor
	DEALLOCATE distAltCursor

	-- Assign the Distribution Member Alternate
	IF @currentDistAltEmpNo IS NOT NULL
	BEGIN

		SET @distMemEmpNo		= @currentDistAltEmpNo
		SET @distMemEmpName		= @currentDistAltEmpName
		SET @distMemEmpEmail	= @currentDistAltEmail

	END

	ELSE
	BEGIN

		SET @distMemAnotherDistListID = 0
		SELECT @distMemAnotherDistListID = a.DistMemAnotherDistListID
			FROM SecUser.DistributionMember AS a
			WHERE a.DistMemID = @distAltDistMemID

		-- Check if a distribution group and check the alternative member of the group
		IF @distMemAnotherDistListID > 0
		BEGIN

			SELECT @distAltDistMemID = a.DistMemID
				FROM SecUser.DistributionMember AS a
				WHERE a.DistMemDistListID = @distMemAnotherDistListID

			EXEC SecUser.pr_GetDistributionMemberAlternate @distAltDistMemID,
				@distMemEmpNo OUTPUT, @distMemEmpName OUTPUT, @distMemEmpEmail OUTPUT, @currentDate, @reqType, @empCostCenter, @maxDuration

		END
	END

END


