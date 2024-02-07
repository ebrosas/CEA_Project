ALTER FUNCTION Projectuser.AccountNo
(
	@ProjectNo AS VARCHAR(50)
)
RETURNS VARCHAR(50)
BEGIN

	DECLARE @AccountID 		AS VARCHAR(50)
	DECLARE @AccountNo 		AS VARCHAR(50)

	--Get the requested amounts
	SELECT @AccountID = AccountID
	FROM dbo.Project a WITH (NOLOCK)
	WHERE RTRIM(a.ProjectNo) = LTRIM(RTRIM(@ProjectNo))

	SELECT @AccountNo = LTRIM(RTRIM(a.CostCenter)) + '.' + LTRIM(RTRIM(a.ObjectAccount)) + '.' + LTRIM(RTRIM(a.SujectAccount))
	FROM Projectuser.Master_AccountID a WITH (NOLOCK)
	WHERE RTRIM(AccountID) = LTRIM(RTRIM(@AccountID))

	RETURN @AccountNo

END

/*	Debug:

	SELECT Projectuser.AccountNo('2220211')

*/


