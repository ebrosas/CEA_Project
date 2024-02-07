
ALTER FUNCTION Projectuser.ProjectUsedAmt
(
	@ProjectNo VARCHAR(50)
)
RETURNS NUMERIC(18,3)
BEGIN 

	DECLARE @ProjectRequestedAmt 	NUMERIC(18,3),
			@CancelStatusID			INT,
			@RejectStatusID			INT

	SELECT @CancelStatusID = ApprovalStatusID 
	FROM dbo.ApprovalStatus a WITH (NOLOCK) 
	WHERE RTRIM(a.StatusCode) = 'Cancelled'
	
	SELECT @RejectStatusID = ApprovalStatusID 
	FROM dbo.ApprovalStatus a WITH (NOLOCK)  
	WHERE RTRIM(StatusCode) = 'Rejected'

	--Get the requested amounts
	SELECT @ProjectRequestedAmt = SUM(a.RequestedAmt)
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE a.ProjectNo = @ProjectNo
		AND a.RequisitionID NOT IN (SELECT RequisitionID FROM dbo.RequisitionStatus WITH (NOLOCK) WHERE ApprovalStatusID IN (@CancelStatusID, @RejectStatusID))

	RETURN ISNULL(@ProjectRequestedAmt, 0)

END

/*	Debug:

	SELECT Projectuser.ProjectUsedAmt('2220211')

*/






